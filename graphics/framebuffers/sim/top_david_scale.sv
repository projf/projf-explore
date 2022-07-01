// Project F: Framebuffers - Scaled David (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_david_scale #(parameter CORDW=16) (  // signed coordinate width (bits)
    input  wire logic clk_pix,      // pixel clock
    input  wire logic rst_pix,      // sim reset
    output      logic signed [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic signed [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,       // data enable (low in blanking interval)
    output      logic sdl_frame,    // high at start of frame
    output      logic [7:0] sdl_r,  // 8-bit red
    output      logic [7:0] sdl_g,  // 8-bit green
    output      logic [7:0] sdl_b   // 8-bit blue
    );

    // display sync signals and coordinates
    logic signed [CORDW-1:0] sx, sy;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de,
        .frame,
        .line
    );

    // colour parameters
    localparam CHANW = 4;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam CIDXW = 4;        // colour index width (bits)
    // localparam PAL_FILE = "../../../lib/res/palettes/grey16_4b.mem";  // palette file
    localparam PAL_FILE = "../../../lib/res/palettes/sweetie16_4b.mem";  // palette file

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;  // framebuffer width in pixels
    localparam FB_HEIGHT = 120;  // framebuffer width in pixels
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel
    // localparam FB_IMAGE  = "../res/david/david.mem";  // bitmap file
    localparam FB_IMAGE  = "../../../lib/res/test/test_box_160x120.mem";  // bitmap file

    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .we(),
        .addr_write(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_read(fb_addr_read),
        /* verilator lint_off PINCONNECTEMPTY */
        .data_in(),
        /* verilator lint_on PINCONNECTEMPTY */
        .data_out(fb_colr_read)
    );

    // linebuffer
    localparam LB_SCALE = 4;
    logic [$clog2(LB_SCALE):0] cnt_lb_rline;  // count lines for scaling
    always_ff @(posedge clk_pix) begin
        if (sy == 0) cnt_lb_rline <= 0;
        else if (line) begin
            cnt_lb_rline <= (cnt_lb_rline == LB_SCALE-1) ? 0 : cnt_lb_rline + 1;
        end
    end

    // linebuffer enable
    localparam LAT = 2;  // latency compensation: LB+1, CLUT+1
    logic lb_en_in;   // enable linebuffer in
    logic lb_en_out;  // linebuffer enable out
    always_comb begin
        lb_en_in  = (sy >= 0 && cnt_lb_rline == 0 && cnt_lbx < FB_WIDTH);
        lb_en_out = (sy >= 0 && sy < FB_HEIGHT * LB_SCALE
            && sx >= 0-LAT && sx < (FB_WIDTH * LB_SCALE)-LAT);
    end

    // calculate framebuffer read address for linebuffer
    logic [$clog2(FB_WIDTH)-1:0] cnt_lbx;
    always_ff @(posedge clk_pix) begin
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (line) begin  // reset horizontal counter at start of line
            cnt_lbx <= 0;
        end else if (lb_en_in) begin
            fb_addr_read <= fb_addr_read + 1;
            cnt_lbx <= cnt_lbx + 1;
        end
    end

    logic [FB_DATAW-1:0] lb_colr_out;
    linebuffer_simple #(
        .DATAW(CIDXW),
        .LEN(FB_WIDTH),
        .SCALE(LB_SCALE)
    ) lb_sf (
        .clk_in(clk_pix),
        .clk_out(clk_pix),
        .rst_in(line),
        .rst_out(line),
        .en_in(lb_en_in),
        .en_out(lb_en_out),
        .data_in(fb_colr_read),
        .data_out(lb_colr_out)
    );

    // colour lookup table
    logic [COLRW-1:0] fb_pix_colr;
    clut_simple #(
        .COLRW(COLRW),
        .CIDXW(CIDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(0),
        .cidx_write(0),
        .cidx_read(lb_colr_out),
        .colr_in(0),
        .colr_out(fb_pix_colr)
    );

    // paint screen
    logic paint_area;  // area of screen to paint
    logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
    always_comb begin
        paint_area = (sy >= 0 && sy < FB_HEIGHT * LB_SCALE
            && sx >= 0 && sx < FB_WIDTH * LB_SCALE);
        {paint_r, paint_g, paint_b} = (de && paint_area) ? fb_pix_colr: 12'h000;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_frame <= frame;
        sdl_r <= {2{paint_r}};  // double signal width (assumes CHANW=4)
        sdl_g <= {2{paint_g}};
        sdl_b <= {2{paint_b}};
    end
endmodule
