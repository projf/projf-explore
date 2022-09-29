// Project F: Hardware Sprites - Tiny F with Motion (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_tinyf_move (
	input  wire logic clk_25mhz,    // 25 MHz clock
	input  wire logic [6:0] btn,
	output wire logic [3:0] gpdi_dp
);

// generate pixel clock
logic clk_pix;
logic clk_tmds_half;
logic clk_pix_locked;
clock_480p clock_pix_inst (
	.clk_25mhz,
	.clk_25m(clk_pix),
	.clk_tmds_half,
	.clk_pix_locked
);

// reset in pixel clock domain
logic rst_pix;
always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

// display sync signals and coordinates
localparam CORDW = 16;  // signed coordinate width (bits)
logic signed [CORDW-1:0] sx, sy;
logic hsync, vsync;
logic de, frame, line;
display_480p #(.CORDW(CORDW)) display_inst (
	.clk_pix,
	.rst_pix,
	.sx,
	.sy,
	.hsync,
	.vsync,
	.de,
	.frame,
	.line
);

// screen dimensions (must match display_inst)
localparam H_RES = 640;
localparam V_RES = 480;

// sprite parameters
localparam SPR_WIDTH  = 8;  // bitmap width in pixels
localparam SPR_HEIGHT = 8;  // bitmap height in pixels
localparam SPR_SCALE  = 3;  // 2^3 = 8x scale
localparam SPR_DATAW  = 1;  // bits per pixel
localparam SPR_DRAWW  = SPR_WIDTH  * 2**SPR_SCALE;  // draw width
localparam SPR_DRAWH  = SPR_HEIGHT * 2**SPR_SCALE;  // draw height
localparam SPR_SPX    = 4;  // horizontal speed (pixels/frame)
localparam SPR_FILE   = "../res/sprites/letter_f.mem";  // bitmap file

// draw sprite at position (sprx,spry)
logic signed [CORDW-1:0] sprx, spry;
logic dx;  // direction: 0 is right/down

// update sprite position once per frame
always_ff @(posedge clk_pix) begin
	if (frame) begin
		if (dx == 0) begin  // moving right
			if (sprx + SPR_DRAWW >= H_RES + 2*SPR_DRAWW) dx <= 1;  // move left
			else sprx <= sprx + SPR_SPX;  // continue right
		end else begin  // moving left
			if (sprx <= -2*SPR_DRAWW) dx <= 0;  // move right
			else sprx <= sprx - SPR_SPX;  // continue left
		end
	end
	if (rst_pix) begin  // centre sprite and set direction right
		sprx <= H_RES/2 - SPR_DRAWW/2;
		spry <= V_RES/2 - SPR_DRAWH/2;
		dx <= 0;
	end
end

logic drawing;  // drawing at (sx,sy)
logic [SPR_DATAW-1:0] pix;  // pixel colour index
sprite #(
	.CORDW(CORDW),
	.H_RES(H_RES),
	.SPR_FILE(SPR_FILE),
	.SPR_WIDTH(SPR_WIDTH),
	.SPR_HEIGHT(SPR_HEIGHT),
	.SPR_SCALE(SPR_SCALE),
	.SPR_DATAW(SPR_DATAW)
) sprite_f (
	.clk(clk_pix),
	.rst(rst_pix),
	.line,
	.sx,
	.sy,
	.sprx,
	.spry,
	.pix,
	.drawing
);

// paint colours: yellow sprite, blue background
logic [3:0] paint_r, paint_g, paint_b;
always_comb begin
	paint_r = (drawing && pix) ? 4'hF : 4'h1;
	paint_g = (drawing && pix) ? 4'hC : 4'h3;
	paint_b = (drawing && pix) ? 4'h0 : 4'h7;
end

// gpdi output
pix2gpdi pix2gpdi_inst(
	.clk_pix, // ~25 MHz
	.clk_tmds_half, // 5* clk_pix, ~ 125 MHz, must be phase aligned
	.red   ( {paint_r, 4'b0000} ),
	.green ( {paint_g, 4'b0000} ),
	.blue  ( {paint_b, 4'b0000} ),
	.de,
	.hsync,
	.vsync,
	.gpdi_dp
);

endmodule
