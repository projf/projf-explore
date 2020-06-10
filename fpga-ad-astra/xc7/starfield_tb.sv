// Project F: FPGA Graphics - Starfield Testbench
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module starfield_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk_100m;

    // starfields
    logic sf_on;
    logic [7:0] sf_star;

    starfield starfield_inst (
        .clk(clk_100m),
        .en(1'b1),
        .rst,
        .sf_on(sf_on),
        .sf_star(sf_star)
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        clk_100m = 1;

        #100 rst = 0;
        #4_200_000 $finish;
    end
endmodule
