// Project F: FPGA Ad Astra - 640x480 Display Timings
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module display_timings #(
	// default 640x480
	parameter HACTIVE = 640,
	parameter HFP     = 16,
	parameter HSYNC   = 96,
	parameter HBP     = 48,
	parameter VACTIVE = 480,
	parameter VFP     = 10,
	parameter VSYNC   = 2,
	parameter VBP     = 33
	) (
    input  wire logic clk_pix,          // pixel clock
    input  wire logic rst,              // reset
    output      logic [9:0] sx,         // horizontal screen position
    output      logic [9:0] sy,         // vertical screen position
    output      logic hsync,            // horizontal sync
    output      logic vsync,            // vertical sync
    output      logic de                // data enable (low in blanking interval)
    );

    // horizontal timings
    localparam HA_END = HACTIVE;         // end of active pixels
    localparam HS_STA = HA_END + HFP;    // sync starts after front porch
    localparam HS_END = HS_STA + HSYNC;  // sync ends
    localparam LINE   = HS_END + HBP - 1; // last pixel on line (after back porch)

    // vertical timings
    localparam VA_END = VACTIVE;         // end of active pixels
    localparam VS_STA = VA_END + VFP;    // sync starts after front porch
    localparam VS_END = VS_STA + VSYNC;  // sync ends
    localparam SCREEN = VS_END + VBP -1; // last line on screen (after back porch)

    always_comb begin
        hsync = ~(sx >= HS_STA && sx < HS_END);  // invert: hsync polarity is negative
        vsync = ~(sy >= VS_STA && sy < VS_END);  // invert: vsync polarity is negative
        de = (sx <= HA_END && sy <= VA_END);
    end

    // calculate horizontal and vertical screen position
    always_ff @ (posedge clk_pix) begin
        if (sx == LINE) begin  // last pixel on line?
            sx <= 0;
            sy <= (sy == SCREEN) ? 0 : sy + 1;  // last line on screen?
        end else begin
            sx <= sx + 1;
        end
        if (rst) begin
            sx <= 0;
            sy <= 0;
        end
    end
endmodule
