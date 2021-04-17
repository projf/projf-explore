// Project F: Null Module for Xilinx 7 Series MMCME2_BASE
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// NB. For Verilator linting - don't include in synthesis

`default_nettype none
`timescale 1ns / 1ps

/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
module MMCME2_BASE #(
    parameter CLKFBOUT_MULT_F,
    parameter CLKIN1_PERIOD,
    parameter CLKOUT0_DIVIDE_F,
    parameter CLKOUT1_DIVIDE,
    parameter DIVCLK_DIVIDE
    ) (
    input  wire logic CLKIN1,
    input  wire logic PWRDWN,
    input  wire logic RST,
    input  wire logic CLKFBIN,
    output      logic CLKOUT0,
    output      logic CLKOUT0B,
    output      logic CLKOUT1,
    output      logic CLKOUT1B,
    output      logic CLKOUT2,
    output      logic CLKOUT2B,
    output      logic CLKOUT3,
    output      logic CLKOUT3B,
    output      logic CLKOUT4,
    output      logic CLKOUT5,
    output      logic CLKOUT6,
    output      logic CLKFBOUT,
    output      logic CLKFBOUTB,
    output      logic LOCKED
    );

    // NULL MODULE

endmodule
/* verilator lint_on UNDRIVEN */
/* verilator lint_on UNUSED */
