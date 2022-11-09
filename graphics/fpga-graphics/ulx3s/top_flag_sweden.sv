// Project F: FPGA Graphics - Flag of Sweden (ULX3S)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_flag_sweden (
	input  wire logic clk_25mhz,	// 25 MHz clock
	output wire logic [3:0] gpdi_dp
	);

	// generate pixel clock
	logic clk_tmds_half;
	logic clk_pix;
	logic clk_pix_locked;
	clock_480p clock_pix_inst (
	   .clk_25m(clk_25mhz),
	   .clk_tmds_half,
	   .clk_pix,
	   .LOCK(clk_pix_locked)
	);

	// display sync signals and coordinates
	localparam CORDW = 10;  // screen coordinate width in bits
	logic [CORDW-1:0] sx, sy;
	logic hsync, vsync, de;
	simple_480p display_inst (
		.clk_pix,
		.rst_pix(!clk_pix_locked),  // wait for clock lock
		.sx,
		.sy,
		.hsync,
		.vsync,
		.de
	);

	// flag of Sweden (16:10 ratio)
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		if (sy >= 400) begin  // black outside the flag area
			paint_r = 4'h0;
			paint_g = 4'h0;
			paint_b = 4'h0;
		end else if (sy > 160 && sy < 240) begin  // yellow cross horizontal
			paint_r = 4'hF;
			paint_g = 4'hC;
			paint_b = 4'h0;
		end else if (sx > 200 && sx < 280) begin  // yellow cross vertical
			paint_r = 4'hF;
			paint_g = 4'hC;
			paint_b = 4'h0;
		end else begin  // blue flag background
			paint_r = 4'h0;
			paint_g = 4'h6;
			paint_b = 4'hA;
		end
	end

	// gpdi output, comments for 480p
	pix2gpdi pix2gpdi_inst(
		.clk_pix,	   // ~25 MHz
		.clk_tmds_half, // 5*clk_pix, ~ 125 MHz, must be phase aligned
		.r ( {paint_r, 4'b0000 } ),
		.g ( {paint_g, 4'b0000 } ),
		.b ( {paint_b, 4'b0000 } ),
		.de,
		.hs (hsync),
		.vs (vsync),
		.gpdi_dp
	);

endmodule
