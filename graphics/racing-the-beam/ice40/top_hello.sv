// Project F: Racing the Beam - Hello (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hello (
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

    // bitmap: big-endian vector, so we can write pixels left to right
    /* verilator lint_off LITENDIAN */
    logic [0:19] bmap [15];  // 20 pixels by 15 lines
    /* verilator lint_on LITENDIAN */

    initial begin
        bmap[0]  = 20'b1010_1110_1000_1000_0110;
        bmap[1]  = 20'b1010_1000_1000_1000_1010;
        bmap[2]  = 20'b1110_1100_1000_1000_1010;
        bmap[3]  = 20'b1010_1000_1000_1000_1010;
        bmap[4]  = 20'b1010_1110_1110_1110_1100;
        bmap[5]  = 20'b0000_0000_0000_0000_0000;
        bmap[6]  = 20'b1010_0110_1110_1000_1100;
        bmap[7]  = 20'b1010_1010_1010_1000_1010;
        bmap[8]  = 20'b1010_1010_1100_1000_1010;
        bmap[9]  = 20'b1110_1010_1010_1000_1010;
        bmap[10] = 20'b1110_1100_1010_1110_1110;
        bmap[11] = 20'b0000_0000_0000_0000_0000;
        bmap[12] = 20'b0000_0000_0000_0000_0000;
        bmap[13] = 20'b0000_0000_0000_0000_0000;
        bmap[14] = 20'b0000_0000_0000_0000_0000;
    end

    // paint at 32x scale in active screen area
    logic picture;
    logic [4:0] x;  // 20 columns need five bits
    logic [3:0] y;  // 15 rows need four bits
    always_comb begin
        x = sx[9:5];  // every 32 horizontal pixels
        y = sy[8:5];  // every 32 vertical pixels
        picture = de ? bmap[y][x] : 0;  // look up pixel (unless we're in blanking)
    end

    // paint colours: yellow lines, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (picture) ? 4'hF : 4'h1;
        paint_g = (picture) ? 4'hC : 4'h3;
        paint_b = (picture) ? 4'h0 : 4'h7;
    end

    // DVI Pmod output
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, paint_r, paint_g, paint_b}),
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
