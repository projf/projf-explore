// Project F: FPGA Graphics - Colour Test (ULX3S)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_colour (
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

// determine colour from screen position
logic [3:0] paint_r, paint_g, paint_b;
always_comb begin
	if (sx < 256 && sy < 256) begin  // colour square in top-left 256x256 pixels
		paint_r = sx[7:4];  // 16 horizontal pixels of each red level
		paint_g = sy[7:4];  // 16 vertical pixels of each green level
		paint_b = 4'h4;     // constant blue level
	end else begin  // otherwise black
		paint_r = 4'h0;
		paint_g = 4'h0;
		paint_b = 4'h0;
	end
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
