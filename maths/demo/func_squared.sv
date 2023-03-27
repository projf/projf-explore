// Project F: Maths Demo - Function: Squared
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module func_squared #(
    CORDW=8,     // signed coordinate width (bits)
    Y_SCALE=256  // increase y-scale so we can see more on-screen
    ) (
    input  wire clk,
    input  wire signed [CORDW-1:0] x,
    input  wire signed [CORDW-1:0] y,
    output logic r
    );

    // // v1: simple version (latency: 2 cycles)
    // logic signed [2*CORDW-1:0] x_squared;
    // logic signed [2*CORDW-1:0] y_scaled;
    // always_ff @(posedge clk) begin
    //     y_scaled <= Y_SCALE * y;
    //     x_squared <= x*x;
    //     r <= (x_squared < y_scaled) ? 1 : 0;
    // end

    // v2: extra pipeline stages (latency: 3 cycles)
    logic signed [2*CORDW-1:0] x_squared, x_squared_p1;
    logic signed [2*CORDW-1:0] y_scaled, y_scaled_p1;
    always_ff @(posedge clk) begin
        y_scaled_p1 <= Y_SCALE * y;
        y_scaled    <= y_scaled_p1;

        x_squared_p1 <= x*x;
        x_squared <= x_squared_p1;

        r <= (x_squared < y_scaled) ? 1 : 0;
    end
endmodule
