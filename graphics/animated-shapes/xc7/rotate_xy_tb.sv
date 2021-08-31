// Project F: Animated Shapes - Rotate XY Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module rotate_xy_tb ();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    logic rst;
    logic clk;

    localparam CORDW = 16;  // signed coordinate width
    localparam ANGLEW = 8;  // 8-bit: 256 angles in 360°

    logic start, done;
    logic [ANGLEW-1:0] angle;
    logic signed [CORDW-1:0] xi, yi;
    logic signed [CORDW-1:0] x, y;

    rotate_xy #(
        .CORDW(CORDW),   // signed coordinate width
        .ANGLEW(ANGLEW)  // angle width
    ) rotate_inst (
        .clk,    // clock
        .rst,    // reset
        .start,  // start rotation
        .angle,  // rotation angle
        .xi,     // x coord in
        .yi,     // y coord in
        .x,      // rotated x coord
        .y,      // rotated y coord
        .done    // rotation complete (high for one tick)
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        clk = 1;
        rst = 1;

        #100
        $display("Coordinate 1: (60,0)");
        xi = 16'sd60;
        yi = 16'sd0;
        rst = 0;

        #100
        angle = 0;  // 0°
        start = 1;
        #10 start = 0;
        #90 $display("0°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 32;  // +45°
        start = 1;
        #10 start = 0;
        #90 $display("+45°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 224;  // -45°
        start = 1;
        #10 start = 0;
        #90 $display("-45°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 64;  // +90°
        start = 1;
        #10 start = 0;
        #90 $display("+90°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 128;  // +180°
        start = 1;
        #10 start = 0;
        #90 $display("+180°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 192;  // -90° (+270°)
        start = 1;
        #10 start = 0;
        #90 $display("-90°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 20;  // +28.125°
        start = 1;
        #10 start = 0;
        #90 $display("+28.125°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        $display("Coordinate 2: (60,30)");
        xi = 16'sd60;
        yi = 16'sd30;
        rst = 0;

        #100
        angle = 0;  // 0°
        start = 1;
        #10 start = 0;
        #90 $display("0°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 32;  // +45°
        start = 1;
        #10 start = 0;
        #90 $display("+45°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 224;  // -45°
        start = 1;
        #10 start = 0;
        #90 $display("-45°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 64;  // +90°
        start = 1;
        #10 start = 0;
        #90 $display("+90°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 128;  // +180°
        start = 1;
        #10 start = 0;
        #90 $display("+180°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 192;  // -90° (+270°)
        start = 1;
        #10 start = 0;
        #90 $display("-90°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 20;  // +28.125°
        start = 1;
        #10 start = 0;
        #90 $display("+28.125°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        $display("Coordinate 3: (-1,32000)");
        xi = 16'shFFFF;
        yi = 16'sh7D00;

        #100
        angle = 0;  // 0°
        start = 1;
        #10 start = 0;
        #90 $display("0°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 32;  // +45°
        start = 1;
        #10 start = 0;
        #90 $display("+45°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 224;  // -45°
        start = 1;
        #10 start = 0;
        #90 $display("-45°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 64;  // +90°
        start = 1;
        #10 start = 0;
        #90 $display("+90°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 128;  // +180°
        start = 1;
        #10 start = 0;
        #90 $display("+180°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 192;  // -90° (+270°)
        start = 1;
        #10 start = 0;
        #90 $display("-90°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100
        angle = 20;  // +28.125°
        start = 1;
        #10 start = 0;
        #90 $display("+28.125°: (%d, %d) -> (%d, %d)", xi, yi, x, y);

        #100 $finish;
    end
endmodule

// Sine Table with 256 entries
//   0 =    0°
//  20 = + 28.125°
//  32 = + 45°
//  64 = + 90°
//  96 = +135°
// 128 = +180°
// 192 = +270° (- 90°)
// 224 = +315° (- 45°)
