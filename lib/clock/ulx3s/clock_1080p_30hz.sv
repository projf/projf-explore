//
// This file was generated using "ecppll" from Project Trellis with some small
// edits. Timings are for CVT-RBv2 and 30Hz.
//
// Command used:
// ecppll -n clock_1080p --clkin_name clk_25mhz --clkin 25 --clkout0_name \
// clk_tmds_half --clkout0 328.80 --clkout1_name clk_66m --clkout1 65.76
//
// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module clock_1080p_30hz_cvtrbv2
(
    input clk_25mhz, // 25 MHz, 0 deg
    output clk_tmds_half, // 329.167 MHz, 0 deg
    output clk_66m, // 65.8333 MHz, 0 deg
    output clk_pix_locked
);
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="329.167" *)
(* FREQUENCY_PIN_CLKOS="65.8333" *)
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
        .CLKI_DIV(6),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(2),
        .CLKOP_CPHASE(0),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(10),
        .CLKOS_CPHASE(0),
        .CLKOS_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(79)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clk_25mhz),
        .CLKOP(clk_tmds_half),
        .CLKOS(clk_66m),
        .CLKFB(clk_tmds_half),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
		.LOCK(clk_pix_locked)
	);
endmodule
