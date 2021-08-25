// Project F Library - Draw 1D Line Test Bench (assumes x1 >= x0)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_line_1d_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 9;  // -256 to +255
    logic signed [CORDW-1:0] x;
    logic signed [CORDW-1:0] x0, x1;
    logic start, oe, drawing, busy, done;
    draw_line_1d #(.CORDW(CORDW)) draw_line_1d_inst (
        .clk,
        .rst,
        .start,
        .oe,
        .x0,
        .x1,
        .x,
        .drawing,
        .busy,
        .done
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\t(%d) >%b Done=%b", $time, x, drawing, done);
    end

    initial begin
        rst = 1;
        clk = 1;
        #100    rst = 0;
                oe = 1;

        #10     $display("case 0: points (0) (32) (255)");
                x0 = 9'sd0;  // (0)
                x1 = 9'sd0;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd32;  // (32)
                x1 = 9'sd32;
                start = 1;
        #10     start = 0;

        #100    x0 = 9'sd255;  // (255)
                x1 = 9'sd255;
                start = 1;
        #10     start = 0;

        #100    $display("case 1: (0) (6) - small, positive coords");
                x0 = 9'sd0;
                x1 = 9'sd6;
                start = 1;
        #10     start = 0;

        #100 $display("case 2: (-6) (-1) - small, negative coords");
                x0 = -9'sd6;
                x1 = -9'sd1;
                start = 1;
        #10     start = 0;

        #100 $display("case 3: (-6) (9) - small, cross zero");
                x0 = -9'sd6;
                x1 =  9'sd9;
                start = 1;
        #10     start = 0;

        #200 $display("case 4: (-256) (-254) - minimum");
                x0 = -9'sd256;
                x1 = -9'sd254;
                start = 1;
        #10     start = 0;

        #100 $display("case 5: (0) (255) - long");
                x0 = 9'sd0;
                x1 = 9'sd255;
                start = 1;
        #10     start = 0;

        #4000   $finish;
    end
endmodule
