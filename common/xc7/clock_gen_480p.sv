// Project F: 640x480p60 Clock Generation (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Set to 25.2 MHz (640x480 60 Hz) with 100 MHz XO
// MMCME2_BASE and BUFG are documented in Xilinx UG472

module clock_gen_480p #(
    parameter MULT_MASTER=31.5,   // master clock multiplier (2.000-64.000)
    parameter DIV_MASTER=5,       // master clock divider (1-106)
    parameter DIV_PIX=25,         // pixel clock divider (1-128)
    parameter IN_PERIOD=10.0      // period of master clock in ns
    ) (
    input  wire logic clk,        // board oscillator
    input  wire logic rst,        // reset
    output      logic clk_pix,    // pixel clock
    output      logic clk_locked  // generated clocks locked?
    );

    logic clk_fb;         // internal clock feedback
    logic clk_pix_unbuf;  // unbuffered pixel clock
    logic locked;         // unsynced lock signal

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_PIX),
        .CLKOUT1_DIVIDE(1),  // included for Veriltator (TMDS clock)
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk),
        .RST(rst),
        .CLKOUT0(clk_pix_unbuf),
        .LOCKED(locked),
        .CLKFBOUT(clk_fb),
        .CLKFBIN(clk_fb),
        /* verilator lint_off PINCONNECTEMPTY */
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUTB(),
        .PWRDWN()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // explicitly buffer output clock
    BUFG bufg_clk(.I(clk_pix_unbuf), .O(clk_pix));

    // ensure clock lock is synced with pixel clock
    logic locked_sync_0;
    always_ff @(posedge clk_pix) begin
        locked_sync_0 <= locked;
        clk_locked <= locked_sync_0;
    end
endmodule
