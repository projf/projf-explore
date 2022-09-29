// Project F: Hardware Sprites - Hedgehog (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_hedgehog (
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

// colour parameters
localparam CHANW = 4;         // colour channel width (bits)
localparam COLRW = 3*CHANW;   // colour width: three channels (bits)
localparam CIDXW = 4;         // colour index width (bits)
localparam TRANS_INDX = 'h9;  // transparant colour index
localparam PAL_FILE = "../res/palettes/hedgehog_4b.mem";  // palette file

// sprite parameters
localparam SX_OFFS    =  3;  // horizontal screen offset (pixels): +1 for CLUT
localparam SPR_WIDTH  = 32;  // bitmap width in pixels
localparam SPR_HEIGHT = 20;  // bitmap height in pixels
localparam SPR_SCALE  =  2;  // 2^2 = 4x scale
localparam SPR_DRAWW  = SPR_WIDTH * 2**SPR_SCALE;  // draw width
localparam SPR_SPX    =  2;  // horizontal speed (pixels/frame)
localparam SPR_FILE   = "../res/sprites/hedgehog.mem";  // bitmap file

logic signed [CORDW-1:0] sprx, spry;  // draw sprite at position (sprx,spry)

// update sprite position once per frame
always_ff @(posedge clk_pix) begin
	if (frame) begin
		if (sprx <= -SPR_DRAWW) sprx <= H_RES;  // move back to right of screen
		else sprx <= sprx - SPR_SPX;  // otherwise keep moving left
	end
	if (rst_pix) begin  // start off screen and level with grass
		sprx <= H_RES;
		spry <= 240;
	end
end

logic drawing;  // drawing at (sx,sy)
logic [CIDXW-1:0] spr_pix_indx;  // pixel colour index
sprite #(
	.CORDW(CORDW),
	.H_RES(H_RES),
	.SX_OFFS(SX_OFFS),
	.SPR_FILE(SPR_FILE),
	.SPR_WIDTH(SPR_WIDTH),
	.SPR_HEIGHT(SPR_HEIGHT),
	.SPR_SCALE(SPR_SCALE),
	.SPR_DATAW(CIDXW)
) sprite_hedgehog (
	.clk(clk_pix),
	.rst(rst_pix),
	.line,
	.sx,
	.sy,
	.sprx,
	.spry,
	.pix(spr_pix_indx),
	.drawing
);

// colour lookup table
logic [COLRW-1:0] spr_pix_colr;
clut_simple #(
	.COLRW(COLRW),
	.CIDXW(CIDXW),
	.F_PAL(PAL_FILE)
) clut_instance (
	.clk_write(clk_pix),
	.clk_read(clk_pix),
	.we(0),
	.cidx_write(0),
	.cidx_read(spr_pix_indx),
	.colr_in(0),
	.colr_out(spr_pix_colr)
);

// account for transparency and delay drawing signal to match CLUT delay (1 cycle)
logic drawing_t1;
always_ff @(posedge clk_pix) drawing_t1 <= drawing && (spr_pix_indx != TRANS_INDX);

// background colour
logic [COLRW-1:0] bg_colr;
always_ff @(posedge clk_pix) begin
	if (line) begin
		if      (sy == 0)   bg_colr <= 12'h239;
		else if (sy == 80)  bg_colr <= 12'h24A;
		else if (sy == 140) bg_colr <= 12'h25B;
		else if (sy == 190) bg_colr <= 12'h26C;
		else if (sy == 230) bg_colr <= 12'h27D;
		else if (sy == 265) bg_colr <= 12'h29E;
		else if (sy == 295) bg_colr <= 12'h2BF;
		else if (sy == 320) bg_colr <= 12'h260;
	end
end

// paint colours
logic [CHANW-1:0] paint_r, paint_g, paint_b;
always_comb {paint_r, paint_g, paint_b} = (drawing_t1) ? spr_pix_colr : bg_colr;

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
