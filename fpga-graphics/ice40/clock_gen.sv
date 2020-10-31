// Project F: FPGA Graphics - Clock Generation (iCE40)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none

// Default to 25.125 MHz (640x480 59.8 Hz) with 12 MHz XO
// iCE40 PLLs are documented in Lattice TN1251

module clock_gen #(
    parameter FEEDBACK_PATH="SIMPLE",
    parameter DIVR=4'b0000,
    parameter DIVF=7'b1000010,
    parameter DIVQ=3'b101,
    parameter FILTER_RANGE=3'b001
    ) (
    input  wire logic clk,        // board oscillator
    input  wire logic rst,        // reset
    output      logic clk_pix,    // pixel clock
    output      logic clk_locked  // generated clock locked?
    );

    SB_PLL40_PAD #(
        .FEEDBACK_PATH(FEEDBACK_PATH),
        .DIVR(DIVR),
        .DIVF(DIVF),
        .DIVQ(DIVQ),
        .FILTER_RANGE(FILTER_RANGE)
    ) SB_PLL40_PAD_inst (
        .PACKAGEPIN(clk),
        .PLLOUTCORE(clk_pix),
        .RESETB(rst),
        .BYPASS(1'b0),
        .LOCK(clk_locked)
    );
endmodule
