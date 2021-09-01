// Project F Library - Draw Filled Triangle Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_triangle_fill_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 9;  // -256 to +255
    logic signed [CORDW-1:0] x, y;
    logic signed [CORDW-1:0] x0, y0, x1, y1, x2, y2;;
    logic start, oe, drawing, busy, done;
    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk,
        .rst,
        .start,
        .oe,
        .x0,
        .y0,
        .x1,
        .y1,
        .x2,
        .y2,
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

        #10     $display("case 1a: small (2,2) (6,2) (4,6)");
                x0 = 9'sd2; y0 = 9'sd2;
                x1 = 9'sd6; y1 = 9'sd2;
                x2 = 9'sd4; y2 = 9'sd6;
                start = 1;
        #10     start = 0;

        #820    $display("case 1b: small (4,6) (6,2) (2,2)");
                x0 = 9'sd4; y0 = 9'sd6;
                x1 = 9'sd6; y1 = 9'sd2;
                x2 = 9'sd2; y2 = 9'sd2;
                start = 1;
        #10     start = 0;

        #990    $display("case 2: (-2,2) (-6,-2) (-4,6)");
                x0 = -9'sd2; y0 =  9'sd2;
                x1 = -9'sd6; y1 = -9'sd2;
                x2 = -9'sd4; y2 =  9'sd6;
                start = 1;
        #10     start = 0;

        #990    $display("case 3a: (13,9) (9,15) (13,19)");
                x0 = 9'sd13; y0 =  9'sd9;
                x1 =  9'sd9; y1 = 9'sd15;
                x2 = 9'sd13; y2 = 9'sd19;
                start = 1;
        #10     start = 0;

        #1990   $display("case 3b: (9,5) (13,9) (9,15)");
                x0 =  9'sd9; y0 =  9'sd5;
                x1 = 9'sd13; y1 =  9'sd9;
                x2 =  9'sd9; y2 = 9'sd15;
                start = 1;
        #10     start = 0;

        #1990   $display("case 3c: (19,5) (13,9) (23,9)");
                x0 = 9'sd19; y0 = 9'sd5;
                x1 = 9'sd13; y1 = 9'sd9;
                x2 = 9'sd23; y2 = 9'sd9;
                start = 1;
        #10     start = 0;

        #1990   $display("case 4a: (8,1) (7,7) (1,8)");
                x0 = 9'sd8; y0 = 9'sd1;
                x1 = 9'sd7; y1 = 9'sd7;
                x2 = 9'sd1; y2 = 9'sd8;
                start = 1;
        #10     start = 0;

        #990    $display("case 4b: (1,1) (2,7) (8,8)");
                x0 = 9'sd1; y0 = 9'sd1;
                x1 = 9'sd2; y1 = 9'sd7;
                x2 = 9'sd8; y2 = 9'sd8;
                start = 1;
        #10     start = 0;

        #990    $display("case 5a: (1,3) (6,2) (3,4)");
                x0 = 9'sd1; y0 = 9'sd3;
                x1 = 9'sd6; y1 = 9'sd2;
                x2 = 9'sd3; y2 = 9'sd4;
                start = 1;
        #10     start = 0;

        #990    $display("case 5b: (1,2) (6,3) (3,4)");
                x0 = 9'sd1; y0 = 9'sd2;
                x1 = 9'sd6; y1 = 9'sd3;
                x2 = 9'sd3; y2 = 9'sd4;
                start = 1;
        #10     start = 0;

        #1990 $finish;
    end
endmodule
