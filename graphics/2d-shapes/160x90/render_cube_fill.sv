// Project F: 2D Shapes - Render Filled Cube (2-bit 160x90)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-shapes/

`default_nettype none
`timescale 1ns / 1ps

module render_cube_fill #(
    parameter CORDW=16,  // signed coordinate width (bits)
    parameter CIDXW=2,   // colour index width (bits)
    parameter SCALE=1    // drawing scale: 1=160x90, 2=320x180, 4=640x360, 8=1280x720
    ) (
    input  wire logic clk,    // clock
    input  wire logic rst,    // reset
    input  wire logic oe,     // output enable
    input  wire logic start,  // start drawing
    output      logic signed [CORDW-1:0] x,  // horizontal draw position
    output      logic signed [CORDW-1:0] y,  // vertical draw position
    output      logic [CIDXW-1:0] cidx,  // pixel colour
    output      logic drawing,  // actively drawing
    output      logic done      // drawing is complete (high for one tick)
    );

    localparam SHAPE_CNT=6;  // number of shapes to draw
    logic [$clog2(SHAPE_CNT)-1:0] shape_id;  // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic draw_start, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                case (shape_id)
                    'd0: begin
                        vx0 <=  65; vy0 <=  30;
                        vx1 <= 115; vy1 <=  30;
                        vx2 <= 115; vy2 <=  80;
                        cidx <= 'h1;  // colour index
                    end
                    'd1: begin
                        vx0 <=  65; vy0 <=  30;
                        vx1 <= 115; vy1 <=  80;
                        vx2 <=  65; vy2 <=  80;
                        cidx <= 'h2;
                    end
                    'd2: begin
                        vx0 <=  65; vy0 <=  30;
                        vx1 <=  45; vy1 <=  60;
                        vx2 <=  65; vy2 <=  80;
                        cidx <= 'h1;
                    end
                    'd3: begin
                        vx0 <=  45; vy0 <=  10;
                        vx1 <=  65; vy1 <=  30;
                        vx2 <=  45; vy2 <=  60;
                        cidx <= 'h2;
                    end
                    'd4: begin
                        vx0 <=  45; vy0 <=  10;
                        vx1 <=  95; vy1 <=  10;
                        vx2 <=  65; vy2 <=  30;
                        cidx <= 'h1;
                    end
                    default: begin  // shape_id=5
                        vx0 <=  95; vy0 <=  10;
                        vx1 <=  65; vy1 <=  30;
                        vx2 <= 115; vy2 <=  30;
                        cidx <= 'h2;
                    end
                endcase
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) begin
                    if (shape_id == SHAPE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        shape_id <= shape_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: state <= DONE;
            default: if (start) state <= INIT;  // IDLE
        endcase
        if (rst) state <= IDLE;
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk,
        .rst,
        .start(draw_start),
        .oe,
        .x0(vx0 * SCALE),
        .y0(vy0 * SCALE),
        .x1(vx1 * SCALE),
        .y1(vy1 * SCALE),
        .x2(vx2 * SCALE),
        .y2(vy2 * SCALE),
        .x,
        .y,
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    always_comb done = (state == DONE);
endmodule
