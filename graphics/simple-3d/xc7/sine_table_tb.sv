// Simple 3D - Sine Table Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sine_table_tb ();
    localparam SF = 2.0**-8.0;  // Q8.8 scaling factor is 2^-8
    localparam ROM_DEPTH=64;    // entires in sine ROM 0°-90°
    localparam ROM_WIDTH=8;     // width of sine ROM data
    localparam ROM_FILE="sine_table_64x8.mem";  // file to populate ROM
    localparam ADDRW=$clog2(4*ROM_DEPTH);  // full table -180° to +180°

    logic [ADDRW-1:0] id;  // table ID to lookup
    logic signed [2*ROM_WIDTH-1:0] data; // answer
    sine_table #(
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE(ROM_FILE)
    ) sine_table_inst (
        .id,
        .data
    );

    initial begin
        #100 id =   0;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id =   1;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id =  32;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id =  63;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id =  64;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id =  65;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 100;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 127;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 128;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 129;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 148;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 191;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 192;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 193;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 226;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #10 id = 255;
        #10 $display("%d = %f", id, $itor(data)*SF);

        #50 $finish();
    end
endmodule
