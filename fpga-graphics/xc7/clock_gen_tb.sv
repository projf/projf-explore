// Project F: FPGA Graphics - Clock Generation Test Bench (XC7)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module clock_gen_tb();

    parameter CLK_PERIOD = 10;

    logic rst, clk_100m;

    // 640x480p60 clocks
    logic clk_480p;
    logic clk_locked_480p;

    clock_gen clock_gen_480p (
       .clk(clk_100m),
       .rst,
       .clk_pix(clk_480p),
       .clk_locked(clk_locked_480p)
    );

    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        clk_100m = 1;
        rst = 1;
        #100
        rst = 0;

        #12000
        $finish;
    end

endmodule
