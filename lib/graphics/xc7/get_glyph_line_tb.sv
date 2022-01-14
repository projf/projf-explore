// Project F Library - Get Glyph Line Test Bench
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module get_glyph_line_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    parameter GLYPH_WIDTH  =  8;  // width in pixels
    parameter GLYPH_HEIGHT =  8;  // number of lines
    parameter GLYPH_COUNT = 256;  // glyphs in font file
    parameter GLYPH_OFFSET =  0;  // first glyph in file
    parameter FONT_FILE = "font_unscii_8x8.mem";
    parameter FONT_LSB = 0;

    logic rst;
    logic clk;

    logic [7:0] ucp; // Unicode code point (0-255 only)
    logic [$clog2(GLYPH_HEIGHT)-1:0] line_id;  // glyph line to get
    logic [GLYPH_WIDTH-1:0] glyph_line;  // glyph pixel line

    get_glyph_line #(
        .WIDTH(GLYPH_WIDTH),
        .HEIGHT(GLYPH_HEIGHT),
        .COUNT(GLYPH_COUNT),
        .OFFSET(GLYPH_OFFSET),
        .FONT_FILE(FONT_FILE),
        .LSB(FONT_LSB)
        ) get_glyph_line_inst (
        .clk,
        .rst,
        .ucp,
        .line_id,
        .glyph_line
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d: U+00%h (%d) %b", $time, ucp, line_id, glyph_line);
    end

    initial begin
        rst = 1;
        clk = 1;

        #100 rst = 0;

        $display("U+0020 - space");
        #10 ucp = 8'h20;
            line_id =  0;
        #10 line_id =  1;
        #10 line_id =  2;
        #10 line_id =  3;
        #10 line_id =  4;
        #10 line_id =  5;
        #10 line_id =  6;
        #10 line_id =  7;

        #100 $display("U+0041 - Capital A");
        #10 ucp = 8'h41;
            line_id =  0;
        #10 line_id =  1;
        #10 line_id =  2;
        #10 line_id =  3;
        #10 line_id =  4;
        #10 line_id =  5;
        #10 line_id =  6;
        #10 line_id =  7;

        #100 $display("U+0077 - Lowercase W");
        #10 ucp = 8'h77;
            line_id =  0;
        #10 line_id =  1;
        #10 line_id =  2;
        #10 line_id =  3;
        #10 line_id =  4;
        #10 line_id =  5;
        #10 line_id =  6;
        #10 line_id =  7;

        #100 $display("U+00BC - One Quarter");
        #10 ucp = 8'hBC;
            line_id =  0;
        #10 line_id =  1;
        #10 line_id =  2;
        #10 line_id =  3;
        #10 line_id =  4;
        #10 line_id =  5;
        #10 line_id =  6;
        #10 line_id =  7;

        #100 $display("U+00DF - Eszett");
        #10 ucp = 8'hDF;
            line_id =  0;
        #10 line_id =  1;
        #10 line_id =  2;
        #10 line_id =  3;
        #10 line_id =  4;
        #10 line_id =  5;
        #10 line_id =  6;
        #10 line_id =  7;

        #1000   $finish;
    end
endmodule
