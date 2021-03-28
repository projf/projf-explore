// Project F: 1920x1080p60 Clock Generation (XC7)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Set to 148.5 MHz for 1080p60
// MMCME2_BASE and BUFG are documented in Xilinx UG472

module clock_gen_1080p #(
    parameter MULT_MASTER=37.125,       // master clock multiplier
    parameter DIV_MASTER=5,             // master clock divider
    parameter DIV_5X=1.0,               // 5x clock divider
    parameter DIV_1X=5,                 // 1x clock divider
    parameter IN_PERIOD=10.0            // period of master clock in ns
    ) (
    input  wire logic clk_100m,         // board oscillator: 100 MHz
    input  wire logic rst,              // reset
    output      logic clk_pix,          // pixel clock
    output      logic clk_pix_5x,       // 5x clock for 10:1 DDR SerDes
    output      logic clk_pix_locked    // pixel clocks locked?
    );

    logic clk_pix_fb;       // internal clock feedback
    logic clk_pix_unbuf;    // unbuffered pixel clock
    logic clk_pix_5x_unbuf; // unbuffered 5x pixel clock
    logic locked;           // unsynced lock signal

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_5X),
        .CLKOUT1_DIVIDE(DIV_1X),
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk_100m),
        .RST(rst),
        .CLKOUT0(clk_pix_5x_unbuf),
        .CLKOUT1(clk_pix_unbuf),
        .LOCKED(locked),
        .CLKFBOUT(clk_pix_fb),
        .CLKFBIN(clk_pix_fb),
        /* verilator lint_off PINCONNECTEMPTY */
        .CLKOUT0B(),
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
    BUFG bufg_clk(.I(clk_pix_unbuf), .O(clk_pix));
    BUFG bufg_clk_5x(.I(clk_pix_5x_unbuf), .O(clk_pix_5x));

    // ensure clock lock is synced with pixel clock
    logic locked_sync_0;
    always_ff @(posedge clk_pix) begin
        locked_sync_0 <= locked;
        clk_pix_locked <= locked_sync_0;
    end
endmodule
