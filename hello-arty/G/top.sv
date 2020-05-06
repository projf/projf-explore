// Project F: Hello Arty G - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-2/

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    output     logic [3:0] led
    );

    logic stb;
    logic [39:0] cnt;
    always_ff @(posedge clk) {stb, cnt} <= cnt + 40'd10995;

    always_ff @(posedge clk) begin
        if (stb) led <= led + 1;
    end
endmodule
