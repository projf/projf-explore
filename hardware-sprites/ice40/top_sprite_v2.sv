// Project F: Hardware Sprites - Top Sprite v2 (iCEBreaker with 12-bit DVI Pmod)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v2 (
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

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    // sprite
    localparam SPR_WIDTH   = 8;  // width in pixels
    localparam SPR_HEIGHT  = 8;  // number of lines
    localparam SPR_FILE = "../res/simple/letter_f.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam DRAW_X = 0;
    localparam DRAW_Y = 0;

    // start sprite in blanking of line before first line drawn
    logic [CORDW-1:0] draw_y_cor;  // corrected for wrapping
    always_comb begin
        draw_y_cor = (DRAW_Y == 0) ? V_RES_FULL - 1 : DRAW_Y - 1;
        spr_start = (sy == draw_y_cor && sx == H_RES);
    end

    sprite_v2 #(
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

    // DVI clock output
    SB_IO #(
        .PIN_TYPE(6'b010000)
    ) dvi_clk_buf (
        .PACKAGE_PIN(dvi_clk),
        .CLOCK_ENABLE(1'b1),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // DVI output
    always_ff @(posedge clk_pix) begin
        dvi_de <= de;
        dvi_r <= (de && spr_pix) ? 4'hF: 4'h0;
        dvi_g <= (de && spr_pix) ? 4'hC: 4'h0;
        dvi_b <= (de && spr_pix) ? 4'h0: 4'h0;
    end
endmodule
