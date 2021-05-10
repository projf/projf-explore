// Simple 3D - Rotation Test Bench
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module rotation_tb ();
    localparam CORDW = 16;
    localparam SF = 2.0**-8.0;  // Q8.8 scaling factor is 2^-8
    
    logic signed [CORDW-1:0] x0, y0, x1, y1;
    logic signed [2*CORDW-1:0] sin_x0_w, sin_y0_w, cos_x0_w, cos_y0_w;
    logic signed [CORDW-1:0] sin_x0, sin_y0, cos_x0, cos_y0;
    logic signed [CORDW-1:0] sin, cos;

    always_comb begin
        // rotation components
        sin_x0_w = x0 * sin;
        sin_y0_w = y0 * sin;
        cos_x0_w = x0 * cos;
        cos_y0_w = y0 * cos;

        // adjust for fixed-point multiplication (take middle 16 bits)
        sin_x0 = sin_x0_w[23:8];
        sin_y0 = sin_y0_w[23:8];
        cos_x0 = cos_x0_w[23:8];
        cos_y0 = cos_y0_w[23:8];

        // new coordinates
        x1 = cos_x0 - sin_y0;
        y1 = cos_y0 + sin_x0; 
    end

    initial begin
        // (1,0) in Q8.8
        x0 = 16'sh0100;
        y0 = 16'sh0000;

        #80  // 45°
        sin = 16'sh00B4;
        cos = 16'sh00B4;
        #20 $display("45°: (%f, %f) -> (%f, %f)", $itor(x0)*SF, $itor(y0)*SF, $itor(x1)*SF, $itor(y1)*SF);

        #80  // 90°
        sin = 16'sh00FF;
        cos = 16'sh0000;
        #20 $display("90°: (%f, %f) -> (%f, %f)", $itor(x0)*SF, $itor(y0)*SF, $itor(x1)*SF, $itor(y1)*SF);


        #80  // 30°
        sin = 16'sh007F;
        cos = 16'sh00DE;
        #20 $display("30°: (%f, %f) -> (%f, %f)", $itor(x0)*SF, $itor(y0)*SF, $itor(x1)*SF, $itor(y1)*SF);

        #80  // 10°
        sin = 16'sh002C;
        cos = 16'sh00FC;
        #20 $display("10°: (%f, %f) -> (%f, %f)", $itor(x0)*SF, $itor(y0)*SF, $itor(x1)*SF, $itor(y1)*SF);

        #80  // -10°
        sin = 16'shFFD4;
        cos = 16'sh00FC;
        #20 $display("-10°: (%f, %f) -> (%f, %f)", $itor(x0)*SF, $itor(y0)*SF, $itor(x1)*SF, $itor(y1)*SF);

        #100   $finish;
    end
endmodule

// quadrants
// -180° to  - 90°   Sin: -  Cos: -
// - 90° to     0°   Sin: -  Cos: +
//    0° to    90°   Sin: +  Cos: +
//   90° to   180°   Sin: +  Cos: -
