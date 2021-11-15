// Project F: Maths Demo - Function: Circle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module func_circle #(
    CORDW=8,    // signed coordinate width (bits)
    RADIUS=128  // circle radius
    ) (
    input  wire clk,
    input  wire signed [CORDW-1:0] x,
    input  wire signed [CORDW-1:0] y,
    output logic r
    );

    logic signed [2*CORDW:0] circle;  // two squares, so twice as wide
    always_ff @(posedge clk) begin
        circle <= x*x + y*y;
        r <= (circle < RADIUS * RADIUS) ? 1 : 0;
    end
endmodule
