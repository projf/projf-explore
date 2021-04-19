// Project F: Life on Screen - Life Sim Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module new_life_tb();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    
    localparam CORDW  = 16;  // signed coordinate width
    localparam WIDTH  = 6;  // world width in cells
    localparam HEIGHT = 6;  // world height in cells
    localparam F_INIT = "test_toad.mem";  // initial world state

    logic rst;
    logic clk_100m;

    logic start;
    logic ready, alive, changed;
    logic signed [CORDW-1:0] x, y;
    logic running, done;

    new_life #(
        .CORDW(CORDW),   
        .WIDTH(WIDTH),   
        .HEIGHT(HEIGHT),  
        .F_INIT(F_INIT)
    ) new_life_inst (
        .clk(clk_100m),  // clock
        .rst,            // reset
        .start,          // start sim generation
        .ready,          // cell state ready to be read
        .alive,          // is the cell alive? (when ready)
        .changed,        // cell's state changed (when ready)
        .x,              // horizontal cell position
        .y,              // vertical cell position
        .running,        // sim is running
        .done            // sim complete (high for one tick)
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        clk_100m = 1;

        start = 0;

        #100 rst = 0;

        #100 start = 1;
        #10  start = 0;

        #3500 start = 1;
        #10  start = 0;

        #3500 start = 1;
        #10  start = 0;

        #3500 start = 1;
        #10  start = 0;

        #3500 $finish;
    end
endmodule
