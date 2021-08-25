// Project F Library - Draw 1D Line (assumes x1 >= x0)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_line_1d #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start line drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0,  // point 0
    input  wire logic signed [CORDW-1:0] x1,  // point 1
    output      logic signed [CORDW-1:0] x,   // drawing position
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    // draw state machine
    enum {IDLE, DRAW} state;
    always_comb drawing = (state == DRAW && oe);

    always_ff @(posedge clk) begin
        case (state)
            DRAW: begin
                if (oe) begin
                    if (x == x1) begin
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        x <= x + 1;
                    end
                end
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= DRAW;
                    x <= x0;
                    busy <= 1;
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
