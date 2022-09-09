// Project F: Lines and Triangles - Render Cube (4-bit 320x180)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/lines-and-triangles/

`default_nettype none
`timescale 1ns / 1ps

module render_cube #(
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
                        vx0 <= 130; vy0 <=  60; vx1 <= 230; vy1 <=  60;
                    end
                    'd1: begin
                        vx0 <= 230; vy0 <=  60; vx1 <= 230; vy1 <= 160;
                    end
                    'd2: begin
                        vx0 <= 230; vy0 <= 160; vx1 <= 130; vy1 <= 160;
                    end
                    'd3: begin
                        vx0 <= 130; vy0 <= 160; vx1 <= 130; vy1 <=  60;
                    end
                    'd4: begin
                        vx0 <= 130; vy0 <= 160; vx1 <=  90; vy1 <= 120;
                    end
                    'd5: begin
                        vx0 <=  90; vy0 <= 120; vx1 <=  90; vy1 <=  20;
                    end
                    'd6: begin
                        vx0 <=  90; vy0 <=  20; vx1 <= 130; vy1 <=  60;
                    end
                    'd7: begin
                        vx0 <=  90; vy0 <=  20; vx1 <= 190; vy1 <=  20;
                    end
                    default: begin  // line_id=8
                        vx0 <= 190; vy0 <=  20; vx1 <= 230; vy1 <=  60;
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
