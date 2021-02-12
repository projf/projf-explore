// Project F: Hello Nexys E - Top
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    output     logic [3:0] led
    );

    logic [31:0] cnt = 0;  // 32-bit counter

    always_ff @(posedge clk) begin
        cnt <= cnt + 1;
        led[0] <= cnt[26];
    end
endmodule
