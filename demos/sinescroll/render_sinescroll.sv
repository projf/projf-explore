// Project F: Sine Scroller Render
// (C)2022 Will Green & Ben Blundell, open source hardware released under the MIT License
// From "All You Need" by Chapterhouse released at Revision 2022 (with minor emendations)
// Learn more at https://projectf.io/posts/sinescroll/

`default_nettype none
`timescale 1ns / 1ps

module render_sinescroll #(
    parameter CORDW=16,       // signed coordinate width
    parameter GREET_FILE="",  // greet text ROM .mem file
    parameter FONT_FILE="",   // font glyph ROM .mem file
    parameter SIN_FILE="",    // sine table ROM .mem file
    parameter SIN_SHIFT=3,    // right-shift sine values
    parameter FB_WIDTH=320,   // framebuffer width in pixels
    parameter FB_HEIGHT=180   // framebuffer height in pixels
    ) (
    input  wire logic clk,                      // clock
    input  wire logic rst,                      // reset
    input  wire logic oe,                       // output enable
    input  wire logic start,                    // start control
    output      logic signed [CORDW-1:0] x, y,  // drawing position
    output      logic pix,                      // draw pixel at this position?
    output      logic drawing,                  // drawing in progress
    output      logic done                      // drawing is complete
    );

    // sine table
    localparam SIN_DEPTH=64;  // entires in sine ROM 0°-90°
    localparam SIN_WIDTH=8;   // width of sine ROM data
    localparam SIN_ADDRW=$clog2(4*SIN_DEPTH);   // full table -180° to +180°

    logic [SIN_ADDRW-1:0] sin_id, sin_offs;
    logic signed [CORDW-1:0] sin_data;  // sign extend data to match coords
    sine_table #(
        .ROM_DEPTH(SIN_DEPTH),
        .ROM_WIDTH(SIN_WIDTH),
        .ROM_FILE(SIN_FILE)
    ) sine_table_inst (
        .id(sin_id + sin_offs),
        .data(sin_data)
    );

    // greeting message ROM
    localparam GREET_MSGS  =   1;  // 1 message
    localparam GREET_LEN   =  71;  // number of code points
    localparam G_ROM_WIDTH =   8;  // highest code point is U+00FF
    localparam G_ROM_DEPTH = GREET_MSGS * GREET_LEN;
    localparam GREET_SPD   =   3;  // speed in pixels/frame
    
    logic [$clog2(G_ROM_DEPTH)-1:0] greet_rom_addr;
    logic [G_ROM_WIDTH-1:0] greet_rom_data;  // code point

    rom_sync #(
        .WIDTH(G_ROM_WIDTH),
        .DEPTH(G_ROM_DEPTH),
        .INIT_F(GREET_FILE)
    ) greet_rom (
        .clk,
        .addr(greet_rom_addr),
        .data(greet_rom_data)
    );

    // Outline 32x32 font
    localparam GLYPH_WIDTH  =  32;
    localparam GLYPH_SPACE  =   2;  // horizontal spacing
    localparam GLYPH_HEIGHT =  32;
    localparam GLYPH_COUNT  =  64;
    localparam GLYPH_OFFSET =  32;  // starts at U+0020
    localparam FONT_LSB = 0;

    // draw chars in framebuffer
    localparam CHAR_NUM = GREET_LEN;  // length of message in characters
    logic [$clog2(CHAR_NUM):0] cnt_char;  // message char counter
    logic signed [CORDW-1:0] cx, cy;  // chars coords
    logic signed [CORDW-1:0] cx_offs;  // horizontal offset for scrolling
    logic [7:0] ucp;  // Unicode code point (0-255 only)
    logic draw_start, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, MEM_WAIT, LOAD_CHAR, CLIP, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        draw_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                state <= MEM_WAIT;
                /* verilator lint_off WIDTH */
                greet_rom_addr <= cnt_char;  // max address is CHAR_NUM-1 
                sin_id <= cnt_char * 16;
                /* verilator lint_on WIDTH */
            end
            MEM_WAIT: begin
                state <= LOAD_CHAR;
            end
            LOAD_CHAR: begin
                ucp <= greet_rom_data;
                cx <= cx_offs + cnt_char * (GLYPH_WIDTH + GLYPH_SPACE);
                cy <= FB_HEIGHT/2-GLYPH_HEIGHT/2 + (sin_data >>> SIN_SHIFT);  // centre
                state <= CLIP;
            end
            CLIP: begin  // only render glyphs in the framebuffer area
                if (cx > -(GLYPH_WIDTH + GLYPH_SPACE) && cx < FB_WIDTH) begin
                    state <= DRAW;
                    draw_start <= 1;
                    // $display("  DRAW: cnt_char: %d, x=%d, y=%d", cnt_char, cx, cy);
                end else begin
                    if (cnt_char == CHAR_NUM-1) begin
                        state <= DONE;
                    end else begin
                        state <= INIT;
                        cnt_char <= cnt_char + 1;
                    end
                end
            end
            DRAW: begin
                if (draw_done) begin
                    if (cnt_char == CHAR_NUM-1) begin
                        state <= DONE;
                    end else begin
                        state <= INIT;
                        cnt_char <= cnt_char + 1;
                    end
                end
            end
            DONE: state <= IDLE;
            default: if (start) begin  // IDLE
                state <= INIT;
                cnt_char <= 0;
                sin_offs <= sin_offs + 1;
                // if final char has been drawn off the screen, restart loop
                cx_offs <= (cx < -GLYPH_WIDTH) ? FB_WIDTH : cx_offs - GREET_SPD;
                // $display("START: cx_offs: %d", cx_offs);
            end
        endcase
        if (rst) begin
            state <= INIT;
            cnt_char <= 0;
            sin_offs <= 0;
            cx_offs <= FB_WIDTH;
        end
    end

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
        .start(draw_start),
        .ucp,
        .cx,
        .cy,
        .x,
        .y,
        .pix,
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    // done for this module
    always_comb done = (state == DONE);
endmodule
