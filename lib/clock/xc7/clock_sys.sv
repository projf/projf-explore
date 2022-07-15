// Project F Library - System Clock Generation (XC7)
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Generates 125 MHz with 100 MHz input clock
// MMCME2_BASE and BUFG are documented in Xilinx UG472

module clock_sys (
    input  wire logic clk_100m,       // input clock (100 MHz)
    input  wire logic rst,            // reset
    output      logic clk_sys,        // system clock
    output      logic clk_sys_locked  // system clock locked?
    );

    localparam MULT_MASTER=10.0;  // master clock multiplier (2.000-64.000)
    localparam DIV_MASTER=1.0;    // master clock divider (1-106)
    localparam DIV_1X=8;          // pixel clock divider
    localparam IN_PERIOD=10.0;    // period of master clock in ns (10 ns == 100 MHz)

    logic feedback;       // internal clock feedback
    logic clk_sys_unbuf;  // unbuffered pixel clock
    logic locked;         // unsynced lock signal

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_1X),
        .CLKOUT1_DIVIDE(1),  // unused
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk_100m),
        .RST(rst),
        .CLKOUT0(clk_sys_unbuf),
        .LOCKED(locked),
        .CLKFBOUT(feedback),
        .CLKFBIN(feedback),
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
    BUFG bufg_clk(.I(clk_sys_unbuf), .O(clk_sys));

    // ensure clock lock is synced with system clock
    logic locked_sync_0;

    always_ff @(posedge clk_sys) begin
        locked_sync_0 <= locked;
        clk_sys_locked <= locked_sync_0;
    end
endmodule
