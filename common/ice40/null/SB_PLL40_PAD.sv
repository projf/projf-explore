// Project F: Null Module for iCE40 SB_PLL40_PAD
// (C)2020 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// NB. For Verilator linting - don't include in synthesis

`default_nettype none
`timescale 1ns / 1ps

module SB_PLL40_PAD #(
    parameter FEEDBACK_PATH,
    parameter DIVR,
    parameter DIVF,
    parameter DIVQ,
    parameter FILTER_RANGE
    ) (
    /* verilator lint_off UNUSED */
    /* verilator lint_off UNDRIVEN */
    input  wire logic PACKAGEPIN,
    input  wire logic RESETB,
    input  wire logic BYPASS,
    output      logic PLLOUTGLOBAL,
    output      logic LOCK
    );
    /* verilator lint_on UNDRIVEN */
    /* verilator lint_on UNUSED */

    // NULL MODULE

endmodule
