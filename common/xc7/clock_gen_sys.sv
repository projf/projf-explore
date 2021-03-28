// Project F: System Clock Generation (XC7)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Set to 125 MHz
// MMCME2_BASE and BUFG are documented in Xilinx UG472

module clock_gen_sys #(
    parameter MULT_MASTER=10.0,     // master clock multiplier
    parameter DIV_MASTER=1.0,       // master clock divider
    parameter DIV_1X=8,             // 1x clock divider
    parameter IN_PERIOD=10.0        // period of master clock in ns
    ) (
    input  wire logic clk_100m,     // board oscillator: 100 MHz
    input  wire logic rst,          // reset
    output      logic clk,          // system clock
    output      logic clk_locked    // system clock locked?
    );

    logic clk_fb;       // internal clock feedback
    logic clk_unbuf;    // unbuffered system clock
    logic locked;       // unsynced lock signal

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_1X),
        .CLKOUT1_DIVIDE(1),  // unused
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk_100m),
        .RST(rst),
        .CLKOUT0(clk_unbuf),
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

    // explicitly buffer output clocks
    BUFG bufg_clk(.I(clk_unbuf), .O(clk));

    // ensure clock lock is synced with system clock
    logic locked_sync_0;

    always_ff @(posedge clk) begin
        locked_sync_0 <= locked;
        clk_locked <= locked_sync_0;
    end
endmodule
