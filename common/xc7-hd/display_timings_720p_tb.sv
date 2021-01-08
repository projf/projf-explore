// Project F: 1280x720p60 Display Timings Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module display_timings_720p_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk_100m;

    // pixel clocks
    logic clk_pix;                  // pixel clock (74.25 MHz)
    logic clk_pix_5x;               // 5x pixel clock for 10:1 DDR SerDes
    logic clk_pix_locked;           // pixel clocks locked?
    clock_gen_pix clock_1280x720 (
        .clk_100m,
        .rst(rst),
        .clk_pix,
        .clk_pix_5x,
        .clk_pix_locked
    );

    // display timings
    logic [10:0] sx, sy;
    logic hsync, vsync, de;
    display_timings_720p timings_1280x720 (
        .clk_pix,
        .rst(!clk_pix_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        clk_100m = 1;

        #100 rst = 0;
        #18_000_000 $finish;  // 18 ms (one frame is 16.7 ms)
    end
endmodule
