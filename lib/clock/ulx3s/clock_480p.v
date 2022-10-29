// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module clock_480p
(
    input clk_25m, // 25 MHz, 0 deg
    output clk_tmds_half, // 125 MHz, 0 deg
    output clk_pix, // 25 MHz, 0 deg
    output LOCK
);
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="125" *)
(* FREQUENCY_PIN_CLKOS="25" *)
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
        .CLKI_DIV(1),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(5),
        .CLKOP_CPHASE(2),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(25),
        .CLKOS_CPHASE(2),
        .CLKOS_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(5)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk_25m),
        .CLKOP(clk_tmds_half),
        .CLKOS(clk_pix),
        .CLKFB(clk_tmds_half),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(LOCK)
	);
endmodule
