// Project F: 24x18 Display Timings
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module display_timings_24x18 (
    input  wire logic clk_pix,   // pixel clock
    input  wire logic rst,       // reset
    output      logic [4:0] sx,  // horizontal screen position
    output      logic [4:0] sy,  // vertical screen position
    output      logic hsync,     // horizontal sync
    output      logic vsync,     // vertical sync
    output      logic de         // data enable (low in blanking interval)
    );

    // horizontal timings
    parameter HA_END = 23;            // end of active pixels
    parameter HS_STA = HA_END + 2;    // sync starts after front porch
    parameter HS_END = HS_STA + 2;    // sync ends
    parameter LINE   = 31;            // last pixel on line (after back porch)

    // vertical timings
    parameter VA_END = 17;            // end of active pixels
    parameter VS_STA = VA_END + 1;    // sync starts after front porch
    parameter VS_END = VS_STA + 1;    // sync ends
    parameter SCREEN = 22;            // last line on screen (after back porch)

    always_comb begin
        hsync = ~(sx >= HS_STA && sx < HS_END);  // invert: negative polarity
        vsync = ~(sy >= VS_STA && sy < VS_END);  // invert: negative polarity
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
