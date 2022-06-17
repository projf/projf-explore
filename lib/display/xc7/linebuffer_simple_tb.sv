// Project F Library - Simple Linebuffer Test Bench (XC7)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_simple_tb();
    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    // 100 MHz clock domain (LB input)
    logic clk_100m;
    logic rst_100m;

    // 25 MHz clock domain (LB output)
    logic clk_25m;
    logic rst_25m;

    // generate clocks
    always #(CLK_PERIOD_100M / 2) clk_100m = ~clk_100m;
    always #(CLK_PERIOD_25M / 2) clk_25m = ~clk_25m;

    initial begin
        clk_100m = 1;
        rst_100m = 1;

        #100 rst_100m = 0;
    end

    initial begin
        clk_25m = 1;
        rst_25m = 1;

        #100 rst_25m = 0;
    end

endmodule