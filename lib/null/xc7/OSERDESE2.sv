// Project F Library - Null Module for Xilinx 7 Series OSERDESE2
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// NB. For Verilator linting - don't include in synthesis

`default_nettype none
`timescale 1ns / 1ps

/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
module OSERDESE2 #(
    parameter SERDES_MODE,
    parameter DATA_WIDTH,
    parameter TRISTATE_WIDTH,
    parameter DATA_RATE_OQ,
    parameter DATA_RATE_TQ
    ) (
    input  wire logic CLK,
    input  wire logic CLKDIV,
    input  wire logic D1,
    input  wire logic D2,
    input  wire logic D3,
    input  wire logic D4,
    input  wire logic D5,
    input  wire logic D6,
    input  wire logic D7,
    input  wire logic D8,
    input  wire logic OCE,
    input  wire logic RST,
    input  wire logic SHIFTIN1,
    input  wire logic SHIFTIN2,
    input  wire logic T1,
    input  wire logic T2,
    input  wire logic T3,
    input  wire logic T4,
    input  wire logic TBYTEIN,
    input  wire logic TCE,
    output      logic OFB,
    output      logic OQ,
    output      logic SHIFTOUT1,
    output      logic SHIFTOUT2,
    output      logic TBYTEOUT,
    output      logic TFB,
    output      logic TQ
    );

    // NULL MODULE

endmodule
/* verilator lint_on UNDRIVEN */
/* verilator lint_on UNUSED */
