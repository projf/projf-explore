// Project F: Hello Arty C - Top
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic [1:0] sw,
    output     logic [3:0] led
    );
  
    always_comb begin
        led[1:0] = sw[0] ? 2'b11 : 2'b00;
        led[3:2] = sw[1] ? 2'b11 : 2'b00;
    end
endmodule
