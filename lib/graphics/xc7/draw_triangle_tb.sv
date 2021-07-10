// Project F Library - Draw Triangle Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_triangle_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 9;  // -256 to +255
    logic signed [CORDW-1:0] x, y;
    logic signed [CORDW-1:0] x0, y0, x1, y1, x2, y2;;
    logic start, oe, drawing, complete, done;
    draw_triangle #(.CORDW(CORDW)) draw_triangle_inst (
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
        .complete,
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
                x0 = 9'sd2;
                y0 = 9'sd2;
                x1 = 9'sd6;
                y1 = 9'sd2;
                x2 = 9'sd4;
                y2 = 9'sd6;
                start = 1;
        #10     start = 0;

        #400    $display("case 1b: small (4,6) (6,2) (2,2)");
                x0 = 9'sd4;
                y0 = 9'sd6;
                x1 = 9'sd6;
                y1 = 9'sd2;
                x2 = 9'sd2;
                y2 = 9'sd2;
                start = 1;
        #10     start = 0;

        #400   $display("case 2: negative (-2,2) (-6,-2) (-4,6)");
                x0 = -9'sd2;
                y0 = 9'sd2;
                x1 = -9'sd6;
                y1 = -9'sd2;
                x2 = -9'sd4;
                y2 = 9'sd6;
                start = 1;
        #10     start = 0;

        #400    $display("case 3: right-angle (10,10) (10,40) (60,40)");
                x0 = 9'sd10;
                y0 = 9'sd10;
                x1 = 9'sd10;
                y1 = 9'sd40;
                x2 = 9'sd60;
                y2 = 9'sd40;
                start = 1;
        #10     start = 0;

        #2000  $display("case 4: obtuse (10,10) (20,40) (60,40)");
                x0 = 9'sd10;
                y0 = 9'sd10;
                x1 = 9'sd20;
                y1 = 9'sd40;
                x2 = 9'sd60;
                y2 = 9'sd40;
                start = 1;
        #10     start = 0;

        #2000   $display("case 5: acute (30,10) (10,40) (60,40)");
                x0 = 9'sd30;
                y0 = 9'sd10;
                x1 = 9'sd10;
                y1 = 9'sd40;
                x2 = 9'sd60;
                y2 = 9'sd40;
                start = 1;
        #10     start = 0;

        #2000   $finish;
    end
endmodule
