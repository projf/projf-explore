// Project F Library - Square Root (Integer) Test Bench (XC7)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sqrt_int_tb();

    parameter CLK_PERIOD = 10;
    parameter WIDTH = 8;

    logic clk;
    logic start;             // start signal
    logic busy;              // calculation in progress
    logic valid;             // root and rem are valid
    logic [WIDTH-1:0] rad;   // radicand
    logic [WIDTH-1:0] root;  // root
    logic [WIDTH-1:0] rem;   // remainder

    sqrt_int #(.WIDTH(WIDTH)) sqrt_inst (.*);

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\tsqrt(%d) =%d (rem =%d) (V=%b)", $time, rad, root, rem, valid);
    end

    initial begin
                clk = 1;

        #100    rad = 8'b00000000;  // 0
                start = 1;
        #10     start = 0;

        #50     rad = 8'b00000001;  // 1
                start = 1;
        #10     start = 0;

        #50     rad = 8'b01111001;  // 121
                start = 1;
        #10     start = 0;

        #50     rad = 8'b01010001;  // 81
                start = 1;
        #10     start = 0;

        #50     rad = 8'b01011010;  // 90
                start = 1;
        #10     start = 0;

        #50     rad = 8'b11111111;  // 255
                start = 1;
        #10     start = 0;

        #50     $finish;
    end
endmodule
