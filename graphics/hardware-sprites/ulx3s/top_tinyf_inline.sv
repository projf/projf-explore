// Project F: Hardware Sprites - Tiny F Inline (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_tinyf_inline (
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
logic de, line;
display_480p #(.CORDW(CORDW)) display_inst (
	.clk_pix,
	.rst_pix,
	.sx,
	.sy,
	.hsync,
	.vsync,
	.de,
	/* verilator lint_off PINCONNECTEMPTY */
	.frame(),
		/* verilator lint_on PINCONNECTEMPTY */
	.line
);

// screen dimensions (must match display_inst)
localparam H_RES = 640;

// sprite parameters
localparam SPRX = 32;  // horizontal position
localparam SPRY = 16;  // vertical position

// sprite
logic pix, drawing;
sprite_inline #(
	.CORDW(CORDW),
	.H_RES(H_RES)
) sprite_f (
	.clk(clk_pix),
	.rst(rst_pix),
	.line,
	.sx,
	.sy,
	.sprx(SPRX),
	.spry(SPRY),
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
	.red ( {paint_r, 4'b0000 } ),
	.green ( { paint_g, 4'b0000 } ),
	.blue ( { paint_b, 4'b0000 } ),
	.de,
	.hsync,
	.vsync,
	.gpdi_dp
);

endmodule
