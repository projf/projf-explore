// Project F Library - 640x480p60 Clock Generation (iCE40)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Generates 25.125 MHz (640x480 59.8 Hz) with 12 MHz input clock
// iCE40 PLLs are documented in Lattice TN1251 and ICE Technology Library

module clock_480p (
    input  wire logic clk_12m,        // input clock (12 MHz)
    input  wire logic rst,            // reset
    output      logic clk_pix,        // pixel clock
    output      logic clk_pix_locked  // pixel clock locked?
    );

    localparam FEEDBACK_PATH="SIMPLE";
    localparam DIVR=4'b0000;
    localparam DIVF=7'b1000010;
    localparam DIVQ=3'b101;
    localparam FILTER_RANGE=3'b001;

    logic locked;
    SB_PLL40_PAD #(
        .FEEDBACK_PATH(FEEDBACK_PATH),
        .DIVR(DIVR),
        .DIVF(DIVF),
        .DIVQ(DIVQ),
        .FILTER_RANGE(FILTER_RANGE)
    ) SB_PLL40_PAD_inst (
        .PACKAGEPIN(clk_12m),
        .PLLOUTGLOBAL(clk_pix),  // use global clock network
        .RESETB(rst),
        .BYPASS(1'b0),
        .LOCK(locked)
    );

    // ensure clock lock is synced with pixel clock
    logic locked_sync_0;
    always_ff @(posedge clk_pix) begin
        locked_sync_0 <= locked;
        clk_pix_locked <= locked_sync_0;
    end
endmodule
