// Project F: Maths Demo - Function: Cubed
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module func_cubed #(
    CORDW=8,       // signed coordinate width (bits)
    Y_SCALE=16384  // increase y-scale so we can see more on-screen
    ) (
    input  wire clk,
    input  wire signed [CORDW-1:0] x,
    input  wire signed [CORDW-1:0] y,
    output logic r
    );

    // // v1: simple version (latency: 2 cycles)
    // logic signed [3*CORDW-1:0] x_cubed, y_scaled;
    // always_ff @(posedge clk) begin
    //     y_scaled <= Y_SCALE * y;
    //     x_cubed <= x*x*x;
    //     r <= (x_cubed < y_scaled) ? 1 : 0;
    // end

    // v2: extra pipeline stages (latency: 5 cycles)
    logic signed [2*CORDW-1:0] x_squared, x_squared_p1;
    logic signed [3*CORDW-1:0] x_cubed_p1, x_cubed;
    logic signed [3*CORDW-1:0] y_scaled, y_scaled_p1, y_scaled_p2, y_scaled_p3;
    always_ff @(posedge clk) begin
        y_scaled_p3 <= Y_SCALE * y;
        y_scaled_p2 <= y_scaled_p3;
        y_scaled_p1 <= y_scaled_p2;
        y_scaled    <= y_scaled_p1;

        x_squared_p1 <= x*x;
        x_squared    <= x_squared_p1;
        x_cubed_p1   <= x*x_squared;
        x_cubed      <= x_cubed_p1;

        r <= (x_cubed < y_scaled) ? 1 : 0;
    end
endmodule
