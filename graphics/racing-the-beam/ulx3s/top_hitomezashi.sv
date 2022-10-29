// Project F: Racing the Beam - Hitomezashi (ULX3S)
// (C) 2022 Will Green, (C) 2022 Tristan Itschner, 
// open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hitomezashi (
	input  wire logic clk_25mhz,	// 25 MHz clock
	output wire logic [3:0] gpdi_dp
	);

	// generate pixel clock
	logic clk_tmds_half;
	logic clk_pix;
	logic clk_pix_locked;
	clock_720p clock_pix_inst (
	   .clk_25m(clk_25mhz),
	   .clk_tmds_half,
	   .clk_pix,
	   .LOCK(clk_pix_locked)
	);

	// display sync signals and coordinates
	localparam CORDW = 12;  // screen coordinate width in bits
	/* verilator lint_off UNUSED */
	logic [CORDW-1:0] sx, sy;
	/* verilator lint_on UNUSED */
	logic hsync, vsync, de;
	simple_720p display_inst (
		.clk_pix,
		.rst_pix(!clk_pix_locked),  // wait for clock lock
		.sx,
		.sy,
		.hsync,
		.vsync,
		.de
	);

	// stitch start values: big-endian vector, so we can write left to right
	/* verilator lint_off LITENDIAN */
	logic [0:39] v_start;  // 40 vertical lines
	logic [0:29] h_start;  // 30 horizontal lines
	/* verilator lint_on LITENDIAN */

	initial begin  // random start values
		v_start = 40'b01100_00101_00110_10011_10101_10101_01111_01101;
		h_start = 30'b10111_01001_00001_10100_00111_01010;
	end

	// paint stitch pattern with 16x16 pixel grid
	logic stitch;
	logic v_line, v_on;
	logic h_line, h_on;
	always_comb begin
		v_line = (sx[3:0] == 4'b0000);
		h_line = (sy[3:0] == 4'b0000);
		v_on = sy[4] ^ v_start[sx[9:4]];
		h_on = sx[4] ^ h_start[sy[8:4]];
		stitch = (v_line && v_on) || (h_line && h_on);
	end

	// paint colours: yellow lines, blue background
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		paint_r = (stitch) ? 4'hF : 4'h1;
		paint_g = (stitch) ? 4'hC : 4'h3;
		paint_b = (stitch) ? 4'h0 : 4'h7;
	end

	// gpdi output, comments for 720p
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
