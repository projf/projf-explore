// Project F: Racing the Beam - Bounce (ULX3S)
// (C) 2022 Will Green, (C) 2022 Tristan Itschner, 
// open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_bounce (
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
	localparam H_RES = 640;  // horizontal screen resolution
	localparam V_RES = 480;  // vertical screen resolution

	logic frame;  // high for one clock tick at the start of vertical blanking
	always_comb frame = (sy == V_RES && sx == 0);

	// frame counter lets us to slow down the action
	localparam FRAME_NUM = 1;  // slow-mo: animate every N frames
	logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
	always_ff @(posedge clk_pix) begin
		if (frame) cnt_frame <= (cnt_frame == FRAME_NUM-1) ? 0 : cnt_frame + 1;
	end

	// square parameters
	localparam Q_SIZE = 200;   // size in pixels
	logic [CORDW-1:0] qx, qy;  // position (origin at top left)
	logic qdx, qdy;			// direction: 0 is right/down
	logic [CORDW-1:0] qs = 2;  // speed in pixels/frame

	// update square position once per frame
	always_ff @(posedge clk_pix) begin
		if (frame && cnt_frame == 0) begin
			// horizontal position
			if (qdx == 0) begin  // moving right
				if (qx + Q_SIZE + qs >= H_RES-1) begin  // hitting right of screen?
					qx <= H_RES - Q_SIZE - 1;  // move right as far as we can
					qdx <= 1;  // move left next frame
				end else qx <= qx + qs;  // continue moving right
			end else begin  // moving left
				if (qx < qs) begin  // hitting left of screen?
					qx <= 0;  // move left as far as we can
					qdx <= 0;  // move right next frame
				end else qx <= qx - qs;  // continue moving left
			end

			// vertical position
			if (qdy == 0) begin  // moving down
				if (qy + Q_SIZE + qs >= V_RES-1) begin  // hitting bottom of screen?
					qy <= V_RES - Q_SIZE - 1;  // move down as far as we can
					qdy <= 1;  // move up next frame
				end else qy <= qy + qs;  // continue moving down
			end else begin  // moving up
				if (qy < qs) begin  // hitting top of screen?
					qy <= 0;  // move up as far as we can
					qdy <= 0;  // move down next frame
				end else qy <= qy - qs;  // continue moving up
			end
		end
	end

	// define a square with screen coordinates
	logic square;
	always_comb begin
		square = (sx >= qx) && (sx < qx + Q_SIZE) && (sy >= qy) && (sy < qy + Q_SIZE);
	end

	// paint colours: white inside square, blue outside
	logic [3:0] paint_r, paint_g, paint_b;
	always_comb begin
		paint_r = (square) ? 4'hF : 4'h1;
		paint_g = (square) ? 4'hF : 4'h3;
		paint_b = (square) ? 4'hF : 4'h7;
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
