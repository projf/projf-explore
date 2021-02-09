// Project F: Life on Screen - Top Life Simulation (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_life (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    localparam GEN_FRAMES = 15;  // each generation lasts this many frames
    localparam SEED_FILE = "simple_life.mem";  // seed to initiate universe

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    display_timings_480p timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    // vertical blanking interval (will move to display_timings soon)
    logic vbi;
    always_comb vbi = (sy == V_RES && sx == 0);

    // framebuffer (FB)
    localparam FB_COUNT  = 2;  // double buffered
    localparam FB_WIDTH  = 80;
    localparam FB_HEIGHT = 60;
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;
    localparam FB_DEPTH  = FB_COUNT * FB_PIXELS;
    localparam FB_ADDRW  = $clog2(FB_DEPTH);
    localparam FB_DATAW  = 1;  // colour bits per pixel
    localparam FB_IMAGE  = SEED_FILE;

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_read, fb_addr_write;
    logic [FB_DATAW-1:0] pix_in;
    logic [FB_DATAW-1:0] pix_out, pix_out_1;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_DEPTH),
        .INIT_F(FB_IMAGE)
    ) fb_inst (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(pix_in),
        .data_out(pix_out_1)
    );

    // update frame counter and choose front buffer
    logic life_start;    // trigger next calculation
    logic front_buffer;  // which buffer to draw the display from
    logic [$clog2(GEN_FRAMES)-1:0] cnt_frames;
    always_ff @(posedge clk_pix) begin
        if (sy == V_RES_FULL-1 && sx == H_RES_FULL-1)
            cnt_frames <= cnt_frames + 1;
        if (cnt_frames == GEN_FRAMES - 1) begin
            front_buffer <= ~front_buffer;
            cnt_frames <= 0;
            life_start <= 1;
        end else life_start <= 0;
    end

    logic life_run;
    logic [FB_ADDRW-1:0] cell_id;
    life #(
        .WORLD_WIDTH(FB_WIDTH),
        .WORLD_HEIGHT(FB_HEIGHT),
        .ADDRW(FB_ADDRW)
    ) life_sim (
        .clk(clk_pix),
        .start(life_start),
        .run(life_run),
        .id(cell_id),
        .r_status(pix_out),
        .w_status(pix_in),
        .we(fb_we),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // linebuffer (LB)
    localparam LB_SCALE = 8;       // scale (horizontal and vertical)
    localparam LB_LEN = FB_WIDTH;  // line length matches framebuffer
    localparam LB_BPC = 4;         // bits per colour channel

    // LB output to display
    logic lb_en_out;
    always_comb lb_en_out = de;  // Use 'de' for entire frame

    // Load data from FB into LB
    logic [FB_ADDRW-1:0] lb_fb_addr;
    logic lb_data_req;  // LB requesting data
    logic [$clog2(LB_LEN+1)-1:0] cnt_h;  // count pixels in line to read
    always_ff @(posedge clk_pix) begin
        if (vbi) lb_fb_addr <= 0;   // new frame
        if (lb_data_req && sy != V_RES-1) begin  // load next line of data...
            cnt_h <= 0;                          // ...if not on last line
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            lb_fb_addr <= lb_fb_addr == FB_PIXELS-1 ? 0 : lb_fb_addr + 1;
        end
    end

    // FB BRAM and colour pipeline adds three cycles of latency
    logic lb_en_in_2, lb_en_in_1, lb_en_in;
    always_ff @(posedge clk_pix) begin
        lb_en_in_2 <= (cnt_h < LB_LEN);
        lb_en_in_1 <= lb_en_in_2;
        lb_en_in <= lb_en_in_1;
    end

    // LB colour channels
    logic [LB_BPC-1:0] lb_in_0, lb_in_1, lb_in_2;
    logic [LB_BPC-1:0] lb_out_0, lb_out_1, lb_out_2;

    linebuffer #(
        .WIDTH(LB_BPC),     // data width of each channel
        .LEN(LB_LEN),       // length of line
        .SCALE(LB_SCALE)    // scaling factor (>=1)
        ) lb_inst (
        .clk_in(clk_pix),       // input clock
        .clk_out(clk_pix),      // output clock
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

    // improve timing with register between BRAM and LB input
    always @(posedge clk_pix) begin
        pix_out <= pix_out_1;
    end

    // sim can run when linebuffer is not using framebuffer
    always_comb life_run = (sy != V_RES && sy[2:0] != 3'b111);

    // framebuffer address control
    always_comb begin
        fb_addr_read = (life_run) ? cell_id : lb_fb_addr;
        if (front_buffer == 1) fb_addr_read = fb_addr_read + FB_PIXELS;
        fb_addr_write = (front_buffer == 1) ? cell_id : cell_id + FB_PIXELS;
    end

    // read framebuffer pixels into LB
    always_ff @(posedge clk_pix) begin
        {lb_in_2, lb_in_1, lb_in_0} <= pix_out ? 12'hFC0 : 12'h115;
    end

    // LB output adds one cycle of latency - need to correct display signals
    logic hsync_1, vsync_1, lb_en_out_1;
    always_ff @(posedge clk_pix) begin
        hsync_1 <= hsync;
        vsync_1 <= vsync;
        lb_en_out_1 <= lb_en_out;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_1;
        vga_vsync <= vsync_1;
        vga_r <= lb_en_out_1 ? lb_out_2 : 4'h0;
        vga_g <= lb_en_out_1 ? lb_out_1 : 4'h0;
        vga_b <= lb_en_out_1 ? lb_out_0 : 4'h0;
    end
endmodule
