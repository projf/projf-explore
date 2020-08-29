// Project F: FPGA Ad Astra - Top LFSR (lichee Tang with LCD)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_lfsr (
    input  wire logic clk_24m,      // 24 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
	output      logic lcd_clk,
	output      logic lcd_den,
	output      logic lcd_pwm,
    output      logic lcd_hsync,    // horizontal sync
    output      logic lcd_vsync,    // vertical sync
    output      logic [7:0] lcd_r,  // 8-bit LCD red
    output      logic [7:0] lcd_g,  // 8-bit LCD green
    output      logic [7:0] lcd_b   // 8-bit LCD blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_800x480 (
       .clk(clk_24m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    display_timings #(
		.HACTIVE(800), .HFP(24), .HSYNC(72), .HBP(96),
		.VACTIVE(480), .VFP(3), .VSYNC(7), .VBP(10)
	) timings_800x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(lcd_hsync),
        .vsync(lcd_vsync),
        .de(lcd_den)
    );

    logic sf_area;
    always_comb sf_area = (sx < 512 && sy < 256);

    // 17-bit LFSR
    logic [16:0] sf_reg;
    lfsr #(
        .LEN(17),
        .TAPS(17'b10010000000000000)
    ) lsfr_sf (
        .clk(clk_pix),
        .rst(!clk_locked),
        .en(sf_area && lcd_den),
        .sreg(sf_reg)
    );

    // VGA output
    logic star;
    always_comb begin
        star = &{sf_reg[16:9]};  // (~512 stars for 8 bits with 512x256)
		lcd_clk = clk_pix;
		lcd_pwm = 1;
        lcd_r = (lcd_den && sf_area && star) ? {sf_reg[3:0], 4'hf} : 8'h0;
        lcd_g = (lcd_den && sf_area && star) ? {sf_reg[3:0], 4'hf} : 8'h0;
        lcd_b = (lcd_den && sf_area && star) ? {sf_reg[3:0], 4'hf} : 8'h0;
    end
endmodule
