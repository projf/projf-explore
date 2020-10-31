// Project F: Null Module for Xilinx 7 Series BUFG
// (C)2020 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// NB. For Verilator linting - don't include in synthesis

`default_nettype none
`timescale 1ns / 1ps

module BUFG (
    /* verilator lint_off UNUSED */
    /* verilator lint_off UNDRIVEN */
    input  wire logic I,
    output      logic O
    /* verilator lint_on UNDRIVEN */
    /* verilator lint_on UNUSED */
    );

    // NULL MODULE

endmodule
