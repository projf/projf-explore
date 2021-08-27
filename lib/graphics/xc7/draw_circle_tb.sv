// Project F Library - Draw Circle Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_circle_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 9;  // -256 to +255
    logic signed [CORDW-1:0] x, y;
    logic signed [CORDW-1:0] x0, y0, r0;
    logic start, oe, drawing, busy, done;
    draw_circle #(.CORDW(CORDW)) draw_circle_inst (
        .clk,
        .rst,
        .start,
        .oe,
        .x0,
        .y0,
        .r0,
        .x,
        .y,
        .drawing,
        .busy,
        .done
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\t(%d, %d) >%b Done=%b", $time, x, y, drawing, done);
    end

    initial begin
        rst = 1;
        clk = 1;
        #100    rst = 0;
                oe = 1;

        #10     $display("case 0: at (0,0) with r=4");
                x0 = 9'sd0;
                y0 = 9'sd0;
                r0 = 9'sd4;
                start = 1;
        #10     start = 0;

        #1000   $display("case 1a: at (2,2) with r=1");
                x0 = 9'sd2;
                y0 = 9'sd2;
                r0 = 9'sd1;
                start = 1;
        #10     start = 0;

        #1000   $display("case 1b: at (2,2) with r=0");
                x0 = 9'sd2;
                y0 = 9'sd2;
                r0 = 9'sd0;
                start = 1;
        #10     start = 0;

        #1000   $display("case 2: at (-8,0) with r=19");
                x0 = -9'sd8;
                y0 = 9'sd0;
                r0 = 9'sd19;
                start = 1;
        #10     start = 0;

        #2000   $display("case 3: at (0,0) with r=255");
                x0 = 9'sd0;
                y0 = 9'sd0;
                r0 = 9'sd255;
                start = 1;
        #10     start = 0;

        #24000   $finish;
    end
endmodule
