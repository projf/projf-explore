// Project F Library - Clock Generation Test Bench (XC7)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module clock_tb ();

    parameter CLK_PERIOD = 10;

    logic rst, clk_100m;

    // 640x480p60 clocks
    logic clk_480p, clk_480p_5x;
    logic clk_locked_480p;

    clock_480p clock_480p_inst (
       .clk_100m,
       .rst,
       .clk_pix(clk_480p),
       .clk_pix_5x(clk_480p_5x),
       .clk_pix_locked(clk_locked_480p)
    );

    // 1280x720p60 clocks
    logic clk_720p, clk_720p_5x;
    logic clk_locked_720p;

    clock_720p clock_720p_inst (
       .clk_100m,
       .rst,
       .clk_pix(clk_720p),
       .clk_pix_5x(clk_720p_5x),
       .clk_pix_locked(clk_locked_720p)
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
