// Project F Library - Draw Filled Circle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

// Based on algorithm from The Beauty of Bresenham's Algorithm by Alois Zingl
// http://members.chello.at/~easyfilter/bresenham.html

`default_nettype none
`timescale 1ns / 1ps

module draw_circle_fill #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start line drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0, y0,  // centre point
    input  wire logic signed [CORDW-1:0] r0,      // radius
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    // internal variables
    logic signed [CORDW-1:0] xa, ya;  // position relative to circle centre point
    logic signed [CORDW+1:0] err, err_tmp;  // error values (4x as wide as coords)

    // draw state machine
    enum {IDLE, CALC_Y, CALC_X, CORDS_DOWN, LINE_DOWN, CORDS_UP, LINE_UP} state;
 
    // horizontal line coordinates
    logic signed [CORDW-1:0] lx0, lx1;
    logic line_start;  // start drawing line
    logic line_done;   // finished drawing current line?

    always_ff @(posedge clk) begin
        case (state)
            CALC_Y: begin
                if (xa == 0) begin
                    state <= IDLE;
                    busy <= 0;
                    done <= 1;
                end else begin
                    state <= CALC_X;
                    err_tmp <= err;  // save existing error for next step
                    /* verilator lint_off WIDTH */
                    if (err <= ya) begin
                        ya <= ya + 1;
                        err <= err + 2 * (ya + 1) + 1;
                    end
                    /* verilator lint_on WIDTH */
                end
            end
            CALC_X: begin
                state <= CORDS_DOWN;
                /* verilator lint_off WIDTH */
                if (err_tmp > xa || err > ya) begin
                    xa <= xa + 1;
                    err <= err + 2 * (xa + 1) + 1;
                end
                /* verilator lint_on WIDTH */
            end
            CORDS_DOWN: begin
                state <= LINE_DOWN;
                y   <= y0 + ya;  // horizontal line (common y-value)
                lx0 <= x0 + xa;  // draw left-to-right
                lx1 <= x0 - xa;
                line_start <= 1;
            end
            LINE_DOWN: begin
                if (line_done) state <= CORDS_UP;
                line_start <= 0;
            end
            CORDS_UP: begin
                state <= LINE_UP;
                y <= y0 - ya;  // lx0 and lx1 are the same as CORDS_DOWN
                line_start <= 1;
            end
            LINE_UP: begin
                if (line_done) state <= CALC_Y;
                line_start <= 0;
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= CORDS_DOWN;
                    busy <= 1;
                    xa <= -r0;
                    ya <= 0;
                    err <= 2 - (2 * r0);
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
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
