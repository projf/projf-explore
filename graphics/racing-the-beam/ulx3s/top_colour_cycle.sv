// Project F: Racing the Beam - Colour Cycle (ULX3S)
// (C) 2022 Will Green, (C) 2022 Tristan Itschner, 
// open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_colour_cycle (
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

	// screen dimensions (must match display_inst)
	localparam V_RES = 480;  // vertical screen resolution

	logic frame;  // high for one clock tick at the start of vertical blanking
	always_comb frame = (sy == V_RES && sx == 0);

	// update the colour level every N frames
	localparam FRAME_NUM = 30;  // frames between colour level change
	logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
	logic [3:0] colr_level;  // level of colour being cycled

	always_ff @(posedge clk_pix) begin
		if (frame) begin
			if (cnt_frame == FRAME_NUM-1) begin  // every FRAME_NUM frames
				cnt_frame <= 0;
				colr_level <= colr_level + 1;
			end else cnt_frame <= cnt_frame + 1;
		end
	end

	// determine colour from screen position
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		paint_r = sx[7:4];  // 16 horizontal pixels of each red level
		paint_g = sy[7:4];  // 16 vertical pixels of each green level
		paint_b = colr_level;  // blue level changes over time
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
