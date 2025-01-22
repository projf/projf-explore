// Project F Library - Dual clock generation (ECP5)
// Copyright Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/ecp5-fpga-clock/

module clock2_gen #(
    parameter CLKI_DIV  = 1,     // input clock divider
    parameter CLKFB_DIV = 1,     // feedback divider
    parameter CLKOP_DIV = 1,     // primary output clock divider
    parameter CLKOP_CPHASE = 0,  // primary output clock phase
    parameter CLKOS_DIV = 1,     // secondary output clock divider
    parameter CLKOS_CPHASE = 0   // secondary output clock phase
    ) (
    input  wire clk_in,      // input clock
    output wire clk_5x_out,  // output 5x clock
    output wire clk_out,     // output clock
    output reg  clk_locked   // clock locked?
    );

    wire locked;  // unsynced lock signal

    // HDL attributes (values are from Project Trellis)
    (* ICP_CURRENT="12" *)
    (* LPF_RESISTOR="8" *)
    (* MFG_ENABLE_FILTEROPAMP="1" *)
    (* MFG_GMCREF_SEL="2" *)

    EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(CLKI_DIV),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(CLKOP_DIV),
        .CLKOP_CPHASE(CLKOP_CPHASE),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(CLKOS_DIV),
        .CLKOS_CPHASE(CLKOS_CPHASE),
        .CLKOS_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(CLKFB_DIV)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk_in),
        .CLKOP(clk_5x_out),
        .CLKOS(clk_out),
        .CLKFB(clk_5x_out),
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

    // ensure clock lock is synced with output clock
    reg locked_sync;
    always @(posedge clk_out) begin
        locked_sync <= locked;
        clk_locked <= locked_sync;
    end
endmodule
