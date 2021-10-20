// Project F: FPGA Graphics - Top Square (Verilator SDL)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_square #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,         // pixel clock
    input  wire logic rst,             // reset
    output      logic [CORDW-1:0] sx,  // horizontal screen position
    output      logic [CORDW-1:0] sy,  // vertical screen position
    output      logic de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,     // 8-bit red
    output      logic [7:0] sdl_g,     // 8-bit green
    output      logic [7:0] sdl_b      // 8-bit blue
    );

    // display sync signals and coordinates
    simple_480p display_inst (
        .clk_pix,
        .rst,
        .sx,
        .sy,
        .hsync(),
        .vsync(),
        .de
    );

    // 32 x 32 pixel square
    logic q_draw;
    always_comb q_draw = (sx < 32 && sy < 32) ? 1 : 0;

    // SDL output
    always_ff @(posedge clk_pix) begin
        sdl_r <= !de ? 8'h00 : (q_draw ? 8'hFF : 8'h00);
        sdl_g <= !de ? 8'h00 : (q_draw ? 8'h88 : 8'h88);
        sdl_b <= !de ? 8'h00 : (q_draw ? 8'h00 : 8'hFF);
    end
endmodule
