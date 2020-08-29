// Project F: FPGA Ad Astra - Top Starfields (lichee Tang with LCD)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_starfields (
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

	localparam VSIZE = 500;
	localparam HSIZE = 992;

    // starfields
    logic sf1_on, sf2_on, sf3_on;
    logic [7:0] sf1_star, sf2_star, sf3_star;

    starfield #(.H(HSIZE), .V(VSIZE), .INC(-1), .SEED(21'h9A9A9)) sf1 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf1_on),
        .sf_star(sf1_star)
    );

    starfield #(.H(HSIZE), .V(VSIZE), .INC(-2), .SEED(21'hA9A9A)) sf2 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf2_on),
        .sf_star(sf2_star)
    );

    starfield #(.H(HSIZE), .V(VSIZE), .INC(-4), .MASK(21'h7FF)) sf3 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf3_on),
        .sf_star(sf3_star)
    );

    // colour channels
    logic [3:0] red, green, blue;
    always_comb begin
        red   = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
        green = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
        blue  = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
    end

    // LCD output
    always_comb begin
		lcd_clk = clk_pix;
		lcd_pwm = 1;
        lcd_r = (lcd_den) ? {red, 4'hf}   : 8'h0;
        lcd_g = (lcd_den) ? {green, 4'hf} : 8'h0;
        lcd_b = (lcd_den) ? {blue, 4'hf}  : 8'h0;
    end
endmodule
