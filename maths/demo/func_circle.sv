// Project F: Maths Demo - Function: Circle
// (C)2023 Will Green, open source hardware released under the MIT License
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

    // // v1: simple version (latency: 2 cycles)
    // logic signed [2*CORDW:0] circle;  // addition of two squares, so twice as wide
    // always_ff @(posedge clk) begin
    //     circle <= x*x + y*y;
    //     r <= (circle < RADIUS * RADIUS) ? 1 : 0;
    // end

    // v2: extra pipeline stages (latency: 4 cycles)
    logic [2*CORDW-1:0] x_squared, x_squared_p1;
    logic [2*CORDW-1:0] y_squared, y_squared_p1;
    logic signed [2*CORDW:0] circle;  // addition of two squares, so twice as wide
    always_ff @(posedge clk) begin
        x_squared_p1 <= x*x;
        x_squared <= x_squared_p1;

        y_squared_p1 <= y*y;
        y_squared <= y_squared_p1;

        circle <= x_squared + y_squared;
        r <= (circle < RADIUS * RADIUS) ? 1 : 0;
    end
endmodule
