// Project F Library - Draw 8-bit Char
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_char #(
    parameter CORDW=16,      // signed coordinate width
    parameter WIDTH=8,       // glyph width in pixels (8 or 16)
    parameter HEIGHT=16,     // glyph height in pixels (8 or 16)
    parameter COUNT=256,     // number of characters in font
    parameter OFFSET=0,      // glyph ROM offset
    parameter FONT_FILE="",  // file to load glyphs from
    parameter LSB=0          // first font pixel in LSB
    ) (
    input  wire logic clk,            // clock
    input  wire logic rst,            // reset
    input  wire logic oe,             // output enable
    input  wire logic start,          // start control
    input  wire logic [7:0] ucp,      // Unicode code point (0-255 only)
    input  wire logic signed [CORDW-1:0] cx, cy,  // character position
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      logic pix,            // draw pixel at this position?
    output      logic drawing,        // actively drawing
    output      logic busy,           // drawing request in progress
    output      logic done            // drawing is complete (high for one tick)
    );

    // glyph line reader
    localparam GLYPH_READ_LAT = 3;  // cycles to read a glyph line
    logic [$clog2(HEIGHT)-1:0] line_id;  // glyph line to get
    logic [WIDTH-1:0] glyph_line;  // glyph pixel lin

    get_glyph_line #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .COUNT(COUNT),
        .OFFSET(OFFSET),
        .FONT_FILE(FONT_FILE),
        .LSB(LSB)
        ) get_glyph_line_inst (
        .clk,
        .rst,
        .ucp(ucp0),
        .line_id,
        .glyph_line
    );

    logic [7:0] ucp0; // register Unicode code point
    logic signed [CORDW-1:0] cx0, cy0;  // register character position
    logic [$clog2(WIDTH)-1:0] gx; // position on glyph pixel line
    logic [$clog2(GLYPH_READ_LAT)-1:0] cnt_lat;  // latency counter

    // status signals
    logic last_pixel, last_line;

    enum {
        IDLE,        // awaiting start signal
        START,       // prepare for drawing
        GLYPH_WAIT,  // wait for glyph read (1 cycle)
        DRAW,        // draw line of glyph pixels
        NEXT_LINE,   // prepare for next line
        DONE         // set done signal
    } state, state_next;

    always_ff @(posedge clk) begin
        state <= state_next;  // advance to next state
        done <= 0;
        cnt_lat <= cnt_lat + 1;

        case (state)
            START: begin
                busy <= 1;
                done <= 0;
                ucp0 <= ucp;
                cx0 <= cx;
                cy0 <= cy;
                x <= cx;
                y <= cy;
                gx <= 0;
                line_id <= 0;
                cnt_lat <= 0;
            end
            DRAW: begin
                if (oe) begin
                    gx <= gx + 1;
                    if (!last_pixel) begin
                        x <= x + 1;
                    end else begin
                        line_id <= line_id + 1;
                    end
                end
            end
            NEXT_LINE: begin
                gx <= 0;
                x <= cx0;
                y <= y + 1;
                cnt_lat <= 0;
            end
            DONE: begin
                busy <= 0;
                done <= 1;
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            ucp0 <= 0;
            cx0 <= 0;
            cy0 <= 0;
            x <= 0;
            y <= 0;
            gx <= 0;
            line_id <= 0;
            cnt_lat <= 0;
        end
    end

    // output current pixel colour when drawing
    always_comb begin
        pix = drawing ? glyph_line[gx] : 0;
    end

    // generate status signals
    always_comb begin
        /* verilator lint_off WIDTH */
        last_pixel = (gx == WIDTH - 1);
        /* verilator lint_on WIDTH */
        last_line  = (y == cy0 + HEIGHT - 1);
        drawing = (state == DRAW && oe);
    end

    // determine next state
    always_comb begin
        case (state)
            IDLE:       state_next = start ? START : IDLE;
            START:      state_next = GLYPH_WAIT;
            GLYPH_WAIT: state_next = (cnt_lat == GLYPH_READ_LAT-1) ? DRAW : GLYPH_WAIT;
            DRAW:       state_next = !last_pixel ? DRAW :
                                    (!last_line ? NEXT_LINE : DONE);
            NEXT_LINE:  state_next = GLYPH_WAIT;
            DONE:       state_next = IDLE;
            default:    state_next = IDLE;
        endcase
    end
endmodule
