// Project F: Hello Arty B - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-1/

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic [1:0] sw,
    output     logic [3:0] led
    );
  
    always_comb begin
        if (sw[0]) begin
            led[1:0] = 2'b11;
        end else begin
            led[1:0] = 2'b00;
        end

        if (sw[1]) begin
            led[3:2] = 2'b11;
        end else begin
            led[3:2] = 2'b00;
        end
    end
endmodule