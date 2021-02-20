// Project F: Lines and Triangles - Draw Line
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_line #(parameter CORDW=10) (  // FB coord width in bits
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start line drawing
    input  wire logic oe,              // output enable
    input  wire logic [CORDW-1:0] x0,  // horizontal start position
    input  wire logic [CORDW-1:0] y0,  // vertical start position
    input  wire logic [CORDW-1:0] x1,  // horizontal end position
    input  wire logic [CORDW-1:0] y1,  // vertical end position
    output      logic [CORDW-1:0] x,   // horizontal drawing position
    output      logic [CORDW-1:0] y,   // vertical drawing position
    output      logic drawing,         // line is drawing
    output      logic done             // line complete (high for one tick)
    );

    // "constant" signals (we register these during the INIT state)
    logic signed [CORDW:0] dx, dx_c, dy, dy_c;  // a bit wider as signed
    logic right, right_c, down, down_c;  // drawing direction
    always_comb begin
        right_c = (x0 < x1);
        down_c  = (y0 < y1);
        dx_c = right_c ? x1 - x0 : x0 - x1;  // dx_c =  abs(x1 - x0)
        dy_c = down_c  ? y0 - y1 : y1 - y0;  // dy_y = -abs(y1 - y0)
    end

    // error values
    logic signed [CORDW:0] err, derr;
    logic movx, movy;  // move in x and/or y required
    always_comb begin
        movx = (2*err >= dy);
        movy = (2*err <= dx);
        derr = movx ? dy : 0;
        if (movy) derr = derr + dx;
    end

    logic in_progress = 0;  // drawing calculation in progress
    always_comb begin
        drawing = 0;
        if (in_progress && oe) drawing = 1;
    end

    enum {IDLE, INIT, DRAW} state;
    always @(posedge clk) begin
        case (state)
            DRAW: begin
                if (x == x1 && y == y1) begin
                    in_progress <= 0;
                    done <= 1;
                    state <= IDLE;
                end else if (oe) begin
                    if (movx) x <= right ? x + 1 : x - 1;
                    if (movy) y <= down  ? y + 1 : y - 1;
                    err <= err + derr;
                end
            end
            INIT: begin
                err <= dx + dy;
                x <= x0;
                y <= y0;
                in_progress <= 1;
                state <= DRAW;
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin  // register "constant" signals
                    right <= right_c;
                    down  <= down_c;
                    dx <= dx_c;
                    dy <= dy_c;
                    state <= INIT;
                end
            end
        endcase

        if (rst) begin
            in_progress <= 0;
            done <= 0;
            state <= IDLE;
        end
    end
endmodule
