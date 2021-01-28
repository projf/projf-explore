// Project F: Framebuffers - Top David Fizzle (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_david_fizzle (
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

    // framebuffer (FB)
    localparam FB_WIDTH   = 160;
    localparam FB_HEIGHT  = 120;
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "david.mem";
    localparam FB_PALETTE = "david_palette.mem";

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_cidx_write, fb_cidx_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) framebuffer (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb_cidx_read)
    );

    // draw a horizontal line at the top of the framebuffer
    always @(posedge clk_pix) begin
        if (sy >= V_RES) begin  // draw in blanking interval
            if (fb_we == 0 && fb_addr_write != FB_WIDTH-1) begin
                fb_cidx_write <= 4'h0;  // first palette entry (white)
                fb_we <= 1;
            end else if (fb_addr_write != FB_WIDTH-1) begin
                fb_addr_write <= fb_addr_write + 1;
            end else begin
                fb_we <= 0;
            end
        end
    end

    // fizzlebuffer (FZ)
    logic [FB_ADDRW-1:0] fz_addr_write;
    logic fz_en_in, fz_en_out;
    logic fz_we;

    bram_sdp #(
        .WIDTH(1),
        .DEPTH(FB_PIXELS),
        .INIT_F("")
    ) fz_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fz_we),
        .addr_write(fz_addr_write),
        .addr_read(fb_addr_read),  // share read address with FB
        .data_in(fz_en_in),
        .data_out(fz_en_out)
    );

    // 15-bit LFSR (160x120 < 2^15)
    logic lfsr_en;
    logic [14:0] lfsr;
    lfsr #(
        .LEN(15),
        .TAPS(15'b110000000000000)
    ) lsfr_fz (
        .clk(clk_pix),
        .rst(!clk_locked),
        .en(lfsr_en),
        .sreg(lfsr)
    );

    localparam FADE_WAIT = 600;   // wait for 600 frames before fading
    localparam FADE_RATE = 3200;  // every 3200 pixel clocks update LFSR
    logic [$clog2(FADE_WAIT)-1:0] cnt_fade_wait;
    logic [$clog2(FADE_RATE)-1:0] cnt_fade_rate;
    always_ff @(posedge clk_pix) begin
        if (sy == V_RES && sx == H_RES) begin  // start of blanking
            cnt_fade_wait <= (cnt_fade_wait != FADE_WAIT-1) ?
                cnt_fade_wait + 1 : cnt_fade_wait;
        end
        if (cnt_fade_wait == FADE_WAIT-1) begin
            cnt_fade_rate <= (cnt_fade_rate == FADE_RATE) ?
                0 : cnt_fade_rate + 1;
        end
    end

    always_comb begin
        fz_addr_write = lfsr;
        if (cnt_fade_rate == FADE_RATE) begin
            lfsr_en = 1;
            fz_we = 1;
            fz_en_in = 1;
        end else begin
            lfsr_en = 0;
            fz_we = 0;
            fz_en_in = 0;
        end
    end

    // linebuffer (LB) - more logic will be moved into module in later version
    localparam LB_SCALE_V = 4;               // scale vertical drawing
    localparam LB_SCALE_H = 4;               // scale horizontal drawing
    localparam LB_LEN = H_RES / LB_SCALE_H;  // line length
    localparam LB_WIDTH = 4;                 // bits per colour channel

    // LB data in from FB
    logic lb_en_in, lb_en_in_1;  // allow for BRAM latency correction
    logic [LB_WIDTH-1:0] lb_in_0, lb_in_1, lb_in_2;

    // correct vertical scale: if scale is 0, set to 1
    logic [$clog2(LB_SCALE_V+1):0] scale_v_cor;
    always_comb scale_v_cor = (LB_SCALE_V == 0) ? 1 : LB_SCALE_V;

    // count screen lines for vertical scaling - read when cnt_scale_v==0
    logic [$clog2(LB_SCALE_V):0] cnt_scale_v;
    always_ff @(posedge clk_pix) begin
        /* verilator lint_off WIDTH */
        if (sx == 0)
            cnt_scale_v <= (cnt_scale_v == scale_v_cor-1) ? 0 : cnt_scale_v + 1;
        /* verilator lint_on WIDTH */
        if (sy == V_RES_FULL-1) cnt_scale_v <= 0;
    end

    logic [$clog2(FB_WIDTH)-1:0] fb_h_cnt;  // counter for FB pixels on line
    always_ff @(posedge clk_pix) begin
        if (sy == V_RES_FULL-1 && sx == H_RES-1) fb_addr_read <= 0;

        // reset horizontal counter at the start of blanking on reading lines
        if (cnt_scale_v == 0 && sx == H_RES) begin
            if (fb_addr_read < FB_PIXELS-1) fb_h_cnt <= 0;  // read all pixels?
        end

        // read each pixel on FB line and write to LB
        if (fb_h_cnt < FB_WIDTH) begin
            lb_en_in <= 1;
            fb_h_cnt <= fb_h_cnt + 1;
            fb_addr_read <= fb_addr_read + 1;
        end else begin
            lb_en_in <= 0;
        end

        // enable LB data in with latency correction
        lb_en_in_1 <= lb_en_in;
    end

    // LB data out to display
    logic [LB_WIDTH-1:0] lb_out_0, lb_out_1, lb_out_2;

    linebuffer #(
        .WIDTH(LB_WIDTH),
        .LEN(LB_LEN)
        ) lb_inst (
        .clk_in(clk_pix),
        .clk_out(clk_pix),
        .en_in(lb_en_in_1),  // correct for BRAM latency
        .en_out(sy < V_RES && sx < H_RES),
        .rst_in(sx == H_RES),  // reset at start of horizontal blanking
        .rst_out(sx == H_RES),
        .scale(LB_SCALE_H),
        .data_in_0(lb_in_0),
        .data_in_1(lb_in_1),
        .data_in_2(lb_in_2),
        .data_out_0(lb_out_0),
        .data_out_1(lb_out_1),
        .data_out_2(lb_out_2)
    );

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
    always_ff @(posedge clk_pix) begin
        {lb_in_2, lb_in_1, lb_in_0} <= fz_en_out ? 12'hA00 : clut_colr;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= de ? lb_out_2 : 4'h0;
        vga_g <= de ? lb_out_1 : 4'h0;
        vga_b <= de ? lb_out_0 : 4'h0;
    end
endmodule
