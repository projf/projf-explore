// Project F Library - Draw Filled Triangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module draw_triangle_fill #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start triangle drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0, y0,  // vertex 0
    input  wire logic signed [CORDW-1:0] x1, y1,  // vertex 1
    input  wire logic signed [CORDW-1:0] x2, y2,  // vertex 2
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    // sorted input vertices
    logic signed [CORDW-1:0] x0s, y0s, x1s, y1s, x2s, y2s;

    // line coordinates
    logic signed [CORDW-1:0] x0a, y0a, x1a, y1a, xa, ya;
    logic signed [CORDW-1:0] x0b, y0b, x1b, y1b, xb, yb;
    logic signed [CORDW-1:0] x0h, x1h, xh;

    // previous y-value for edges
    logic signed [CORDW-1:0] prev_y;

    // previous x-values for horizontal line
    logic signed [CORDW-1:0] prev_xa;
    logic signed [CORDW-1:0] prev_xb;

    // line control signals
    logic oe_a, oe_b, oe_h;
    logic drawing_h;
    logic busy_a, busy_b, busy_h;
    logic b_edge;  // which B edge are we drawing?

    // pipeline completion signals to match coordinates
    logic busy_p1, done_p1;

    // draw state machine
    enum {IDLE, SORT_0, SORT_1, SORT_2, INIT_A, INIT_B0, INIT_B1, INIT_H,
            START_A, START_B, START_H, EDGE, H_LINE, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            SORT_0: begin
                state <= SORT_1;
                if (y0 > y2) begin
                    x0s <= x2;
                    y0s <= y2;
                    x2s <= x0;
                    y2s <= y0;
                end else begin
                    x0s <= x0;
                    y0s <= y0;
                    x2s <= x2;
                    y2s <= y2;
                end
            end
            SORT_1: begin
                state <= SORT_2;
                if (y0s > y1) begin
                    x0s <= x1;
                    y0s <= y1;
                    x1s <= x0s;
                    y1s <= y0s;
                end else begin
                    x1s <= x1;
                    y1s <= y1;
                end
            end
            SORT_2: begin
                state <= INIT_A;
                if (y1s > y2s) begin
                    x1s <= x2s;
                    y1s <= y2s;
                    x2s <= x1s;
                    y2s <= y1s;
                end
            end
            INIT_A: begin
                state <= INIT_B0;
                x0a <= x0s;
                y0a <= y0s;
                x1a <= x2s;
                y1a <= y2s;
                prev_xa <= x0s;
                prev_xb <= x0s;
            end
            INIT_B0: begin
                state <= START_A;
                b_edge <= 0;
                x0b <= x0s;
                y0b <= y0s;
                x1b <= x1s;
                y1b <= y1s;
                prev_y <= y0s;
            end
            INIT_B1: begin
                state <= START_B;  // we don't need to start A again
                b_edge <= 1;
                x0b <= x1s;
                y0b <= y1s;
                x1b <= x2s;
                y1b <= y2s;
                prev_y <= y1s;
            end
            START_A: state <= START_B;
            START_B: state <= EDGE;
            EDGE: begin
                if ((ya != prev_y || !busy_a) && (yb != prev_y || !busy_b)) begin
                    state <= START_H;
                    x0h <= (prev_xa > prev_xb) ? prev_xb : prev_xa;  // always draw...
                    x1h <= (prev_xa > prev_xb) ? prev_xa : prev_xb;  // left to right
                end
            end
            START_H: state <= H_LINE;
            H_LINE: begin
                if (!busy_h) begin
                    prev_y <= yb;  // safe to update previous values once h-line done
                    prev_xa <= xa;
                    prev_xb <= xb;
                    if (!busy_b) begin
                        state <= (busy_a && b_edge == 0) ? INIT_B1 : DONE;
                    end else state <= EDGE;
                end
            end
            DONE: begin
                state <= IDLE;
                done_p1 <= 1;
                busy_p1 <= 0;
            end
            default: begin  // IDLE
                if (start) begin
                    state <= SORT_0;
                    busy_p1 <= 1;
                end
                done_p1 <= 0;
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy_p1 <= 0;
            done_p1 <= 0;
            b_edge <= 0;
        end
    end

    always_comb begin
        oe_a = (state == EDGE && ya == prev_y);
        oe_b = (state == EDGE && yb == prev_y);
        oe_h = oe;
    end

    // register output
    always_ff @(posedge clk) begin
        x <= xh;
        y <= prev_y;
        drawing <= drawing_h;
        busy <= busy_p1;
        done <= done_p1;
    end

    draw_line #(.CORDW(CORDW)) draw_edge_a (
        .clk,
        .rst,
        .start(state == START_A),
        .oe(oe_a),
        .x0(x0a),
        .y0(y0a),
        .x1(x1a),
        .y1(y1a),
        .x(xa),
        .y(ya),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
        .busy(busy_a),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    draw_line #(.CORDW(CORDW)) draw_edge_b (
        .clk,
        .rst,
        .start(state == START_B),
        .oe(oe_b),
        .x0(x0b),
        .y0(y0b),
        .x1(x1b),
        .y1(y1b),
        .x(xb),
        .y(yb),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
        .busy(busy_b),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    draw_line_1d #(.CORDW(CORDW)) draw_h_line (
        .clk,
        .rst,
        .start(state == START_H),
        .oe(oe_h),
        .x0(x0h),
        .x1(x1h),
        .x(xh),
        .drawing(drawing_h),
        .busy(busy_h),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
