// Project F: Castle Drawing - Render Castle
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/castle-drawing/

`default_nettype none
`timescale 1ns / 1ps

module render_castle #(
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

    localparam RBOW_CNT=8;    // number of shapes in rainbow
    localparam SHAPE_CNT=19;  // number of shapes in castle
    logic [$clog2(RBOW_CNT)-1:0] rbow_id;    // rainbow shape identifier
    logic [$clog2(SHAPE_CNT)-1:0] shape_id;  // castle shape identifier

    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic signed [CORDW-1:0] vr0;  // circle radius
    logic signed [CORDW-1:0] x_tri,    y_tri;     // triangle framebuffer coords
    logic signed [CORDW-1:0] x_rect,   y_rect;    // rectangle framebuffer coords
    logic signed [CORDW-1:0] x_circle, y_circle;  // circle framebuffer coords
    logic draw_done;  // combined done signal
    logic draw_start_tri, drawing_tri, draw_done_tri;           // drawing triangle
    logic draw_start_rect, drawing_rect, draw_done_rect;        // drawing rectangle
    logic draw_start_circle, drawing_circle, draw_done_circle;  // drawing circle

    // draw state machine
    enum {IDLE, INIT_RBOW, DRAW_RBOW, INIT_CASTLE, DRAW_CASTLE, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT_RBOW: begin
                state <= DRAW_RBOW;
                draw_start_circle <= 1;
                vx0 <= 368;
                vy0 <= 160;
                vr0 <= 180 - 5 * rbow_id;
                /* verilator lint_off WIDTH */
                cidx <= (rbow_id == RBOW_CNT-1) ? 'h0 : 'h2 + rbow_id;
                /* verilator lint_on WIDTH */
            end
            DRAW_RBOW: begin
                draw_start_circle <= 0;
                if (draw_done) begin
                    /* verilator lint_off WIDTH */
                    if (rbow_id == RBOW_CNT-1) begin
                    /* verilator lint_on WIDTH */
                        state <= INIT_CASTLE;
                    end else begin
                        rbow_id <= rbow_id + 1;
                        state <= INIT_RBOW;
                    end
                end
            end
            INIT_CASTLE: begin  // register coordinates and colour (Sweetie 16 palette)
                state <= DRAW_CASTLE;
                case (shape_id)
                    'd0: begin  // main building
                        draw_start_rect <= 1;
                        vx0 <=  60; vy0 <=  75;
                        vx1 <= 190; vy1 <= 130;
                        cidx <= 'hE;  // dark grey
                    end
                    'd1: begin  // drawbridge
                        draw_start_rect <= 1;
                        vx0 <= 110; vy0 <= 110;
                        vx1 <= 140; vy1 <= 130;
                        cidx <= 'hF;  // blue-grey
                    end
                    'd2: begin  // drawbridge arch
                        draw_start_circle <= 1;
                        vx0 <= 125; vy0 <= 110;
                        vr0 <=  15;
                        cidx <= 'hF;  // blue-grey
                    end
                    'd3: begin  // left tower
                        draw_start_rect <= 1;
                        vx0 <=  40; vy0 <=  50;
                        vx1 <=  60; vy1 <= 130;
                        cidx <= 'hE;  // dark grey
                    end
                    'd4: begin  // middle tower
                        draw_start_rect <= 1;
                        vx0 <= 110; vy0 <=  45;
                        vx1 <= 140; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    'd5: begin  // right tower
                        draw_start_rect <= 1;
                        vx0 <= 190; vy0 <=  50;
                        vx1 <= 210; vy1 <= 130;
                        cidx <= 'hE;  // dark grey
                    end
                    'd6: begin  // left roof
                        draw_start_tri <= 1;
                        vx0 <=  50; vy0 <=  35;
                        vx1 <=  65; vy1 <=  50;
                        vx2 <=  35; vy2 <=  50;
                        cidx <= 'h2;  // red
                    end
                    'd7: begin  // middle roof
                        draw_start_tri <= 1;
                        vx0 <= 125; vy0 <=  25;
                        vx1 <= 145; vy1 <=  45;
                        vx2 <= 105; vy2 <=  45;
                        cidx <= 'h2;  // red
                    end
                    'd8: begin  // right roof
                        draw_start_tri <= 1;
                        vx0 <= 200; vy0 <=  35;
                        vx1 <= 215; vy1 <=  50;
                        vx2 <= 185; vy2 <=  50;
                        cidx <= 'h2;  // red
                    end
                    'd9: begin  // left window
                        draw_start_rect <= 1;
                        vx0 <=  46; vy0 <=  55;
                        vx1 <=  54; vy1 <=  70;
                        cidx <= 'hF;  // blue-grey
                    end
                    'd10: begin  // middle window
                        draw_start_rect <= 1;
                        vx0 <= 120; vy0 <=  50;
                        vx1 <= 130; vy1 <=  70;
                        cidx <= 'hF;  // blue-grey
                    end
                    'd11: begin  // right window
                        draw_start_rect <= 1;
                        vx0 <= 196; vy0 <=  55;
                        vx1 <= 204; vy1 <=  70;
                        cidx <= 'hF;  // blue-grey
                    end
                    'd12: begin  // battlement 1
                        draw_start_rect <= 1;
                        vx0 <=  63; vy0 <=  67;
                        vx1 <=  72; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    'd13: begin  // battlement 2
                        draw_start_rect <= 1;
                        vx0 <=   80; vy0 <=  67;
                        vx1 <=   89; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    'd14: begin  // battlement 3
                        draw_start_rect <= 1;
                        vx0 <=  97; vy0 <=  67;
                        vx1 <= 106; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    'd15: begin  // battlement 4
                        draw_start_rect <= 1;
                        vx0 <= 144; vy0 <=  67;
                        vx1 <= 153; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    'd16: begin  // battlement 5
                        draw_start_rect <= 1;
                        vx0 <= 161; vy0 <=  67;
                        vx1 <= 170; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    'd17: begin  // battlement 6
                        draw_start_rect <= 1;
                        vx0 <= 178; vy0 <=  67;
                        vx1 <= 187; vy1 <=  75;
                        cidx <= 'hE;  // dark grey
                    end
                    default: begin  // clear ground
                        draw_start_rect <= 1;
                        vx0 <=   0; vy0 <= 131;
                        vx1 <= 319; vy1 <= 179;
                        cidx <= 'h0;  // background (transparent)
                    end
                endcase
            end
            DRAW_CASTLE: begin
                draw_start_tri    <= 0;
                draw_start_rect   <= 0;
                draw_start_circle <= 0;
                if (draw_done) begin
                    if (shape_id == SHAPE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        shape_id <= shape_id + 1;
                        state <= INIT_CASTLE;
                    end
                end
            end
            DONE: state <= DONE;
            default: if (start) state <= INIT_RBOW;  // IDLE
        endcase
        if (rst) state <= IDLE;
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk,
        .rst,
        .start(draw_start_tri),
        .oe,
        .x0(vx0 * SCALE),
        .y0(vy0 * SCALE),
        .x1(vx1 * SCALE),
        .y1(vy1 * SCALE),
        .x2(vx2 * SCALE),
        .y2(vy2 * SCALE),
        .x(x_tri),
        .y(y_tri),
        .drawing(drawing_tri),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_tri)
    );

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
        .clk,
        .rst,
        .start(draw_start_rect),
        .oe,
        .x0(vx0 * SCALE),
        .y0(vy0 * SCALE),
        .x1(vx1 * SCALE),
        .y1(vy1 * SCALE),
        .x(x_rect),
        .y(y_rect),
        .drawing(drawing_rect),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_rect)
    );

    draw_circle_fill #(.CORDW(CORDW)) draw_circle_inst (
        .clk,
        .rst,
        .start(draw_start_circle),
        .oe,
        .x0(vx0 * SCALE),
        .y0(vy0 * SCALE),
        .r0(vr0 * SCALE),
        .x(x_circle),
        .y(y_circle),
        .drawing(drawing_circle),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_circle)
    );

    // output coordinates for the active shape
    always_ff @(posedge clk) begin
        x <= drawing_tri ? x_tri : (drawing_rect ? x_rect : x_circle);
        y <= drawing_tri ? y_tri : (drawing_rect ? y_rect : y_circle);
    end

    // drawing and done apply to all drawing types
    always_ff @(posedge clk) begin
        drawing   <= drawing_tri   || drawing_rect   || drawing_circle;
        draw_done <= draw_done_tri || draw_done_rect || draw_done_circle;
    end

    // doesn't need delaying one cycle because it's based on draw_done
    always_ff @(posedge clk) done <= (state == DONE);
endmodule
