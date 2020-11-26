// Project F: Null Module for iCE40 SB_IO
// (C)2020 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// NB. For Verilator linting - don't include in synthesis

`default_nettype none
`timescale 1ns / 1ps

module SB_IO #(
    parameter PIN_TYPE
    ) (
    /* verilator lint_off UNUSED */
    /* verilator lint_off UNDRIVEN */
    output      logic PACKAGE_PIN,
    input  wire logic OUTPUT_CLK,
    input  wire logic D_OUT_0,
    input  wire logic D_OUT_1
    );
    /* verilator lint_on UNDRIVEN */
    /* verilator lint_on UNUSED */

    // NULL MODULE

endmodule
