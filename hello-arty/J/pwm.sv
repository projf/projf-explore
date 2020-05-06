// Project F: Hello Arty J - Pulse Width Modulation
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-2/

`default_nettype none
`timescale 1ns / 1ps

module pwm (
    input wire logic clk,
    input wire logic [7:0] duty,
    output     logic pwm_out
    );

    logic [7:0] cnt = 8'b0;
    always_ff @(posedge clk) begin
        cnt <= cnt + 1;
    end

    always_comb begin
        pwm_out = (cnt < duty);
    end
endmodule
