// Project F: Hardware Sprites - Top Sprite v3 (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v3 (
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

    // sprite
    localparam SPR_WIDTH   =  8;  // width in pixels
    localparam SPR_HEIGHT  =  8;  // number of lines
    localparam SPR_SCALE_X = 10;  // width scale-factor
    localparam SPR_SCALE_Y = 10;  // height scale-factor
    localparam SPR_FILE = "letter_f.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam DRAW_X = 280;
    localparam DRAW_Y = 200;

    // start sprite in blanking of line before first line drawn
    logic [CORDW-1:0] draw_y_cor;  // corrected for wrapping
    always_comb begin
        draw_y_cor = (DRAW_Y == 0) ? V_RES_FULL - 1 : DRAW_Y - 1;
        spr_start = (sy == draw_y_cor && sx == H_RES);
    end

    sprite_v3 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .SPR_FILE(SPR_FILE)
        ) spr_instance (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .sx,
        .sprx(DRAW_X),
        .pix(spr_pix)
    );

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= (de && spr_pix) ? 4'hF: 4'h0;
        vga_g <= (de && spr_pix) ? 4'hC: 4'h0;
        vga_b <= (de && spr_pix) ? 4'h0: 4'h0;
    end
endmodule
