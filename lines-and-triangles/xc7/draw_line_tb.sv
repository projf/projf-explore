// Project F: Lines and Triangles - Draw Line Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_line_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam CORDW = 8;
    logic [CORDW-1:0] x, y;
    logic [CORDW-1:0] x0, y0, x1, y1;
    logic start, oe, drawing, done;
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
                x0 = 8'd0;  // (0,0)
                y0 = 8'd0;
                x1 = 8'd0;
                y1 = 8'd0;
                start = 1;
        #10     start = 0;

        #100    x0 = 8'd32;  // (32,17)
                y0 = 8'd17;
                x1 = 8'd32;
                y1 = 8'd17;
                start = 1;
        #10     start = 0;

        #100    x0 = 8'd255;  // (255,255)
                y0 = 8'd255;
                x1 = 8'd255;
                y1 = 8'd255;
                start = 1;
        #10     start = 0;

        #100    $display("case 1: (0,1) (6,4) - not steep, down");
                x0 = 8'd0;  // left to right
                y0 = 8'd1;
                x1 = 8'd6;
                y1 = 8'd4;
                start = 1;
        #10     start = 0;

        #100    x0 = 8'd6;  // right to left
                y0 = 8'd4;
                x1 = 8'd0;
                y1 = 8'd1;
                start = 1;
        #10     start = 0;

        #100 $display("case 2: (1,0) (4,6) - steep, down");
                x0 = 8'd1;  // left to right
                y0 = 8'd0;
                x1 = 8'd4;
                y1 = 8'd6;
                start = 1;
        #10     start = 0;


        #100    x0 = 8'd4;  // right to left
                y0 = 8'd6;
                x1 = 8'd1;
                y1 = 8'd0;
                start = 1;
        #10     start = 0;


        #100 $display("case 3: (0,4) (6,1) - not steep, up");
                x0 = 8'd0;  // left to right
                y0 = 8'd4;
                x1 = 8'd6;
                y1 = 8'd1;
                start = 1;
        #10     start = 0;

        #100    x0 = 8'd6;  // right to left
                y0 = 8'd1;
                x1 = 8'd0;
                y1 = 8'd4;
                start = 1;
        #10     start = 0;


        #100 $display("case 4: (4,0) (1,6) - steep, up");
                x0 = 8'd4;  // left to right
                y0 = 8'd0;
                x1 = 8'd1;
                y1 = 8'd6;
                start = 1;
        #10     start = 0;

        #100    x0 = 8'd1;  // right to left
                y0 = 8'd6;
                x1 = 8'd4;
                y1 = 8'd0;
                start = 1;
        #10     start = 0;

        #100 $display("case 5: (70,180) (180,50) - longer line");
                x0 = 8'd70;
                y0 = 8'd180;
                x1 = 8'd180;
                y1 = 8'd50;
                start = 1;
        #10     start = 0;

        #2000 $display("case 6: (0,0) (255,0) - horizontal");
                x0 = 8'd0;
                y0 = 8'd0;
                x1 = 8'd255;
                y1 = 8'd0;
                start = 1;
        #10     start = 0;

        #3000 $display("case 7: (0,0) (0,255) - vertical");
                x0 = 8'd0;
                y0 = 8'd0;
                x1 = 8'd0;
                y1 = 8'd255;
                start = 1;
        #10     start = 0;

        #3000 $display("case 8: (255,255) (0,0) - diagonal");
                x0 = 8'd255;
                y0 = 8'd255;
                x1 = 8'd0;
                y1 = 8'd0;
                start = 1;
        #10     start = 0;

        #4000   $finish;
    end
endmodule
