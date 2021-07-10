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
    output      logic drawing,         // line is drawing
    output      logic complete,        // line complete (remains high)
    output      logic done             // line done (high for one tick)
    );

    logic in_progress = 0;  // calculation in progress (but only output if oe)
    always_comb begin
        drawing = 0;
        if (in_progress && oe) drawing = 1;
    end

    enum {IDLE, DRAW} state;
    always_ff @(posedge clk) begin
        case (state)
            DRAW: begin
                if (oe) begin
                    if (x == x1) begin
                        state <= IDLE;
                        in_progress <= 0;
                        complete <= 1;
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
                    in_progress <= 1;
                    complete <= 0;
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
            in_progress <= 0;
            complete <= 0;
            done <= 0;
        end
    end
endmodule
