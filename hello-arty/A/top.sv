// Project F: Hello Arty A - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-1/

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic sw,
    output     logic led
    );

    always_comb begin
        led = sw;
    end
endmodule
