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
    input  wire logic signed [CORDW-1:0] x0,  // vertex 0 - horizontal position
    input  wire logic signed [CORDW-1:0] y0,  // vertex 0 - vertical position
    input  wire logic signed [CORDW-1:0] x1,  // vertex 2 - horizontal position
    input  wire logic signed [CORDW-1:0] y1,  // vertex 2 - vertical position
    output      logic signed [CORDW-1:0] x,   // horizontal drawing position
    output      logic signed [CORDW-1:0] y,   // vertical drawing position
    output      logic drawing,         // rectangle is drawing
    output      logic done             // rectangle complete (high for one tick)
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

    // line coordinates - horizontal lines, so only one y-value
    logic signed [CORDW-1:0] lx0, lx1, ly;

    enum {IDLE, INIT, DRAW} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk) begin
        line_start <= 0;
        done <= 0;
        case (state)
            INIT: begin  // register coordinates
                // x-coordinates don't change for a given filled rectangle
                lx0 <= (x0 > x1) ? x1 : x0;  // draw left-to-right
                lx1 <= (x0 > x1) ? x0 : x1;
                ly <= y0s + line_id;  // vertical position
                state <= DRAW;
                line_start <= 1;
            end
            DRAW: begin
                if (line_done) begin
                    if (ly == y1s) begin
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        line_id <= line_id + 1;
                        state <= INIT;
                    end
                end
            end
            default: begin  // IDLE
                if (start) begin
                    line_id <= 0;
                    state <= INIT;
                end
            end
        endcase

        if (rst) begin
            line_id <= 0;
            line_start <= 0;
            done <= 0;
            state <= IDLE;
        end
    end

    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk,
        .rst,
        .start(line_start),
        .oe,
        .x0(lx0),
        .y0(ly),
        .x1(lx1),
        .y1(ly),
        .x,
        .y,
        .drawing,
        .done(line_done)
    );
endmodule
