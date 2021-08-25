// Project F Library - Draw Rectangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_rectangle #(parameter CORDW=16) (  // signed coordinate width
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

    logic [1:0] line_id;  // current line (0, 1, 2, or 3)
    logic line_start;     // start drawing line
    logic line_done;      // finished drawing current line?

    // current line coordinates
    logic signed [CORDW-1:0] lx0, ly0;  // point 0 position
    logic signed [CORDW-1:0] lx1, ly1;  // point 1 position

    // draw state machine
    enum {IDLE, INIT, DRAW} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates
                state <= DRAW;
                line_start <= 1;
                if (line_id == 2'd0) begin  // (x0,y0) (x1,y0)
                    lx0 <= x0; ly0 <= y0;
                    lx1 <= x1; ly1 <= y0;
                end else if (line_id == 2'd1) begin  // (x1,y0) (x1,y1)
                    lx0 <= x1; ly0 <= y0;
                    lx1 <= x1; ly1 <= y1;
                end else if (line_id == 2'd2) begin  // (x1,y1) (x0,y1)
                    lx0 <= x1; ly0 <= y1;
                    lx1 <= x0; ly1 <= y1;
                end else begin  // (x0,y1) (x0,y0)
                    lx0 <= x0; ly0 <= y1;
                    lx1 <= x0; ly1 <= y0;
                end
            end
            DRAW: begin
                line_start <= 0;
                if (line_done) begin
                    if (line_id == 3) begin  // final line
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

    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk,
        .rst,
        .start(line_start),
        .oe,
        .x0(lx0),
        .y0(ly0),
        .x1(lx1),
        .y1(ly1),
        .x,
        .y,
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(line_done)
    );
endmodule
