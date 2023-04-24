// Project F: Animated Shapes - Render Coloured Square (4-bit 320x180)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/animated-shapes/

`default_nettype none
`timescale 1ns / 1ps

module render_square_colr #(
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

    localparam QS =  64;  // square size
    localparam SP =   1;  // speed pixels/frame
    localparam BW = 320;  // bounce width
    localparam BH = 180;  // bounce height
    localparam COLR_CHANGE = 12;  // change colour every N draws

    logic [$clog2(COLR_CHANGE)-1:0] cnt_colr;

    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1;  // shape coords
    logic dx, dy;  // shape direction: 0 is right/down
    logic draw_start, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;

                // horizontal position
                if (vx0 >= BW - (QS + SP)) begin  // right edge
                    dx <= 1;
                    vx0 <= vx0 - SP;
                end else if (vx0 < SP) begin  // left edge
                    dx <= 0;
                    vx0 <= vx0 + SP;
                end else vx0 <= (dx) ? vx0 - SP : vx0 + SP;

                // vertical position
                if (vy0 >= BH - (QS + SP)) begin  // bottom edge
                    dy <= 1;
                    vy0 <= vy0 - SP;
                end else if (vy0 < SP) begin  // top edge
                    dy <= 0;
                    vy0 <= vy0 + SP;
                end else vy0 <= (dy) ? vy0 - SP : vy0 + SP;

                // colour change
                if (cnt_colr == COLR_CHANGE-1) begin
                    cnt_colr <= 0;
                    cidx <= cidx + 1;
                end else cnt_colr <= cnt_colr + 1;
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) state <= DONE;
            end
            DONE: state <= IDLE;
            default: if (start) state <= INIT;  // IDLE
        endcase
        if (rst) state <= IDLE;
    end

    always_comb begin
        vx1 = vx0 + QS;
        vy1 = vy0 + QS;
    end

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
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
