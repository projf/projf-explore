// Project F: Render Mandelbrot Set with Supersampling
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/mandelbrot-set-verilog/

`default_nettype none
`timescale 1ns / 1ps

module render_mandel #(
    parameter CORDW=16,       // signed coordinate width (bits)
    parameter FB_WIDTH=320,   // framebuffer width in pixels
    parameter FB_HEIGHT=180,  // framebuffer height in pixels
    parameter CIDXW=4,        // colour index width (bits)
    parameter FP_WIDTH=25,    // total width of fixed-point number: integer + fractional bits
    parameter FP_INT=4,       // integer bits in fixed-point number
    parameter ITER_MAX=255,   // maximum number of interations
    parameter SUPERSAMPLE=1   // combine multiple samples for each coordinate
    ) (
    input  wire logic clk,                            // clock
    input  wire logic rst,                            // reset
    input  wire logic start,                          // start drawing
    input  wire logic signed [FP_WIDTH-1:0] x_start,  // left x-coordinate
    input  wire logic signed [FP_WIDTH-1:0] y_start,  // top y-coordinate
    input  wire logic signed [FP_WIDTH-1:0] step,     // coordinate step
    output      logic signed [CORDW-1:0] x,           // horizontal draw position
    output      logic signed [CORDW-1:0] y,           // vertical draw position
    output      logic [CIDXW-1:0] cidx,               // pixel colour
    output      logic drawing,                        // actively drawing
    output      logic done                            // drawing is complete (high for one tick)
    );

    localparam ITERW=$clog2(ITER_MAX);  // maximum iteration width (bits)
    localparam SF = 2.0**-(FP_WIDTH-FP_INT);  // scale factor for debugging messages

    // function coordinates
    logic signed [FP_WIDTH-1:0] fx, fy;
    logic signed [FP_WIDTH-1:0] fx_00, fx_01, fx_10, fx_11;
    logic signed [FP_WIDTH-1:0] fy_00, fy_01, fy_10, fy_11;

    // control signals
    logic calc_start, calc_done;
    logic calc_done_00w, calc_done_01w, calc_done_10w, calc_done_11w;  // calc done wires
    logic calc_done_00r, calc_done_01r, calc_done_10r, calc_done_11r;  // registered calc done

    // iterations
    logic [ITERW-1:0] iter, iter_00, iter_01, iter_10, iter_11;

    localparam COLR_CNT = 2**CIDXW;  // number of colours
    logic [$clog2(COLR_CNT)-1:0] colr;
    always_comb begin
        if (SUPERSAMPLE) begin
            iter = (iter_00 + iter_01 + iter_10 + iter_11) / 4;  // mean of four samples
        end else begin
            iter = iter_00;  // one sample
        end
        colr = iter[ITERW-1-:CIDXW];
    end

    // calculation state machine
    enum {IDLE, INIT, CALC, NEXT, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin
                state <= CALC;
                calc_start <= 1;
                // register sample coordinates
                fx_00 <= fx - (step>>>2);
                fx_01 <= fx - (step>>>2);
                fx_10 <= fx + (step>>>2);
                fx_11 <= fx + (step>>>2);
                fy_00 <= fy - (step>>>2);
                fy_01 <= fy + (step>>>2);
                fy_10 <= fy - (step>>>2);
                fy_11 <= fy + (step>>>2);
            end
            CALC: begin
                calc_start <= 0;
                if (calc_done) begin
                    state <= NEXT;
                    if (iter == ITER_MAX) cidx <= 'h00;
                    else cidx <= (colr == 0) ? 1 : colr;
                end
            end
            NEXT: begin
                if (x == FB_WIDTH-1) begin  // last pixel on line?
                    if (y == FB_HEIGHT-1) begin  // last pixel in buffer?
                        state <= DONE;
                        drawing <= 0;
                    end else begin
                        x <= 0;
                        fx <= x_start;
                        y <= y + 1;
                        fy <= fy + step;
                        state <= INIT;
                    end
                end else begin
                    x <= x + 1;
                    fx <= fx + step;
                    state <= INIT;
                end
            end
            DONE: begin
                state <= IDLE;
                $strobe("       complete: (%f,%f)", $itor(fx)*SF, $itor(fy)*SF);
            end
            default: if (start) begin  // IDLE
                state <= INIT;
                x <= 0;
                y <= 0;
                fx <= x_start;
                fy <= y_start;
                drawing <= 1;
                $strobe("Render start   : (%f,%f)  step: %f  iter max: %d", $itor(fx)*SF, $itor(fy)*SF, $itor(step)*SF, ITER_MAX);
            end
        endcase
        if (rst) state <= IDLE;
    end

    // determine when all calculations are complete
    always_comb calc_done = calc_done_00r && calc_done_01r && calc_done_10r && calc_done_11r;
    always_ff @(posedge clk) begin  // register calculation completion for each function instance
        if (state == CALC) begin
            if (calc_done_00r == 0) calc_done_00r <= calc_done_00w;
            if (calc_done_01r == 0) calc_done_01r <= calc_done_01w;
            if (calc_done_10r == 0) calc_done_10r <= calc_done_10w;
            if (calc_done_11r == 0) calc_done_11r <= calc_done_11w;
        end else begin
            calc_done_00r <= 0;
            calc_done_01r <= 0;
            calc_done_10r <= 0;
            calc_done_11r <= 0;
        end
    end

    // function to render (top-left sample)
    mandelbrot #(
        .FP_WIDTH(FP_WIDTH),
        .FP_INT(FP_INT),
        .ITER_MAX(ITER_MAX)
    ) mandelbrot_inst_00 (
        .clk,
        .rst,
        .start(calc_start),
        .re(fx_00),
        .im(fy_00),
        .iter(iter_00),
        /* verilator lint_off PINCONNECTEMPTY */
        .calculating(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(calc_done_00w)
    );

    // function to render (bottom-left sample)
    mandelbrot #(
        .FP_WIDTH(FP_WIDTH),
        .FP_INT(FP_INT),
        .ITER_MAX(ITER_MAX)
    ) mandelbrot_inst_01 (
        .clk,
        .rst,
        .start(calc_start),
        .re(fx_01),
        .im(fy_01),
        .iter(iter_01),
        /* verilator lint_off PINCONNECTEMPTY */
        .calculating(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(calc_done_01w)
    );

    // function to render (bottom-right sample)
    mandelbrot #(
        .FP_WIDTH(FP_WIDTH),
        .FP_INT(FP_INT),
        .ITER_MAX(ITER_MAX)
    ) mandelbrot_inst_10 (
        .clk,
        .rst,
        .start(calc_start),
        .re(fx_10),
        .im(fy_10),
        .iter(iter_10),
        /* verilator lint_off PINCONNECTEMPTY */
        .calculating(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(calc_done_10w)
    );

    // function to render (top-right sample)
    mandelbrot #(
        .FP_WIDTH(FP_WIDTH),
        .FP_INT(FP_INT),
        .ITER_MAX(ITER_MAX)
    ) mandelbrot_inst_11 (
        .clk,
        .rst,
        .start(calc_start),
        .re(fx_11),
        .im(fy_11),
        .iter(iter_11),
        /* verilator lint_off PINCONNECTEMPTY */
        .calculating(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(calc_done_11w)
    );

    always_comb done = (state == DONE);
endmodule
