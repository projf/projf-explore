// Project F: Hello Nexys G - Top
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    output     logic [3:0] led
    );

    localparam DIV_BY = 27'd100_000_000 - 27'd1;

    logic stb;
    logic [26:0] cnt = 0;
    always_ff @(posedge clk) begin
        cnt <= (cnt < DIV_BY) ? cnt + 1 : 0;
        stb <= (cnt == DIV_BY) ? 1 : 0;
    end

    always_ff @(posedge clk) begin
        if (stb) led <= led + 1;
    end
endmodule

