// Project F: Racing the Beam - Hitomezashi (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hitomezashi #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,             // pixel clock
    input  wire logic sim_rst,             // sim reset
    output      logic [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,         // 8-bit red
    output      logic [7:0] sdl_g,         // 8-bit green
    output      logic [7:0] sdl_b          // 8-bit blue
    );

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(sim_rst),
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de
    );

    // stitch start values: big-endian vector, so we can write left to right
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

    // paint colours: yellow lines, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (stitch) ? 4'hF : 4'h1;
        paint_g = (stitch) ? 4'hC : 4'h3;
        paint_b = (stitch) ? 4'h0 : 4'h7;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r <= {2{paint_r}};  // double signal width from 4 to 8 bits
        sdl_g <= {2{paint_g}};
        sdl_b <= {2{paint_b}};
    end
endmodule
