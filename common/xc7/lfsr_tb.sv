// Project F: Galois Linear-Feedback Shift Register Test Bench (XC7)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module lfsr_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk_100m;
    logic en;
    logic [7:0] sreg;

    lfsr lfsr_inst (
        .clk(clk_100m),
        .rst,
        .en,
        .sreg
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        clk_100m = 1;

        #100 rst = 0;
             en = 1;
        #10000 $finish;
    end
endmodule
