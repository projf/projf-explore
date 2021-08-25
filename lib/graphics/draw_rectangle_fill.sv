// Project F Library - Draw Filled Rectangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_rectangle_fill #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start rectangle drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0, y0,  // vertex 0
    input  wire logic signed [CORDW-1:0] x1, y1,  // vertex 2
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    // filled rectangle has as many lines as it is tall abs(y1-y0)
    logic signed [CORDW-1:0] line_id;  // current line
    logic line_start;  // start drawing line
    logic line_done;   // finished drawing current line?

    // sort input Y coordinates so we always draw top-to-bottom
    logic signed [CORDW-1:0] y0s, y1s;  // vertex 0 - ordered
    always_comb begin
        y0s = (y0 > y1) ? y1 : y0;
        y1s = (y0 > y1) ? y0 : y1;  // last line
    end

    // horizontal line coordinates
    logic signed [CORDW-1:0] lx0, lx1;

    // draw state machine
    enum {IDLE, INIT, DRAW} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates
                state <= DRAW;
                line_start <= 1;
                // x-coordinates don't change for a given filled rectangle
                lx0 <= (x0 > x1) ? x1 : x0;  // draw left-to-right
                lx1 <= (x0 > x1) ? x0 : x1;
                y <= y0s + line_id;  // vertical position
            end
            DRAW: begin
                line_start <= 0;
                if (line_done) begin
                    if (y == y1s) begin
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        state <= INIT;
                        line_id <= line_id + 1;
                    end
                end
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= INIT;
                    line_id <= 0;
                    busy <= 1;
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
            line_id <= 0;
            line_start <= 0;
            busy <= 0;
            done <= 0;
        end
    end

    draw_line_1d #(.CORDW(CORDW)) draw_line_1d_inst (
        .clk,
        .rst,
        .start(line_start),
        .oe,
        .x0(lx0),
        .x1(lx1),
        .x(x),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(line_done)
    );
endmodule
