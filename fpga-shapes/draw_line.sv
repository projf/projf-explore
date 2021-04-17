// Project F: FPGA Shapes - Draw Line
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_line #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start line drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0,  // point 0 - horizontal position
    input  wire logic signed [CORDW-1:0] y0,  // point 0 - vertical position
    input  wire logic signed [CORDW-1:0] x1,  // point 1 - horizontal position
    input  wire logic signed [CORDW-1:0] y1,  // point 1 - vertical position
    output      logic signed [CORDW-1:0] x,   // horizontal drawing position
    output      logic signed [CORDW-1:0] y,   // vertical drawing position
    output      logic drawing,         // line is drawing
    output      logic done             // line complete (high for one tick)
    );

    // line properties
    logic right, swap;  // drawing direction
    logic signed [CORDW-1:0] xa, ya;  // starting point
    logic signed [CORDW-1:0] xb, yb;  // ending point
    always_comb begin
        swap = (y0 > y1);  // swap points if y0 is below y1
        xa = swap ? x1 : x0;
        xb = swap ? x0 : x1;
        ya = swap ? y1 : y0;
        yb = swap ? y0 : y1;
        right = (xa < xb);  // draw right to left?
    end

    // error values
    logic signed [CORDW:0] err, derr;  // a bit wider as signed
    logic signed [CORDW:0] dx, dy;
    logic movx, movy;  // horizontal or vertical move required
    always_comb begin
        movx = (2*err >= dy);
        movy = (2*err <= dx);
        derr = movx ? dy : 0;
        if (movy) derr = derr + dx;
    end

    logic in_progress = 0;  // calculation in progress (but only output if oe)
    always_comb begin
        drawing = 0;
        if (in_progress && oe) drawing = 1;
    end

    enum {IDLE, INIT, DRAW} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk) begin
        case (state)
            DRAW: begin
                if (oe) begin
                    if (x == xb && y == yb) begin
                        in_progress <= 0;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        if (movx) x <= right ? x + 1 : x - 1;
                        if (movy) y <= y + 1;  // always down
                        err <= err + derr;
                    end
                end
            end
            INIT: begin
                err <= dx + dy;
                x <= xa;
                y <= ya;
                in_progress <= 1;
                state <= DRAW;
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    dx <= right ? xb - xa : xa - xb;  // dx = abs(xb - xa)
                    dy <= ya - yb;  // dy = -abs(yb - ya)
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
