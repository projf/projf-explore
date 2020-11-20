// Project F: Framebuffers - Linebuffer (New!) Test Bench
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_tb();

    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    logic clk_25m;
    logic clk_100m;

    parameter LB_WIDTH = 4;
    parameter LB_LEN = 8;
    parameter SCALEW = 3;  // Scale by up to 2^3=8

    logic en_in, en_out;
    logic rst_in, rst_out;
    logic [SCALEW-1:0] scale_out;
    logic [LB_WIDTH-1:0] data_in_0, data_in_1, data_in_2;
    logic [LB_WIDTH-1:0] data_out_0, data_out_1, data_out_2;

    linebuffer_new #(
        .WIDTH(LB_WIDTH),
        .LEN(LB_LEN),
        .SCALEW(SCALEW)
        ) lb (
        .clk_in(clk_100m),
        .clk_out(clk_25m),
        .en_in,
        .en_out,
        .rst_in,
        .rst_out,
        .scale_out,
        .data_in_0,
        .data_in_1,
        .data_in_2,
        .data_out_0,
        .data_out_1,
        .data_out_2
    );

    // generate clocks
    always #(CLK_PERIOD_100M / 2) clk_100m = ~clk_100m;
    always #(CLK_PERIOD_25M / 2) clk_25m = ~clk_25m;

    initial begin
        clk_100m = 1;
        rst_in  = 1;
        en_in  = 0;

        #100 
        rst_in = 0;
        en_in = 1;
        data_in_0 = 4'b1010;  // 0xA
        data_in_1 = 4'b0101;  // 0x5
        data_in_2 = 4'b1111;  // 0xF

        #10
        data_in_0 = 4'b1000;  // 0x8
        data_in_1 = 4'b0100;  // 0x4
        data_in_2 = 4'b0010;  // 0x2
        
        #10
        data_in_0 = 4'b0000;  // 0x0
        data_in_1 = 4'b0010;  // 0x2
        data_in_2 = 4'b0001;  // 0x1

        #10 en_in = 0;

        #20
        en_in = 1;
        data_in_0 = 4'b0101;  // 0x5
        data_in_1 = 4'b1010;  // 0xA
        data_in_2 = 4'b0000;  // 0x0

        #10
        data_in_0 = 4'b0000;  // 0x0
        data_in_1 = 4'b0010;  // 0x2
        data_in_2 = 4'b0001;  // 0x1

        #10
        data_in_0 = 4'b1000;  // 0x8
        data_in_1 = 4'b0100;  // 0x4
        data_in_2 = 4'b0010;  // 0x2

        #30 en_in = 0;
    end

    initial begin
        clk_25m  = 1;
        rst_out = 1;
        en_out = 0;
        scale_out = 0;
        
        #120 rst_out = 0;
        en_out = 1;

        #40 en_out = 0;
        #40 en_out = 1;
        #280 en_out = 0;

        #80 rst_out = 1;
        scale_out = 1;
        #40 rst_out = 0;
        #40 en_out = 1;
        #320 en_out = 0;

        #80 rst_out = 1;
        scale_out = 2;
        #40 rst_out = 0;
        #40 en_out = 1;
        #640 en_out = 0;
        
        #80 rst_out = 1;
        scale_out = 5;
        #40 rst_out = 0;
        #40 en_out = 1;
        #1600 en_out = 0;

        #1000 $finish;
    end
endmodule
