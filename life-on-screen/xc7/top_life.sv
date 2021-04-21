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
    localparam SEED_FILE = "simple_64x48.mem";  // world seed

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
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

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m),
                 .rst_i(1'b0), .rst_o(1'b0), .i(frame), .o(frame_sys));

    // life signals
    /* verilator lint_off UNUSED */
    logic life_start, life_alive, life_changed;
    /* verilator lint_on UNUSED */

    // start life generation in blanking every GEN_FRAMES
    logic [$clog2(GEN_FRAMES)-1:0] cnt_frames;
    always @(posedge clk_100m) begin
        life_start <= 0;
        if (frame_sys) begin
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
    localparam FB_PALETTE = "life_palette.mem";

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
        .clk_sys(clk_100m),
        .clk_pix,
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

    // select colour based on cell state and whether it's changed
    always_comb fb_cidx = {1'b0, life_alive};

    life #(
        .CORDW(CORDW),
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .F_INIT(SEED_FILE)
    ) life_inst (
        .clk(clk_100m),          // clock
        .rst(1'b0),              // reset
        .start(life_start),      // start sim generation
        .ready(fb_we),           // cell state ready to be read
        .alive(life_alive),      // is the cell alive? (when ready)
        .changed(life_changed),  // cell's state changed (when ready)
        .x(fbx),                 // horizontal cell position
        .y(fby),                 // vertical cell position
        /* verilator lint_off PINCONNECTEMPTY */
        .running(),              // sim is running
        .done()                  // sim complete (high for one tick)
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_p1;
        vga_vsync <= vsync_p1;
        vga_r <= fb_red;
        vga_g <= fb_green;
        vga_b <= fb_blue;
    end
endmodule