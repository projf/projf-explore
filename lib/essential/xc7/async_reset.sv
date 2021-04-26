// Project F Library - Async Reset
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module async_reset (
    input  wire logic clk,      // clock
    input  wire logic rst_in,   // reset
    output      logic rst_out   // output reset
    );

    (* ASYNC_REG = "TRUE" *) logic [1:0] rst_shf;  // reset shift reg

    initial rst_out = 1'b1;     // start off with reset asserted
    initial rst_shf = 2'b11;    //  and reset shift reg populated

    always_ff @(posedge clk or posedge rst_in) begin
        /* verilator lint_off SYNCASYNCNET */
        if (rst_in) {rst_out, rst_shf} <= 3'b111;
        else {rst_out, rst_shf} <= {rst_shf, 1'b0};
        /* verilator lint_on SYNCASYNCNET */
    end

endmodule
