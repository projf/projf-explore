// Project F: Square - Top (Arty)
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-on-screen/

`default_nettype none
`timescale 1ns / 1ps

module top (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst,          // reset button (active low)
    output      logic vga_hsync,        // horizontal sync
    output      logic vga_vsync,        // vertical sync
    output      logic [3:0] vga_red,    // 4-bit VGA red
    output      logic [3:0] vga_green,  // 4-bit VGA green
    output      logic [3:0] vga_blue    // 4-bit VGA blue
    );

    // divide 100 MHz clock by four to create 25 MHz strobe
    logic stb_pix;
    logic [1:0] cnt;
    always_ff @(posedge clk_100m) begin
        {stb_pix, cnt} <= cnt + 1;
    end

    // screen position
    logic [9:0] sx;
    logic [9:0] sy;

    // blanking signals: sync and data enable
    logic vsync;
    logic hsync;
    logic de;

    display_timings timings_640x480 (
        .clk(clk_100m),
        .stb_pix,
        .rst(!btn_rst),  // reset button is active low
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // 32 x 32 pixel square
    logic q_draw;
    always_comb q_draw = (sx < 32 && sy < 32) ? 1 : 0;

    // VGA output
    always_comb begin
        vga_hsync = hsync;
        vga_vsync = vsync;
        vga_red   = !de ? 4'h0 : (q_draw ? 4'hD : 4'h3);
        vga_green = !de ? 4'h0 : (q_draw ? 4'hA : 4'h7);
        vga_blue  = !de ? 4'h0 : (q_draw ? 4'h3 : 4'hD);
    end
endmodule
