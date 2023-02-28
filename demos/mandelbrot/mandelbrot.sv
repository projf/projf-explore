// Project F: Fixed-Point Mandelbrot Set
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/mandelbrot-set-verilog/

// Is (re,im) in the Mandelbrot set?

`default_nettype none
`timescale 1ns / 1ps

module mandelbrot #(
    parameter FP_WIDTH=25,   // total width of fixed-point number: integer + fractional bits
    parameter FP_INT=4,      // integer bits in fixed-point number
    parameter ITER_MAX=255,  // maximum number of interations
    parameter ITERW=$clog2(ITER_MAX+1)  // maximum iteration width (bits)
    ) (
    input  wire logic clk,    // clock
    input  wire logic rst,    // reset
    input  wire logic start,  // start calculation
    input  wire logic signed [FP_WIDTH-1:0] re, im,  // coordinate
    output      logic [ITERW-1:0] iter,  // iterations
    output      logic calculating,  // calculation in progress
    output      logic done  // calculation complete (high for one tick)
    );

    // intermediate values
    logic signed [FP_WIDTH-1:0] x0, y0, x2, y2, x, y;

    // fixed-point multiplication module
    logic signed [FP_WIDTH-1:0] mul_a, mul_b, mul_val, mul_val_p;
    logic mul_start, mul_done;
    mul #(.WIDTH(FP_WIDTH), .FBITS(FP_WIDTH - FP_INT)) mul_inst (
        .clk,
        .rst,
        .start(mul_start),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(mul_done),
        /* verilator lint_off PINCONNECTEMPTY */
        .valid(),
        .ovf(),
        /* verilator lint_on PINCONNECTEMPTY */
        .a(mul_a),
        .b(mul_b),
        .val(mul_val)
    );

    /* verilator lint_off UNUSED */
    logic signed [FP_WIDTH-1:0] xt, xy2;  // temporaries
    /* verilator lint_on UNUSED */

    enum {IDLE, STEP1, STEP2, STEP2A, STEP3, STEP4} state;
    always_ff @(posedge clk) begin
        done <= 0;
        case (state)
            STEP1: begin
                if ((xy2[FP_WIDTH-1-:FP_INT] <= 4) && (iter < ITER_MAX)) begin
                    state <= STEP2;
                    mul_a <= x;
                    mul_b <= y;
                    mul_start <= 1;
                end else begin
                    state <= IDLE;
                    calculating <= 0;
                    done <= 1;
                end
            end
            STEP2: begin
                mul_start <= 0;
                if (mul_done) begin  // register results
                    state <= STEP2A;
                    mul_val_p <= mul_val;
                    xt <= x2 - y2 + x0;
                end
            end
            STEP2A: begin
                state <= STEP3;
                y <= 2 * mul_val_p + y0;
                x <= xt;
                mul_a <= xt;
                mul_b <= xt;
                mul_start <= 1;
            end
            STEP3: begin
                mul_start <= 0;
                if (mul_done) begin
                    state <= STEP4;
                    x2 <= mul_val;
                    mul_a <= y;
                    mul_b <= y;
                    mul_start <= 1;
                end
            end
            STEP4: begin
                mul_start <= 0;
                if (mul_done) begin
                    state <= STEP1;
                    y2 <= mul_val;
                    xy2 <= x2 + mul_val;
                    iter <= iter + 1;
                end
            end
            default: if (start) begin  // IDLE
                state <= STEP1;
                calculating <= 1;
                x0 <= re;  // register coordinates
                y0 <= im;
                x <= 0;
                y <= 0;
                x2 <= 0;
                y2 <= 0;
                xy2 <= 0;
                xt <= 0;
                iter <= 0;
            end
        endcase
        if (rst) state <= IDLE;
    end
endmodule
