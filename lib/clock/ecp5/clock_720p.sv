// Project F Library - 1280x720p60 TMDS Clock Generation (ECP5)
// Copyright Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// Generate 74.0 MHz (1280x720 59.8Hz) with 25 MHz input clock
// ECP5 PLLs are documented in Lattice TN02200 and FPGA Libraries Reference Guide
// ECP5 PLL dividers: https://github.com/YosysHQ/prjtrellis/blob/master/libtrellis/tools/ecppll.cpp

// 74 MHz Dividers
// f_VCO:   (FREQUENCY_PIN_CLKI / CLKI_DIV) x CLKFB_DIV x CLKOP_DIV = (25 / 5) * 74 * 2 = 740 MHz
// f_CLKOP: f_VCO/CLKOP_DIV = 740/2 = 370 MHz
// f_CLKOS: f_VCO/CLKOS_DIV = 740/10 = 74 MHz

module clock_720p (
    input  wire logic clk_25m,        // input clock (25 MHz)
    input  wire logic rst,            // reset
    output      logic clk_pix,        // pixel clock
    output      logic clk_pix_5x,     // 5x clock for 10:1 DDR SerDes
    output      logic clk_pix_locked  // pixel clock locked?
    );

    logic locked;  // unsynced lock signal

    // HDL attributes
    (* FREQUENCY_PIN_CLKI="25" *)
    (* FREQUENCY_PIN_CLKOP="370" *)
    (* FREQUENCY_PIN_CLKOS="74" *)

    // following attributes are copied from libtrellis/tools/ecppll.cpp
    (* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)

    EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(5),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(2),
        .CLKOP_CPHASE(1),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(10),
        .CLKOS_CPHASE(1),
        .CLKOS_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(74)
    ) pll_i (
        .RST(rst),
        .STDBY(1'b0),
        .CLKI(clk_25m),
        .CLKOP(clk_pix_5x),
        .CLKOS(clk_pix),
        .CLKFB(clk_pix_5x),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
    );

    // ensure clock lock is synced with pixel clock
    logic locked_sync_0;
    always_ff @(posedge clk_pix) begin
        locked_sync_0 <= locked;
        clk_pix_locked <= locked_sync_0;
    end
endmodule
