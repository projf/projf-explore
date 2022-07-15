// Project F: Framebuffers - David Fizzle (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/framebuffers/

`default_nettype none
`timescale 1ns / 1ps

module top_david_fizzle #(parameter CORDW=16) (  // signed coordinate width (bits)
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

    // system clock is the same as pixel clock in simulation
    logic clk_sys, rst_sys;
    always_comb begin
        clk_sys = clk_pix;
        rst_sys = rst_pix;
    end

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
    localparam PAL_FILE = "../../../lib/res/palettes/grey16_4b.mem";  // palette file

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;  // framebuffer width in pixels
    localparam FB_HEIGHT = 120;  // framebuffer width in pixels
    localparam FB_SCALE  =   4;  // framebuffer display scale via linebuffer (1-63)
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel
    localparam FB_IMAGE  = "../res/david/david.mem";  // bitmap file

    // pixel read and write addresses and colours
    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_write, fb_colr_read;

    // framebuffer memory
    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_sys),
        .clk_read(clk_sys),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_colr_write),
        .data_out(fb_colr_read)
    );

    // display flags in system clock domain
    logic frame_sys, line_sys, lb_line, lb_1st;
    xd2 xd_frame (.clk_src(clk_pix), .clk_dst(clk_sys), .src(frame), .dst(frame_sys));
    xd2 xd_line  (.clk_src(clk_pix), .clk_dst(clk_sys), .src(line),  .dst(line_sys));
    xd2 xd_read  (.clk_src(clk_pix), .clk_dst(clk_sys), .src(sy>=0), .dst(lb_line));
    xd2 xd_start (.clk_src(clk_pix), .clk_dst(clk_sys), .src(sy==0), .dst(lb_1st));

    // fizzlefade!
    logic lfsr_en;
    logic [14:0] lfsr;
    lfsr #(  // 15-bit LFSR (160x120 < 2^15)
        .LEN(15),
        .TAPS(15'b110000000000000)
    ) lsfr_fz (
        .clk(clk_sys),
        .rst(rst_sys),
        .en(lfsr_en),
        .seed(0),  // use default seed
        .sreg(lfsr)
    );

    // control fade start and rate
    localparam FADE_WAIT = 120;   // wait for N frames before fading
    localparam FADE_RATE = 2000;  // every N system cycles update LFSR
    logic [$clog2(FADE_WAIT)-1:0] cnt_wait;
    logic [$clog2(FADE_RATE)-1:0] cnt_rate;
    always_ff @(posedge clk_sys) begin
        if (frame_sys) cnt_wait <= (cnt_wait != FADE_WAIT-1) ? cnt_wait + 1 : cnt_wait;
        if (cnt_wait == FADE_WAIT-1) begin
            if (cnt_rate == FADE_RATE-1) begin
                lfsr_en <= 1;
                fb_we <= 1;
                fb_addr_write <= lfsr;
                cnt_rate <= 0;
            end else begin
                cnt_rate <= cnt_rate + 1;
                lfsr_en <= 0;
                fb_we <= 0;
            end
        end
        fb_colr_write <= 4'h7;  // fade colour
    end

    // count lines for scaling via linebuffer
    logic [$clog2(FB_SCALE):0] cnt_lb_line;
    always_ff @(posedge clk_sys) begin
        if (line_sys) begin
            if (lb_1st) cnt_lb_line <= 0;
            else cnt_lb_line <= (cnt_lb_line == FB_SCALE-1) ? 0 : cnt_lb_line + 1;
        end
    end

    // enable linebuffer input
    logic lb_en_in;
    logic [$clog2(FB_WIDTH)-1:0] cnt_lbx;
    always_comb lb_en_in = (lb_line && cnt_lb_line == 0 && cnt_lbx < FB_WIDTH);

    // calculate framebuffer read address for linebuffer
    always_ff @(posedge clk_sys) begin
        if (frame_sys) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (line_sys) begin  // reset horizontal counter at start of line
            cnt_lbx <= 0;
        end else if (lb_en_in) begin
            fb_addr_read <= fb_addr_read + 1;
            cnt_lbx <= cnt_lbx + 1;
        end
    end

    // enable linebuffer output
    logic lb_en_out;
    localparam LB_LAT = 3;  // output latency compensation: lb_en_out+1, LB+1, CLUT+1
    always_ff @(posedge clk_pix) begin
        lb_en_out <= (sy >= 0 && sy < (FB_HEIGHT * FB_SCALE)
            && sx >= -LB_LAT && sx < (FB_WIDTH * FB_SCALE) - LB_LAT);
    end

    // display linebuffer
    logic [FB_DATAW-1:0] lb_colr_out;
    linebuffer_simple #(
        .DATAW(CIDXW),
        .LEN(FB_WIDTH)
    ) linebuffer_instance (
        .clk_sys,
        .clk_pix,
        .line,
        .line_sys,
        .en_in(lb_en_in),
        .en_out(lb_en_out),
        .scale(FB_SCALE),
        .data_in(fb_colr_read),
        .data_out(lb_colr_out)
    );

    // colour lookup table (CLUT)
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
        paint_area = (sy >= 0 && sy < (FB_HEIGHT * FB_SCALE)
            && sx >= 0 && sx < FB_WIDTH * FB_SCALE);
        {paint_r, paint_g, paint_b} = (de && paint_area) ? fb_pix_colr : 12'h000;
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
