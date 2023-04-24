// Project F: Animated Shapes - Render Teleport (4-bit 320x180)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/animated-shapes/

`default_nettype none
`timescale 1ns / 1ps

module render_teleport #(
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

    // animation steps
    localparam ANIM_CNT=5;    // five different frames in animation
    localparam ANIM_SPEED=3;  // display each animation step this many times (3==20 FPS)
    logic [$clog2(ANIM_CNT)-1:0] cnt_anim;
    logic [$clog2(ANIM_SPEED)-1:0] cnt_anim_speed;
    logic [CIDXW-1:0] colr_offs;  // colour offset
    always_ff @(posedge clk) begin
        if (start) begin
            /* verilator lint_off WIDTH */
            if (cnt_anim_speed == ANIM_SPEED-1) begin
                if (cnt_anim == ANIM_CNT-1) begin
            /* verilator lint_on WIDTH */
                    cnt_anim <= 0;
                    colr_offs <= colr_offs + 1;
                end else cnt_anim <= cnt_anim + 1;
                cnt_anim_speed <= 0;
            end else cnt_anim_speed <= cnt_anim_speed + 1;
        end
    end

    localparam SHAPE_CNT=8;  // number of shapes to draw
    logic [3:0] shape_id;    // shape identifier
    logic signed [CORDW-1:0] dx0, dy0, dx1, dy1;  // shape coords
    logic draw_start, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                cidx <= colr_offs + shape_id;
                case (shape_id)
                    'd0: begin  // background
                        dx0 <=   0;
                        dy0 <=   0;
                        dx1 <= 319;
                        dy1 <= 179;
                    end
                    'd1: begin  // 12 pixels per anim step
                        dx0 <=  40 - (cnt_anim * 12);
                        dy0 <=   0 - (cnt_anim * 12);
                        dx1 <= 279 + (cnt_anim * 12);
                        dy1 <= 249 + (cnt_anim * 12);
                    end
                    'd2: begin  // 8 pixels per anim step
                        dx0 <=  80 - (cnt_anim * 8);
                        dy0 <=  10 - (cnt_anim * 8);
                        dx1 <= 239 + (cnt_anim * 8);
                        dy1 <= 169 + (cnt_anim * 8);
                    end
                    'd3: begin  // 5 pixels per anim step
                        dx0 <= 105 - (cnt_anim * 5);
                        dy0 <=  35 - (cnt_anim * 5);
                        dx1 <= 214 + (cnt_anim * 5);
                        dy1 <= 144 + (cnt_anim * 5);
                    end
                    'd4: begin  // 4 pixels per anim step
                        dx0 <= 125 - (cnt_anim * 4);
                        dy0 <=  55 - (cnt_anim * 4);
                        dx1 <= 194 + (cnt_anim * 4);
                        dy1 <= 124 + (cnt_anim * 4);
                    end
                    'd5: begin  // 3 pixels per anim step
                        dx0 <= 140 - (cnt_anim * 3);
                        dy0 <=  70 - (cnt_anim * 3);
                        dx1 <= 179 + (cnt_anim * 3);
                        dy1 <= 109 + (cnt_anim * 3);
                    end
                    'd6: begin  // 2 pixels per anim step
                        dx0 <= 150 - (cnt_anim * 2);
                        dy0 <=  80 - (cnt_anim * 2);
                        dx1 <= 169 + (cnt_anim * 2);
                        dy1 <=  99 + (cnt_anim * 2);
                    end
                    default: begin   // shape_id=7: 1 pixel per anim step
                        dx0 <= 155 - (cnt_anim * 1);
                        dy0 <=  85 - (cnt_anim * 1);
                        dx1 <= 164 + (cnt_anim * 1);
                        dy1 <=  94 + (cnt_anim * 1);
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
            default: if (start) begin  // IDLE
                state <= INIT;
                shape_id <= 0;
            end
        endcase
        if (rst) begin
            state <= IDLE;
            shape_id <= 0;
        end
    end

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
        .clk,
        .rst,
        .start(draw_start),
        .oe,
        .x0(dx0 * SCALE),
        .y0(dy0 * SCALE),
        .x1(dx1 * SCALE),
        .y1(dy1 * SCALE),
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
