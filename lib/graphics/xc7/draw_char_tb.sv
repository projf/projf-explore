// Project F Library - Draw Line Test Bench
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_char_tb ();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    parameter CORDW        =  9;  // -256 to +255
    parameter GLYPH_WIDTH  =  8;  // width in pixels
    parameter GLYPH_HEIGHT =  8;  // number of lines
    parameter GLYPH_COUNT = 256;  // glyphs in font file
    parameter GLYPH_OFFSET =  0;  // first glyph in file
    parameter FONT_FILE = "font_unscii_8x8.mem";
    parameter FONT_LSB = 0;

    logic rst;
    logic clk;

    logic oe;  // output enable
    logic start;  // start signal
    logic [7:0] ucp; // Unicode code point (0-255 only)
    logic signed [CORDW-1:0] cx, cy;  // chars coords (input)
    logic signed [CORDW-1:0] x, y;  // drawing coordinates (output)
    logic pix;  // glyph pixel colour (0 or 1)
    logic drawing, busy, done;  // drawing signals

    draw_char #(
        .CORDW(CORDW),
        .WIDTH(GLYPH_WIDTH),
        .HEIGHT(GLYPH_HEIGHT),
        .COUNT(GLYPH_COUNT),
        .OFFSET(GLYPH_OFFSET),
        .FONT_FILE(FONT_FILE),
        .LSB(FONT_LSB)
        ) draw_char_inst (
        .clk,
        .rst,
        .oe,
        .start,
        .ucp,
        .cx,
        .cy,
        .x,
        .y,
        .pix,
        .drawing,
        .busy,
        .done
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d: U+00%h (%d,%d) %b (%b)", $time, ucp, x, y, pix, drawing);
    end

    initial begin
        rst = 1;
        clk = 1;
        
        oe    = 1;  // we're not (yet) testing output enable
        start = 0;
        cx    = 0;  // we're not (yet) testing character coordinates
        cy    = 0;  // we're not (yet) testing character coordinates
    
        #100 rst = 0;

        $display("U+0020 - space");
        #10 ucp = 8'h20;
        start = 1;
        #10 start = 0;

        #1000 $display("U+0041 - Capital A");
        #10 ucp = 8'h41;
        start = 1;
        #10 start = 0;

        #1000 $display("U+0077 - Lowercase W");
        #10 ucp = 8'h77;
        start = 1;
        #10 start = 0;

        #1000 $display("U+00BC - One Quarter");
        #10 ucp = 8'hBC;
        start = 1;
        #10 start = 0;

        #1000 $display("U+00DF - Eszett");
        #10 ucp = 8'hDF;
        start = 1;
        #10 start = 0;

        #1000   $finish;
    end
endmodule
