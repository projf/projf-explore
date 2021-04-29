// Simple 3D - Sine Table Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sine_table_tb ();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;
    logic clk;

    localparam SF = 2.0**-8.0;  // Q8.8 scaling factor is 2^-8

    localparam CORDW=16;      // signed number width
    localparam ROM_DEPTH=64;  // entires in sine ROM 0°-90°
    localparam ROM_WIDTH=8;   // width of sine ROM data
    localparam ROM_FILE="sine_table_64x8.mem";  // file to populate ROM
    localparam ADDRW=$clog2(4*ROM_DEPTH);  // full table -180° to +180°

    logic start;  // start lookup
    logic [ADDRW-1:0] id;  // table ID to lookup
    logic signed [2*ROM_WIDTH-1:0] data; // answer
    logic done;  // lookup complete (high for one tick)

    sine_table #(
        .CORDW(CORDW),
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE(ROM_FILE)
    ) sine_table_inst (
        .clk,
        .rst,
        .start,
        .id,
        .data,
        .done
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        rst = 1;
        clk = 1;

        #100 rst = 0;

        #20 id =   0; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id =   1; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id =  32; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id =  63; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id =  64; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id =  65; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 100; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 127; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 128; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 129; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 148; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 191; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 192; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 193; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 226; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #20 id = 255; start = 1;
        #10 start = 0;
        #20 $display("%d = %f", id, $itor(data)*SF);

        #50 $finish();
    end
endmodule
