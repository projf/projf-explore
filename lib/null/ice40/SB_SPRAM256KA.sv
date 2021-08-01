// Project F Library - Null Module for iCE40 SB_SPRAM256KA
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// NB. For Verilator linting - don't include in synthesis

`default_nettype none
`timescale 1ns / 1ps

/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
module SB_SPRAM256KA  (
    input  wire logic [13:0] ADDRESS,
    input  wire logic [15:0] DATAIN,
    input  wire logic [3:0] MASKWREN,
    input  wire logic WREN,
    input  wire logic CHIPSELECT,
    input  wire logic CLOCK,
    input  wire logic STANDBY,
    input  wire logic SLEEP,
    input  wire logic POWEROFF,
    output      logic [15:0] DATAOUT
    );

    // NULL MODULE

endmodule
/* verilator lint_on UNDRIVEN */
/* verilator lint_on UNUSED */
