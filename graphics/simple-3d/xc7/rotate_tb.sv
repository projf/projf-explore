// Simple 3D - Rotate Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module rotate_tb ();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    logic rst;
    logic clk;

    localparam CORDW = 16;  // signed coordinate width
    localparam SF = 2.0**-8.0;  // Q8.8 scaling factor is 2^-8
    localparam ANGLEW = 8;  // 8-bit: 256 angles in 360°
    
    logic start, done;
    logic [1:0] axis;
    logic [ANGLEW-1:0] angle;
    logic signed [CORDW-1:0] x, y, z;
    logic signed [CORDW-1:0] xr, yr, zr;

    rotate #(
        .CORDW(CORDW),   // signed coordinate width
        .ANGLEW(ANGLEW)  // angle width
    ) rotate_inst (
        .clk,    // clock
        .rst,    // reset
        .start,  // start rotation
        .axis,   // axis (none=00, x=01, y=10, z=11)
        .angle,  // rotation angle
        .x,      // x coord in
        .y,      // y coord in
        .z,      // z coord in
        .xr,     // rotated x coord
        .yr,     // rotated y coord
        .zr,     // rotated z coord
        .done    // rotation complete (high for one tick)
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        clk = 1;
        rst = 1;
        // (1,0,0) in Q8.8
        x = 16'sh0100;
        y = 16'sh0000;
        z = 16'sh0000;
        axis = 2'b11;  // z-axis

        #100
        rst = 0;
        angle = 160;  // 45°
        start = 1;
        #10 start = 0;
        #90 $display("45°: (%f, %f, %f) -> (%f, %f, %f)", $itor(x)*SF, $itor(y)*SF, $itor(z)*SF, $itor(xr)*SF, $itor(yr)*SF, $itor(zr)*SF);

        #100
        angle = 96;  // -45°
        start = 1;
        #10 start = 0;
        #90 $display("-45°: (%f, %f, %f) -> (%f, %f, %f)", $itor(x)*SF, $itor(y)*SF, $itor(z)*SF, $itor(xr)*SF, $itor(yr)*SF, $itor(zr)*SF);

        #100
        angle = 192;  // +90°
        start = 1;
        #10 start = 0;
        #90 $display("+90°: (%f, %f, %f) -> (%f, %f, %f)", $itor(x)*SF, $itor(y)*SF, $itor(z)*SF, $itor(xr)*SF, $itor(yr)*SF, $itor(zr)*SF);

        #100
        angle = 0;  // +180°
        start = 1;
        #10 start = 0;
        #90 $display("+180°: (%f, %f, %f) -> (%f, %f, %f)", $itor(x)*SF, $itor(y)*SF, $itor(z)*SF, $itor(xr)*SF, $itor(yr)*SF, $itor(zr)*SF);

        #100
        angle = 64;  // -90° (+270°)
        start = 1;
        #10 start = 0;
        #90 $display("-90°: (%f, %f, %f) -> (%f, %f, %f)", $itor(x)*SF, $itor(y)*SF, $itor(z)*SF, $itor(xr)*SF, $itor(yr)*SF, $itor(zr)*SF);

        #100
        angle = 148;  // +28.125°
        start = 1;
        #10 start = 0;
        #90 $display("+28.125°: (%f, %f, %f) -> (%f, %f, %f)", $itor(x)*SF, $itor(y)*SF, $itor(z)*SF, $itor(xr)*SF, $itor(yr)*SF, $itor(zr)*SF);

        #100 $finish;
    end
endmodule

// Sine Table with 256 entries
//   0 = -180°
//  64 = - 90°
//  96 = - 45°
// 128 =    0°
// 160 = + 45°
// 192 = + 90°
//   0 = +180°
