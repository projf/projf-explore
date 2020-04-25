// Project F: Hello Arty 1C - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-1/

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    input wire logic [3:0] sw,
    input wire logic [3:0] btn,
    output     logic [3:0] led
    );
    
    always_ff @(posedge clk) begin
        if(sw[0] == 0) begin
            led[3:0] <= 4'b0000;
        end else begin
            if (btn[0] == 0) begin
                led[3:0] <= 4'b0110;
            end else begin
                led[3:0] <= 4'b1001;
            end
        end
    end
endmodule
