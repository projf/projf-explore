// Project F: Maths Demo - Function: x⁴−x²
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module func_polynomial #(
    CORDW=8,       // signed coordinate width (bits)
    Y_SCALE=2**24  // increase y-scale so we can see more on-screen
    ) (
    input  wire clk,
    input  wire signed [CORDW-1:0] x,
    input  wire signed [CORDW-1:0] y,
    output logic r
    );

    // // v1: simple version (latency: 2 cycles)
    // logic signed [4*CORDW-1:0] x_poly, y_scaled;
    // always_ff @(posedge clk) begin
    //     y_scaled <= Y_SCALE * y;
    //     x_poly <= x*x*x*x - 2**16 * x*x;
    //     r <= (x_poly < y_scaled) ? 1 : 0;
    // end

    // v2: extra pipeline stages (latency: 6 cycles)
    logic signed [2*CORDW-1:0] x_squared, x_squared_p1, x_squared_p2, x_squared_p3;
    logic signed [4*CORDW-1:0] x_fourth, x_fourth_p1, x_poly;
    logic signed [4*CORDW-1:0] y_scaled, y_scaled_p1, y_scaled_p2, y_scaled_p3, y_scaled_p4;
    always_ff @(posedge clk) begin
        y_scaled_p4 <= Y_SCALE * y;
        y_scaled_p3 <= y_scaled_p4;
        y_scaled_p2 <= y_scaled_p3;
        y_scaled_p1 <= y_scaled_p2;
        y_scaled    <= y_scaled_p1;

        x_squared_p3 <= x*x;
        x_squared_p2 <= x_squared_p3;
        x_squared_p1 <= x_squared_p2;
        x_squared    <= x_squared_p1;

        x_fourth_p1 <= x_squared_p2 * x_squared_p2;
        x_fourth    <= x_fourth_p1;

        x_poly <= x_fourth - 2**16 * x_squared;
        r <= (x_poly < y_scaled) ? 1 : 0;
    end
endmodule
