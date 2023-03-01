// Project F: Racing the Beam - Hello (Verilator SDL)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hello #(parameter CORDW=10) (  // coordinate width
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

    // bitmap: MSB first, so we can write pixels left to right
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

    // paint colour: yellow lines, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (picture) ? 4'hF : 4'h1;
        paint_g = (picture) ? 4'hC : 4'h3;
        paint_b = (picture) ? 4'h0 : 4'h7;
    end

    // display colour: black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r <= {2{display_r}};  // double signal width from 4 to 8 bits
        sdl_g <= {2{display_g}};
        sdl_b <= {2{display_b}};
    end
endmodule
