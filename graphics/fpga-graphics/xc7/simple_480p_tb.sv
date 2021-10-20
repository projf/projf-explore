// Project F: FPGA Graphics - Simple 640x480p60 Display Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module simple_480p_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    parameter CORDW = 10;  // screen coordinate width in bits

    logic rst;
    logic clk_100m;

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(rst),
       .clk_pix,
       .clk_locked
    );

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_480p display_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
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
        #20_000_000 $finish;  // 18 ms (one frame is 16.7 ms)
    end
endmodule
