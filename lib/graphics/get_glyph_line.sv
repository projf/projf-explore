// Project F Library - Get Glyph Line
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module get_glyph_line #(
    parameter WIDTH=8,       // glyph width in pixels
    parameter HEIGHT=16,     // glyph height in pixels
    parameter COUNT=256,     // number of characters in font
    parameter OFFSET=0,      // glyph ROM offset
    parameter FONT_FILE="",  // file to load glyphs from
    parameter LSB=0          // first font pixel in LSB
    ) (
    input  wire logic clk,                             // clock
    input  wire logic rst,                             // reset
    input  wire logic [7:0] ucp,                       // Unicode code point (0-255 only)
    input  wire logic [$clog2(HEIGHT)-1:0] line_id,    // glyph line to get
    output      logic [WIDTH-1:0] glyph_line           // glyph pixel line
    );

    // font glyph ROM - line of glyph pixels at each location
    localparam DEPTH = HEIGHT * COUNT;
    logic [$clog2(DEPTH)-1:0] rom_addr;
    logic [WIDTH-1:0] rom_data;
    rom_sync #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .INIT_F(FONT_FILE)
    ) glyph_rom (
        .clk,
        .addr(rom_addr),
        .data(rom_data)
    );

    integer i;  // for bit reversal

    always_ff @(posedge clk) begin
        /* verilator lint_off WIDTH */
        rom_addr <= (ucp - OFFSET) * HEIGHT + line_id;
        /* verilator lint_on WIDTH */
        if (LSB) begin
            glyph_line <= rom_data;
        end else begin  // reverse if MSB is left-most pixel
            for (i=0; i<WIDTH; i=i+1) glyph_line[i] <= rom_data[(WIDTH-1)-i];
        end
        if (rst) rom_addr <= 0;
    end
endmodule
