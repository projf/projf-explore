// Project F: FPGA Graphics - Simple 1280x720p60 Display Test Bench (XC7)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module simple_720p_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    parameter CORDW = 12;  // screen coordinate width in bits

    logic rst;
    logic clk_100m;

    // generate pixel clock
    logic clk_pix;         // pixel clock
    logic clk_pix_5x;      // 5x pixel clock for 10:1 DDR SerDes
    logic clk_pix_locked;  // pixel clock locked?
    clock_gen_720p clock_pix_inst (
        .clk_100m,
        .rst(rst),
        .clk_pix,
        .clk_pix_5x,
        .clk_pix_locked
    );

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_720p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
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
