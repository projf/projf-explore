// Project F: Hardware Sprites - Top Sprite v1 (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v1 (
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
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        /* verilator lint_off PINCONNECTEMPTY */
        .frame(),
        /* verilator lint_on PINCONNECTEMPTY */
        .line
    );

    // sprite
    localparam SPR_WIDTH  = 8;  // width in pixels
    localparam SPR_HEIGHT = 8;  // number of lines
    localparam SPR_FILE = "letter_f.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam DRAW_X = 16;
    localparam DRAW_Y = 16;

    // signal to start sprite drawing
    always_comb spr_start = (line && sy == DRAW_Y);

    sprite_v1 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
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
