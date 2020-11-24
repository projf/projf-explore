// Project F: Hardware Sprites - Top Sprite v1 (iCEBreaker with 12-bit DVI Pmod)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v1 (
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

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_12m),
       .rst(btn_rst),
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
        .hsync(dvi_hsync),
        .vsync(dvi_vsync),
        .de
    );

    // sprite
    localparam SPR_WIDTH  = 8;  // width in pixels
    localparam SPR_HEIGHT = 8;  // number of lines
    localparam SPR_FILE = "../res/simple/letter_f.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam DRAW_X = 16;
    localparam DRAW_Y = 16;

    // signal to start sprite drawing
    always_comb begin
        spr_start = (sy == DRAW_Y && sx == 0);
    end

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

    // DVI output
    always_comb begin
        dvi_clk = clk_pix;
        dvi_de  = de;
        dvi_r = (de && spr_pix) ? 4'hF: 4'h0;
        dvi_g = (de && spr_pix) ? 4'hC: 4'h0;
        dvi_b = (de && spr_pix) ? 4'h0: 4'h0;
    end
endmodule
