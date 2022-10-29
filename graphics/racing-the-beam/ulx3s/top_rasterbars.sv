// Project F: Racing the Beam - Colour Test (ULX3S)
// (C)2022 Will Green, (C)2022 Tristan Itschner 
// open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars (
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
	logic [CORDW-1:0] sx, sy;
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

	// screen dimensions (must match display_inst)
	localparam V_RES_FULL = 525;  // vertical screen resolution (including blanking)
	localparam H_RES	  = 640;  // horizontal screen resolution

	localparam START_COLR = 12'h126;  // bar start colour (blue: 12'h126) (gold: 12'h640)
	localparam COLR_NUM   = 10;	   // colours steps in each bar (don't overflow)
	localparam LINE_NUM   =  2;	   // lines of each colour

	logic [11:0] bar_colr;  // 12 bit colour (4 bits per channel)
	logic bar_inc;  // increase (or decrease) brightness
	logic [$clog2(COLR_NUM):0] cnt_colr;  // count colours in each bar
	logic [$clog2(LINE_NUM):0] cnt_line;  // count lines of each colour

	// update colour for each screen line
	always_ff @(posedge clk_pix) begin
		if (sx == H_RES) begin  // on each screen line at the start of blanking
			if (sy == V_RES_FULL-1) begin  // reset colour on last line of screen
				bar_colr <= START_COLR;
				bar_inc <= 1;  // start by increasing brightness
				cnt_colr <= 0;
				cnt_line <= 0;
			end else if (cnt_line == LINE_NUM-1) begin  // colour complete
				cnt_line <= 0;
				if (cnt_colr == COLR_NUM-1) begin  // switch increase/decrease
					bar_inc <= ~bar_inc;
					cnt_colr <= 0;
				end else begin
					bar_colr <= (bar_inc) ? bar_colr + 12'h111 : bar_colr - 12'h111;
					cnt_colr <= cnt_colr + 1;
				end
			end else cnt_line <= cnt_line + 1;
		end
	end

	// separate colour channels
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb {paint_r, paint_g, paint_b} = bar_colr;

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
