// Project F: Framebuffer Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module framebuffer_tb();

    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    logic rst;
    logic clk_25m;
    logic clk_100m;

    // display timings
    localparam CORDW = 5;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    display_timings_24x18 timings_24x18 (
        .clk_pix(clk_25m),
        .rst,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 32;
    localparam V_RES_FULL = 23;
    localparam H_RES = 24;
    localparam V_RES = 18;

    // vertical blanking interval (will move to display_timings soon)
    logic vbi;
    always_comb vbi = (sy == V_RES && sx == 0);

    // framebuffer (FB)
    localparam FB_WIDTH   = 12;
    localparam FB_HEIGHT  = 9;
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "test_box_12x9.mem";
    localparam FB_PALETTE = "test_palette.mem";

    logic fb_we = 0;
    logic [FB_ADDRW-1:0] fb_addr_write = 1;
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_cidx_write;
    logic [FB_DATAW-1:0] fb_cidx_read, fb_cidx_read_1;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) fb_inst (
        .clk_write(clk_25m),
        .clk_read(clk_25m),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb_cidx_read_1)
    );

    // draw a horizontal line at the top of the framebuffer
    always @(posedge clk_25m) begin
        if (sy >= V_RES) begin  // draw in blanking interval
            if (fb_we == 0 && fb_addr_write != FB_WIDTH-2) begin
                fb_cidx_write <= 4'hF;  // last palette entry (0xFCA)
                fb_we <= 1;
            end else if (fb_addr_write != FB_WIDTH-2) begin
                fb_addr_write <= fb_addr_write + 1;
            end else begin
                fb_we <= 0;
            end
        end
    end

    // linebuffer (LB)
    localparam LB_SCALE = 2;       // scale (horizontal and vertical)
    localparam LB_LEN = FB_WIDTH;  // line length matches framebuffer
    localparam LB_BPC = 4;         // bits per colour channel

    // LB output to display
    logic lb_en_out;
    always_comb lb_en_out = de;  // Use 'de' for entire frame.

    // Load data from FB into LB
    logic lb_data_req;  // LB requesting data
    logic [$clog2(LB_LEN+1)-1:0] cnt_h = 0;  // count pixels in line to read
    always_ff @(posedge clk_25m) begin
        if (vbi) fb_addr_read <= 0;   // new frame
        if (lb_data_req && sy != V_RES-1) begin  // load next line of data...
            cnt_h <= 0;                          // ...if not on last line
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            fb_addr_read <= fb_addr_read == FB_PIXELS-1 ? 0 : fb_addr_read + 1;
        end
    end

    // FB BRAM and CLUT pipeline adds three cycles of latency
    logic lb_en_in_2, lb_en_in_1, lb_en_in;
    always_ff @(posedge clk_25m) begin
        lb_en_in_2 <= (cnt_h < LB_LEN);
        lb_en_in_1 <= lb_en_in_2;
        lb_en_in <= lb_en_in_1;
    end

    logic [LB_BPC-1:0] lb_in_0, lb_in_1, lb_in_2;
    logic [LB_BPC-1:0] lb_out_0, lb_out_1, lb_out_2;

    linebuffer #(
        .WIDTH(LB_BPC),     // data width of each channel
        .LEN(LB_LEN),       // length of line
        .SCALE(LB_SCALE)    // scaling factor (>=1)
        ) lb_inst (
        .clk_in(clk_25m),       // input clock
        .clk_out(clk_25m),      // output clock
        .data_req(lb_data_req), // request input data (clk_in)
        .en_in(lb_en_in),       // enable input (clk_in)
        .en_out(lb_en_out),     // enable output (clk_out)
        .vbi,                   // start of vertical blanking interval (clk_out)
        .din_0(lb_in_0),        // data in (clk_in)
        .din_1(lb_in_1),
        .din_2(lb_in_2),
        .dout_0(lb_out_0),      // data out (clk_out)
        .dout_1(lb_out_1),
        .dout_2(lb_out_2)
    );

    // improve timing with register between BRAM and async ROM
    always @(posedge clk_25m) begin
        fb_cidx_read <= fb_cidx_read_1;
    end

    // colour lookup table (ROM) 16x12-bit entries
    logic [11:0] clut_colr;
    rom_async #(
        .WIDTH(12),
        .DEPTH(16),
        .INIT_F(FB_PALETTE)
    ) clut (
        .addr(fb_cidx_read),
        .data(clut_colr)
    );

    // map colour index to palette using CLUT and read into LB
    always_ff @(posedge clk_25m) begin
        {lb_in_2, lb_in_1, lb_in_0} <= clut_colr;
    end

    // Indicate when drawing should occur to screen
    logic draw_to_screen;  // LB output adds one cycle of latency
    always_ff @(posedge clk_25m) draw_to_screen <= lb_en_out;

    // generate clocks
    always #(CLK_PERIOD_100M / 2) clk_100m = ~clk_100m;
    always #(CLK_PERIOD_25M / 2) clk_25m = ~clk_25m;

    initial begin
        rst = 1;
        clk_100m = 1;
        clk_25m = 1;

        #100 rst = 0;

        #100000 $finish;
    end
endmodule
