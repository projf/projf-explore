// Project F: Lines and Triangles - Draw Triangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_triangle #(parameter CORDW=10) (  // FB coord width in bits
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start triangle drawing
    input  wire logic oe,              // output enable
    input  wire logic [CORDW-1:0] x0,  // vertex 0 - horizontal position
    input  wire logic [CORDW-1:0] y0,  // vertex 0 - vertical position
    input  wire logic [CORDW-1:0] x1,  // vertex 1 - horizontal position
    input  wire logic [CORDW-1:0] y1,  // vertex 1 - vertical position
    input  wire logic [CORDW-1:0] x2,  // vertex 2 - horizontal position
    input  wire logic [CORDW-1:0] y2,  // vertex 2 - vertical position
    output      logic [CORDW-1:0] x,   // horizontal drawing position
    output      logic [CORDW-1:0] y,   // vertical drawing position
    output      logic drawing,         // triangle is drawing
    output      logic done             // triangle complete (high for one tick)
    );

    // we're either idle or drawing
    enum {IDLE, DRAW} state;

    localparam CNT_LINE = 3;  // triangle has three lines
    logic [$clog2(CNT_LINE)-1:0] line_id;  // current line
    logic line_start;  // start drawing line
    logic line_done;   // finished drawing current line?

    always @(posedge clk) begin
        line_start <= 0;
        case (state)
            DRAW: begin
                if (line_done) begin
                    /* verilator lint_off WIDTH */
                    if (line_id == CNT_LINE-1) begin
                    /* verilator lint_on WIDTH */
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        line_id <= line_id + 1;
                        line_start <= 1;
                    end
                end
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    line_id <= 0;
                    line_start <= 1;
                    state <= DRAW;
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

    // line coordinates
    logic [CORDW-1:0] lx0, ly0;  // current line start position
    logic [CORDW-1:0] lx1, ly1;  // current line end position

    always_comb begin
        if (line_id == 2'd0) begin  // (x0,y0) -> (x1,y1)
            lx0 = x0; ly0 = y0;
            lx1 = x1; ly1 = y1;
        end else if (line_id == 2'd1) begin  // (x1,y1) -> (x2,y2)
            lx0 = x1; ly0 = y1;
            lx1 = x2; ly1 = y2;
        end else begin  // (x2,y2) -> (x0,y0)
            lx0 = x2; ly0 = y2;
            lx1 = x0; ly1 = y0;
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
        .done(line_done)
    );
endmodule
