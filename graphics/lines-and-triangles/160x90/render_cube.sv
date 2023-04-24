// Project F: Lines and Triangles - Render Cube (2-bit 160x90)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/lines-and-triangles/

`default_nettype none
`timescale 1ns / 1ps

module render_cube #(
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

    localparam LINE_CNT=9;  // number of lines to draw
    logic [$clog2(LINE_CNT):0] line_id;  // line identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1;  // line coords
    logic draw_start, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                cidx <= 'h2;  // colour index
                case (line_id)
                    'd0: begin
                        vx0 <=  65; vy0 <=  30; vx1 <= 115; vy1 <=  30;
                    end
                    'd1: begin
                        vx0 <= 115; vy0 <=  30; vx1 <= 115; vy1 <=  80;
                    end
                    'd2: begin
                        vx0 <= 115; vy0 <=  80; vx1 <=  65; vy1 <=  80;
                    end
                    'd3: begin
                        vx0 <=  65; vy0 <=  80; vx1 <=  65; vy1 <=  30;
                    end
                    'd4: begin
                        vx0 <=  65; vy0 <=  80; vx1 <=  45; vy1 <=  60;
                    end
                    'd5: begin
                        vx0 <=  45; vy0 <=  60; vx1 <=  45; vy1 <=  10;
                    end
                    'd6: begin
                        vx0 <=  45; vy0 <=  10; vx1 <=  65; vy1 <=  30;
                    end
                    'd7: begin
                        vx0 <=  45; vy0 <=  10; vx1 <=  95; vy1 <=  10;
                    end
                    default: begin  // shape_id=8
                        vx0 <=  95; vy0 <=  10; vx1 <= 115; vy1 <=  30;
                    end
                endcase
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) begin
                    if (line_id == LINE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        line_id <= line_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: state <= DONE;
            default: if (start) state <= INIT;  // IDLE
        endcase
        if (rst) state <= IDLE;
    end

    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk,
        .rst,
        .start(draw_start),
        .oe,
        .x0(vx0 * SCALE),
        .y0(vy0 * SCALE),
        .x1(vx1 * SCALE),
        .y1(vy1 * SCALE),
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
