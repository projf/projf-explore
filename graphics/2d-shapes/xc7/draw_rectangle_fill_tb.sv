// Project F: 2D Shapes - Draw Filled Rectangle Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_rectangle_fill_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 8;
    logic [CORDW-1:0] x, y;
    logic [CORDW-1:0] x0, y0, x1, y1;
    logic start, oe, drawing, done;
    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_fill_inst (
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

        #10     $display("case 1: (10,8) -> (20,15)");
                x0 = 8'd10;
                y0 = 8'd08;
                x1 = 8'd20;
                y1 = 8'd15;
                start = 1;
        #10     start = 0;

        #1500   $display("case 2: (20,15) -> (10,8)");
                x0 = 8'd10;
                y0 = 8'd08;
                x1 = 8'd20;
                y1 = 8'd15;
                start = 1;
        #10     start = 0;

        #1500   $finish;
    end
endmodule
