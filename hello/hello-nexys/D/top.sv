// Project F: Hello Nexys D - Top
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic [3:0] sw,
    input wire logic btnc, btnd, btnl, btnr, btnu,
    output     logic [3:0] led
    );

    always_comb begin
        if (sw[0] == 0 && sw[1] == 1) begin
            led[3:0] = btnc ? 4'b1001 : 4'b0110;
        end else begin
            led[3:0] = 4'b0000;
        end
    end
endmodule
