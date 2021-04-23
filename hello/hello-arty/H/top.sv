// Project F: Hello Arty H - Top
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    output     logic [3:0] led
    );

    logic [7:0] cnt = 0;
    logic [7:0] duty = 8'd5;

    always_ff @(posedge clk) begin
        cnt <= cnt + 1;
        led[3:0] <= (cnt < duty) ? 4'b1111 : 4'b0000;
    end
endmodule
