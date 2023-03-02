// Project F: Racing the Beam - Hitomezashi (iCEBreaker 12-bit DVI Pmod)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hitomezashi (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button
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
    logic clk_pix_locked;
    clock_480p clock_pix_inst (
       .clk_12m,
       .rst(btn_rst),
       .clk_pix,
       .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 10;  // screen coordinate width in bits
    /* verilator lint_off UNUSED */
    logic [CORDW-1:0] sx, sy;
    /* verilator lint_on UNUSED */
    logic hsync, vsync, de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // stitch start values: MSB first, so we can write left to right
    /* verilator lint_off LITENDIAN */
    logic [0:39] v_start;  // 40 vertical lines
    logic [0:29] h_start;  // 30 horizontal lines
    /* verilator lint_on LITENDIAN */

    initial begin  // random start values
        v_start = 40'b01100_00101_00110_10011_10101_10101_01111_01101;
        h_start = 30'b10111_01001_00001_10100_00111_01010;
    end

    // paint stitch pattern with 16x16 pixel grid
    logic stitch;
    logic v_line, v_on;
    logic h_line, h_on;
    always_comb begin
        v_line = (sx[3:0] == 4'b0000);
        h_line = (sy[3:0] == 4'b0000);
        v_on = sy[4] ^ v_start[sx[9:4]];
        h_on = sx[4] ^ h_start[sy[8:4]];
        stitch = (v_line && v_on) || (h_line && h_on);
    end

    // paint colour: yellow lines, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (stitch) ? 4'hF : 4'h1;
        paint_g = (stitch) ? 4'hC : 4'h3;
        paint_b = (stitch) ? 4'h0 : 4'h7;
    end

    // display colour: paint colour but black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // DVI Pmod output
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, display_r, display_g, display_b}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // DVI Pmod clock output: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );
endmodule
