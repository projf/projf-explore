// Project F: Hello Arty E - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-2/

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
