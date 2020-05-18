// Project F: Beam - 640x480 Display Timings
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module display_timings (
    input  wire logic clk,              // 100 MHz clock
    input  wire logic stb_pix,          // 25 MHz pixel strobe
    input  wire logic rst,              // reset
    output      logic [9:0] sx,         // horizontal screen position
    output      logic [9:0] sy,         // vertical screen position
    output      logic hsync,            // horizontal sync
    output      logic vsync,            // vertical sync
    output      logic de,               // data enable (low in blanking interval)
    output      logic frame_start       // high for one cycle at frame start
    );

    // screen coordinates including blanking
    logic [9:0] x;
    logic [9:0] y;

    // horizontal timings
    localparam HS_STA = 16;             // sync starts after front porch
    localparam HS_END = 16 + 96;        // sync ends
    localparam HA_STA = 16 + 96 + 48;   // active starts after back porch
    localparam LINE   = 799;            // last pixel on line

    // vertical timings
    localparam VS_STA = 10;             // sync starts after front porch
    localparam VS_END = 10 + 2;         // sync ends
    localparam VA_STA = 10 + 2 + 33;    // active starts after back porch
    localparam SCREEN = 524;            // last line on screen

    always_comb begin
        sx = (x < HA_STA) ? 0 : (x - HA_STA);
        sy = (y < VA_STA) ? 0 : (y - VA_STA);
        hsync = ~(x >= HS_STA && x < HS_END);  // 640x480 sync polarity is negative...
        vsync = ~(y >= VS_STA && y < VS_END);  //  for horizontal and vertical sync
        de = (x >= HA_STA && y >= VA_STA);
        frame_start = (y == 0 && x == 0);
    end

    // calculate horizontal and vertical screen position
    always_ff @ (posedge clk) begin
        if (stb_pix) begin  // every 25 MHz strobe
            if (x == LINE) begin  // last pixel on line?
                x <= 0;
                y <= (y == SCREEN) ? 0 : y + 1;  // last line?
            end else begin
                x <= x + 1;
            end
        end
        if (rst) begin  // last assignment wins
            x <= 0;
            y <= 0;
        end
    end
endmodule
