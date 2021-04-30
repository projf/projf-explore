// Project F: Life on Screen - Top Conway's Life (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_life (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    localparam GEN_FRAMES = 15;  // each generation lasts this many frames
    localparam SEED_FILE = "simple_64x48.mem";  // world seed

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        .sy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // life signals
    /* verilator lint_off UNUSED */
    logic life_start, life_alive, life_changed;
    /* verilator lint_on UNUSED */

    // start life generation in blanking every GEN_FRAMES
    logic [$clog2(GEN_FRAMES)-1:0] cnt_frames;
    always_ff @(posedge clk_pix) begin
        life_start <= 0;
        if (frame) begin
            if (cnt_frames == GEN_FRAMES-1) begin
                life_start <= 1;
                cnt_frames <= 0;
            end else cnt_frames <= cnt_frames + 1;
        end
    end

    // framebuffer (FB)
    localparam FB_WIDTH   = 64;
    localparam FB_HEIGHT  = 48;
    localparam FB_CIDXW   = 2;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 10;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "../res/life_palette.mem";

    logic fb_we;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    framebuffer #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_pix),
        .clk_pix(clk_pix),
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de,
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // select colour based on cell state
    always_comb fb_cidx = {1'b0, life_alive};

    life #(
        .CORDW(CORDW),
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .F_INIT({"../res/seed/",SEED_FILE})
    ) life_inst (
        .clk(clk_pix),          // clock
        .rst(1'b0),              // reset
        .start(life_start),      // start generation
        .ready(fb_we),           // cell state ready to be read
        .alive(life_alive),      // is the cell alive? (when ready)
        .changed(life_changed),  // cell's state changed (when ready)
        .x(fbx),                 // horizontal cell position
        .y(fby),                 // vertical cell position
        /* verilator lint_off PINCONNECTEMPTY */
        .running(),              // life is running
        .done()                  // generation complete (high for one tick)
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

    // Output DVI clock: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // Output DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync_p1, vsync_p1, de_p1, fb_red, fb_green, fb_blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
