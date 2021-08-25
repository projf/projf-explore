// Project F Library - Draw Line Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_line_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 9;  // -256 to +255
    logic signed [CORDW-1:0] x, y;
    logic signed [CORDW-1:0] x0, y0, x1, y1;
    logic start, oe, drawing, busy, done;
    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk,
        .rst,
        .start,
        .oe,
        .x0,
        .y0,
        .x1,
        .y1,
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

        #10     $display("case 0: points (0,0) (32,17) (255,255)");
                x0 = 9'sd0;  // (0,0)
                y0 = 9'sd0;
                x1 = 9'sd0;
                y1 = 9'sd0;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd32;  // (32,17)
                y0 = 9'sd17;
                x1 = 9'sd32;
                y1 = 9'sd17;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd255;  // (255,255)
                y0 = 9'sd255;
                x1 = 9'sd255;
                y1 = 9'sd255;
                start = 1;
        #10     start = 0;

        #100    $display("case 1: (0,1) (6,4) - not steep, down");
                x0 = 9'sd0;  // left to right
                y0 = 9'sd1;
                x1 = 9'sd6;
                y1 = 9'sd4;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd6;  // right to left
                y0 = 9'sd4;
                x1 = 9'sd0;
                y1 = 9'sd1;
                start = 1;
        #10     start = 0;

        #100 $display("case 2: (1,0) (4,6) - steep, down");
                x0 = 9'sd1;  // left to right
                y0 = 9'sd0;
                x1 = 9'sd4;
                y1 = 9'sd6;
                start = 1;
        #10     start = 0;


        #100    x0 = 9'sd4;  // right to left
                y0 = 9'sd6;
                x1 = 9'sd1;
                y1 = 9'sd0;
                start = 1;
        #10     start = 0;


        #100 $display("case 3: (0,4) (6,1) - not steep, up");
                x0 = 9'sd0;  // left to right
                y0 = 9'sd4;
                x1 = 9'sd6;
                y1 = 9'sd1;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd6;  // right to left
                y0 = 9'sd1;
                x1 = 9'sd0;
                y1 = 9'sd4;
                start = 1;
        #10     start = 0;


        #100 $display("case 4: (4,0) (1,6) - steep, up");
                x0 = 9'sd4;  // left to right
                y0 = 9'sd0;
                x1 = 9'sd1;
                y1 = 9'sd6;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd1;  // right to left
                y0 = 9'sd6;
                x1 = 9'sd4;
                y1 = 9'sd0;
                start = 1;
        #10     start = 0;

        #100 $display("case 5: (-4,0) (-1,-6) - negative coords");
                x0 = -9'sd4;  // left to right
                y0 = 9'sd0;
                x1 = -9'sd1;
                y1 = -9'sd6;
                start = 1;
        #10     start = 0;

        #100    x0 = -9'sd1;  // right to left
                y0 = -9'sd6;
                x1 = -9'sd4;
                y1 = 9'sd0;
                start = 1;
        #10     start = 0;

        #100 $display("case 6: (70,180) (180,50) - longer line");
                x0 = 9'sd70;
                y0 = 9'sd180;
                x1 = 9'sd180;
                y1 = 9'sd50;
                start = 1;
        #10     start = 0;

        #2000 $display("case 7: (0,0) (255,0) - horizontal");
                x0 = 9'sd0;
                y0 = 9'sd0;
                x1 = 9'sd255;
                y1 = 9'sd0;
                start = 1;
        #10     start = 0;

        #3000 $display("case 8: (0,0) (0,255) - vertical");
                x0 = 9'sd0;
                y0 = 9'sd0;
                x1 = 9'sd0;
                y1 = 9'sd255;
                start = 1;
        #10     start = 0;

        #3000 $display("case 9: (255,255) (0,0) - diagonal");
                x0 = 9'sd255;
                y0 = 9'sd255;
                x1 = 9'sd0;
                y1 = 9'sd0;
                start = 1;
        #10     start = 0;

        #4000   $finish;
    end
endmodule
