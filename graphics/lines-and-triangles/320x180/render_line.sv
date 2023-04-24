// Project F: Lines and Triangles - Render Line (4-bit 320x180)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/lines-and-triangles/

`default_nettype none
`timescale 1ns / 1ps

module render_line #(
    parameter CORDW=16,  // signed coordinate width (bits)
    parameter CIDXW=4,   // colour index width (bits)
    parameter SCALE=1    // drawing scale: 1=320x180, 2=640x360, 4=1280x720
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

    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1;  // line coords
    logic draw_start, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates and colour
                vx0 <=  70; vy0 <=   0;
                vx1 <= 249; vy1 <= 179;
                cidx <= 'h3;  // colour index
                draw_start <= 1;
                state <= DRAW;
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) state <= DONE;
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
