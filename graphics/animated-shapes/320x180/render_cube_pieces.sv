// Project F: Animated Shapes - Render Cube Pieces (4-bit 320x180)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/animated-shapes/

`default_nettype none
`timescale 1ns / 1ps

module render_cube_pieces #(
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

    localparam SHAPE_CNT=6;  // number of shapes to draw
    logic [$clog2(SHAPE_CNT)-1:0] shape_id;  // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic draw_start, draw_done;  // drawing signals

    // animate triangle coordinates
    localparam MAX_OFFS   = 160;  // maximum pixels to move
    localparam WAIT_STEPS = 120;  // steps to wait before moving
    logic [CORDW-1:0] offs;       // animation offset
    logic [$clog2(WAIT_STEPS)-1:0] cnt_wait;
    logic dir;  // direction: 0 is increasing offset
    enum {MOVE, WAIT} anim_state;
    always_ff @(posedge clk) begin
        if (start) begin
            case (anim_state)
                MOVE: begin
                    if (offs < MAX_OFFS/8) begin  // start slow
                        offs <= (!dir) ? offs + 1 : offs - 1;
                    end else begin
                        offs <= (!dir) ? offs + 3 : offs - 3;
                    end

                    if ((!dir && offs >= MAX_OFFS-1) || (dir && offs <= 1)) begin
                        anim_state <= WAIT;
                        cnt_wait <= 0;
                    end
                end
                default: begin  // anim_state=WAIT
                    if (cnt_wait == WAIT_STEPS-1) begin
                        anim_state <= MOVE;
                        dir <= ~dir;  // change direction
                    end else cnt_wait <= cnt_wait + 1;
                end
            endcase
        end
        if (rst) begin
            anim_state <= WAIT;
            cnt_wait <= 0;
            dir <= 1;  // otherwise first move doesn't work
        end
    end

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                case (shape_id)
                    'd0: begin  // moves in from right - DONE
                        vx0 <= 160 + offs; vy0 <=  90;
                        vx1 <= 240 + offs; vy1 <=  90;
                        vx2 <= 240 + offs; vy2 <= 170;
                        cidx <= (offs == 0) ? 'h1 : 'h2;  // pink
                    end
                    'd1: begin  // moves in from bottom-right
                        vx0 <= 160 + offs; vy0 <=  90 + offs;
                        vx1 <= 240 + offs; vy1 <= 170 + offs;
                        vx2 <= 160 + offs; vy2 <= 170 + offs;
                        cidx <= (offs == 0) ? 'h1 : 'h2;  // pink
                    end
                    'd2: begin  // moves in from bottom-left
                        vx0 <= 160 - offs; vy0 <=  90 + offs;
                        vx1 <= 120 - offs; vy1 <= 140 + offs;
                        vx2 <= 160 - offs; vy2 <= 170 + offs;
                        cidx <= (offs == 0) ? 'hA : 'h8;  // green
                    end
                    'd3: begin  // moves in from left
                        vx0 <= 120 - offs; vy0 <=  60;
                        vx1 <= 160 - offs; vy1 <=  90;
                        vx2 <= 120 - offs; vy2 <= 140;
                        cidx <= (offs == 0) ? 'hA : 'h8;  // green
                    end
                    'd4: begin  // moves in from top
                        vx0 <= 120; vy0 <=  60 - offs;
                        vx1 <= 200; vy1 <=  60 - offs;
                        vx2 <= 160; vy2 <=  90 - offs;
                        cidx <= (offs == 0) ? 'hB : 'hC;  // blue
                    end
                    default: begin  // shape_id=5 moves in from top-right
                        vx0 <= 200 + offs; vy0 <=  60 - offs;
                        vx1 <= 160 + offs; vy1 <=  90 - offs;
                        vx2 <= 240 + offs; vy2 <=  90 - offs;
                        cidx <= (offs == 0) ? 'hB : 'hC;  // blue
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
            DONE: state <= IDLE;
            default: if (start) begin
                state <= INIT;  // IDLE
                shape_id <= 0;
            end
        endcase
        if (rst) begin
            state <= IDLE;
            shape_id <= 0;
        end
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
