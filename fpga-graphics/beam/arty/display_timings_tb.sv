// Project F: Beam - Display Timings Test Bench
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module display_timings_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk_100m;

    // divide 100 MHz clock by four to create 25 MHz strobe
    logic stb_pix = 0;
    logic [1:0] cnt = 0;
    always_ff @(posedge clk_100m) begin
        {stb_pix, cnt} <= cnt + 1;
    end

    logic hsync;
    logic vsync;
    logic [9:0] sx;
    logic [9:0] sy;
    logic de;
    logic frame_start;

    display_timings timings_640x480 (
        .clk(clk_100m),
        .stb_pix,
        .rst,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame_start
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        clk_100m = 1;

        #100 rst = 0;
        #18_000_000 $finish;
    end
endmodule
