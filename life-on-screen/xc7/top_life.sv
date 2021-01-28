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
    localparam SEED_FILE = "simple_life.mem";  // seed to initiate universe with

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
    logic [FB_DATAW-1:0] pix_in, pix_out;

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
        .data_out(pix_out)
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

    // linebuffer (LB) - more logic will be moved into module in later version
    localparam LB_SCALE_V = 8;               // scale vertical drawing
    localparam LB_SCALE_H = 8;               // scale horizontal drawing
    localparam LB_LEN = H_RES / LB_SCALE_H;  // line length
    localparam LB_WIDTH = 4;                 // bits per colour channel

    // LB data in from FB
    logic [FB_ADDRW-1:0] lb_fb_addr;
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
        if (sy == V_RES_FULL-1 && sx == H_RES-1) lb_fb_addr <= 0;

        // reset horizontal counter at the start of blanking on reading lines
        if (cnt_scale_v == 0 && sx == H_RES) begin
            if (lb_fb_addr < FB_PIXELS-1) fb_h_cnt <= 0;  // read all pixels?
        end

        // read each pixel on FB line and write to LB
        if (fb_h_cnt < FB_WIDTH) begin
            lb_en_in <= 1;
            fb_h_cnt <= fb_h_cnt + 1;
            lb_fb_addr <= lb_fb_addr + 1;
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

    // sim can run when linebuffer is not using framebuffer
    always_comb life_run = (cnt_scale_v != 0);  // OK if FB line < blanking length

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

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= de ? lb_out_2 : 4'h0;
        vga_g <= de ? lb_out_1 : 4'h0;
        vga_b <= de ? lb_out_0 : 4'h0;
    end
endmodule
