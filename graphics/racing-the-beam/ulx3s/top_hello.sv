// Project F: Racing the Beam - Hello (ULX3S)
// (C) 2022 Will Green, (C) 2022 Tristan Itschner, 
// open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hello (
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

	// bitmap: big-endian vector, so we can write pixels left to right
	/* verilator lint_off LITENDIAN */
	logic [0:19] bmap [15];  // 20 pixels by 15 lines
	/* verilator lint_on LITENDIAN */

	initial begin
		bmap[0]  = 20'b1010_1110_1000_1000_0110;
		bmap[1]  = 20'b1010_1000_1000_1000_1010;
		bmap[2]  = 20'b1110_1100_1000_1000_1010;
		bmap[3]  = 20'b1010_1000_1000_1000_1010;
		bmap[4]  = 20'b1010_1110_1110_1110_1100;
		bmap[5]  = 20'b0000_0000_0000_0000_0000;
		bmap[6]  = 20'b1010_0110_1110_1000_1100;
		bmap[7]  = 20'b1010_1010_1010_1000_1010;
		bmap[8]  = 20'b1010_1010_1100_1000_1010;
		bmap[9]  = 20'b1110_1010_1010_1000_1010;
		bmap[10] = 20'b1110_1100_1010_1110_1110;
		bmap[11] = 20'b0000_0000_0000_0000_0000;
		bmap[12] = 20'b0000_0000_0000_0000_0000;
		bmap[13] = 20'b0000_0000_0000_0000_0000;
		bmap[14] = 20'b0000_0000_0000_0000_0000;
	end

	// paint at 32x scale in active screen area
	logic picture;
	logic [4:0] x;  // 20 columns need five bits
	logic [3:0] y;  // 15 rows need four bits
	always_comb begin
		x = sx[9:5];  // every 32 horizontal pixels
		y = sy[8:5];  // every 32 vertical pixels
		picture = de ? bmap[y][x] : 0;  // look up pixel (unless we're in blanking)
	end

	// paint colours: yellow lines, blue background
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		paint_r = (picture) ? 4'hF : 4'h1;
		paint_g = (picture) ? 4'hC : 4'h3;
		paint_b = (picture) ? 4'h0 : 4'h7;
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
