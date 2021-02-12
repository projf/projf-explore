// Project F: Hello Arty G - Top
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    output     logic [3:0] led
    );

    localparam DIV_BY = 27'd100_000_000;

    logic stb;
    logic [26:0] cnt = 0;
    always_ff @(posedge clk) begin
        if (cnt != DIV_BY-1) begin
            stb <= 0;
            cnt <= cnt + 1;
        end else begin
            stb <= 1;
            cnt <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if (stb) led <= led + 1;
    end
endmodule
