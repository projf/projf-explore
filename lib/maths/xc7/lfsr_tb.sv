// Project F Library - Galois Linear-Feedback Shift Register Test Bench (XC7)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module lfsr_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    parameter LEN  = 8;
    parameter TAPS = 8'b10111000;
    logic rst;
    logic clk_100m;
    logic en;
    logic [LEN-1:0] seed;
    logic [LEN-1:0] sreg;

    lfsr #(
        .LEN(LEN),
        .TAPS(TAPS)
        ) lfsr_inst (
        .clk(clk_100m),
        .rst,
        .en,
        .seed,
        .sreg
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        seed = '1;
        clk_100m = 1;

        #100 rst = 0;
             en = 1;
        #10000 $finish;
    end
endmodule
