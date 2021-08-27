// Project F Library - Draw Circle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

// Based on algorithm from The Beauty of Bresenham's Algorithm by Alois Zingl
// http://members.chello.at/~easyfilter/bresenham.html

`default_nettype none
`timescale 1ns / 1ps

module draw_circle #(parameter CORDW=16) (  // signed coordinate width
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
    logic [1:0] quadrant;  // circle quadrant

    // draw state machine
    enum {IDLE, CALC_Y, CALC_X, DRAW} state;
    always_ff @(posedge clk) drawing <= (state == DRAW && oe);  // 1 cycle delay in draw

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
                state <= DRAW;
                /* verilator lint_off WIDTH */
                if (err_tmp > xa || err > ya) begin
                    xa <= xa + 1;
                    err <= err + 2 * (xa + 1) + 1;
                end
                /* verilator lint_on WIDTH */
            end
            DRAW: begin
                if (oe) begin
                    case (quadrant)
                        2'b00: begin  //   I Quadrant (+x +y)
                            x <= x0 - xa;
                            y <= y0 + ya;
                        end
                        2'b01: begin  //  II Quadrant (-x +y)
                            x <= x0 - ya;
                            y <= y0 - xa;
                        end
                        2'b10: begin  // III Quadrant (-x -y)
                            x <= x0 + xa;
                            y <= y0 - ya;
                        end
                        2'b11: begin  //  IV Quadrant (+x -y)
                            state <= CALC_Y;
                            x <= x0 + ya;
                            y <= y0 + xa;
                        end
                    endcase
                    quadrant <= quadrant + 1;  // next quadrant
                end
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= CALC_Y;
                    busy <= 1;
                    xa <= -r0;
                    ya <= 0;
                    err <= 2 - (2 * r0);
                    quadrant <= 0;
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
        end
    end
endmodule
