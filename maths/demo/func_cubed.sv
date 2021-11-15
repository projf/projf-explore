// Project F: Maths Demo - Function: Cubed
// (C)2021 Will Green, open source hardware released under the MIT License
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

    logic signed [3*CORDW-1:0] x_cubed, y_scaled;
    always_ff @(posedge clk) begin
        x_cubed <= x*x*x;
        y_scaled <= Y_SCALE*y;
        r <= (x_cubed < y_scaled) ? 1 : 0;
    end
endmodule
