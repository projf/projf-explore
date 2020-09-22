// Project F: Life on Screen - Top Earth Bitmap (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_earth (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

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
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .de
    );

    logic frame_end;   // high for one clycle at the end of a frame
    logic line_start;  // high for one cycle at line start (drawing lines only)
    always_comb begin
        frame_end = (sy == 524 && sx == 799);
        line_start = (sy < 480 && sx == 0);
    end

    // bitmap buffer
    localparam BMP_WIDTH  = 320;
    localparam BMP_HEIGHT = 240;
    localparam BMP_PIXELS = BMP_WIDTH * BMP_HEIGHT; 
    localparam BMP_ADDRW = $clog2(BMP_PIXELS);
    localparam BMP_DATAW = 4;  // colour bits per pixel
    localparam BMP_IMAGE = "earthrise_320x240.mem";
    localparam BMP_PALETTE = "earthrise_320x240_palette.mem";

    logic [BMP_ADDRW-1:0] bmp_addr_read;
    logic [BMP_DATAW-1:0] colr_idx;

    bram_sdp #(
        .WIDTH(BMP_DATAW),
        .DEPTH(BMP_PIXELS),
        .INIT_F(BMP_IMAGE)
    ) bram_bmp ( 
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(0),
        .addr_write(),
        .addr_read(bmp_addr_read),
        .data_in(),
        .data_out(colr_idx)
    );

    // Vivado makes this a LUT ROM
    logic [11:0] palette [0:15];  // 16 x 12-bit colour palette entries
    logic [11:0] colr;
    initial begin
        $display("Loading palette.");
        $readmemh(BMP_PALETTE, palette);  // bitmap palette to load
    end

    // line buffer
    localparam LB_SCALE_V = 2;                // factor to scale vertical drawing
    localparam LB_SCALE_H = 2;                // factor to scale horizontal drawing
    localparam LB_LINE  = 640 / LB_SCALE_H;   // line length
    localparam LB_ADDRW = $clog2(LB_LINE);    // line address width
    localparam LB_WIDTH = 4;                  // 4-bits per colour channel

    // line buffer read port (pixel clock)
    logic [LB_ADDRW-1:0] lb_addr_read_pix;
    logic [LB_WIDTH-1:0] lb0_out_pix, lb1_out_pix, lb2_out_pix;

    // line buffer write port (system clock - latency corrected)
    logic lb_re;  // signals when the line buffer needs to read data from bitmap
    logic [2:0] lb_we, lb_we_l1;
    logic [LB_ADDRW-1:0] lb_addr_write, lb_addr_write_l1;
    logic [LB_WIDTH-1:0] lb0_in, lb1_in, lb2_in;

    // latency correction
    always_ff @(posedge clk_pix) begin
        lb_we_l1 <= lb_we;
        lb_addr_write_l1 <= lb_addr_write;
    end

    linebuffer #(
        .WIDTH(LB_WIDTH),
        .DEPTH(LB_LINE)
        ) lb (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(lb_we_l1),                  // use lb_we_l1 to correct for latency
        .addr_write(lb_addr_write_l1),  // use lb_addr_write_l1 to correct for latency
        .addr_read(lb_addr_read_pix),
        .data_in_0(lb0_in),
        .data_in_1(lb1_in),
        .data_in_2(lb2_in),
        .data_out_0(lb0_out_pix),
        .data_out_1(lb1_out_pix),
        .data_out_2(lb2_out_pix)
    );

    // address for lb to read from bitmap
    logic [BMP_ADDRW-1:0] lb_bmp_addr_read;
    always_ff @(posedge clk_pix) begin
        if (frame_end) begin
            lb_bmp_addr_read <= 0;
        end else if (lb_re) begin
            lb_bmp_addr_read <= lb_bmp_addr_read + 1;
        end
    end

    // calculate linebuffer system address
    logic [$clog2(LB_SCALE_V)-1:0] lb_repeat;  // repeat line based on scale
    always_ff @(posedge clk_pix) begin
        if (line_start) begin  // start new line
            if (lb_repeat == 0) begin  // time to read a fresh line of data?
                lb_re <= 1;
                lb_we <= 3'b111;
                lb_addr_write <= 0;
            end
            lb_repeat <= (lb_repeat == LB_SCALE_V-1) ? 0 : lb_repeat + 1;
        end else begin
            if (lb_addr_write < LB_LINE-1) begin  // next pixel
                lb_addr_write <= lb_addr_write + 1;
            end else begin  // disable drawing at end of line
                lb_re <= 0;
                lb_we <= 0;
            end
        end
    end

    // calculate linebuffer pixel address
    logic [$clog2(LB_SCALE_H)-1:0] scale_pix_cnt;
    always_ff @(posedge clk_pix) begin
        if (sx == 798) begin  // address 0 when sx=799, so we need to set when sx=798 (latency=1)
            lb_addr_read_pix <= 0;
            scale_pix_cnt <= 0;
        end else if (lb_addr_read_pix < LB_LINE-1) begin
            scale_pix_cnt <= (scale_pix_cnt < LB_SCALE_H-1) ? scale_pix_cnt + 1 : 0;
            if (scale_pix_cnt == LB_SCALE_H-1) lb_addr_read_pix <= lb_addr_read_pix + 1;
        end
    end

    // read into line buffer
    always_comb begin
        bmp_addr_read = lb_bmp_addr_read;
        lb0_in = colr[3:0];
        lb1_in = colr[7:4];
        lb2_in = colr[11:8];
    end

    // lookup colour in CLUT
    always_ff @(posedge clk_pix) begin
        colr <= palette[colr_idx];
    end

    // VGA output
    always_comb begin
        vga_r = de ? lb2_out_pix : 4'h0;
        vga_g = de ? lb1_out_pix : 4'h0;
        vga_b = de ? lb0_out_pix : 4'h0;
    end
endmodule
