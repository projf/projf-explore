// Project F Library - Galois Linear-Feedback Shift Register
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// NB. Ensure reset is asserted for one or more cycles before enable

module lfsr #(
    parameter LEN=8,                   // shift register length
    parameter TAPS=8'b10111000         // XOR taps
    ) (
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic en,              // enable
    input  wire logic [LEN-1:0] seed,  // seed (uses default seed if zero)
    output      logic [LEN-1:0] sreg   // lfsr output
    );

    always_ff @(posedge clk) begin
        if (en)  sreg <= {1'b0, sreg[LEN-1:1]} ^ (sreg[0] ? TAPS : {LEN{1'b0}});
        if (rst) sreg <= (seed != 0) ? seed : {LEN{1'b1}};
    end
endmodule
