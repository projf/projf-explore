// Project F: FPGA Graphics - 640x480 Display Timings Test Bench
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module display_timings_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk_100m;

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_100m),
       .rst(rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    logic [9:0] sx, sy;
    logic hsync, vsync;
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),
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
