// Project F: Maths Demo - Function: Squared
// (C)2021 Will Green, open source hardware released under the MIT License
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

    logic signed [2*CORDW-1:0] x_squared, y_scaled;
    always_ff @(posedge clk) begin
        x_squared <= x*x;
        y_scaled <= Y_SCALE*y;
        r <= (x_squared < y_scaled) ? 1 : 0;
    end
endmodule
