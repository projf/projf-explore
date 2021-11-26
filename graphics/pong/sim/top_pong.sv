// Project F: FPGA Pong - Top Pong (Verilator SDL)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_pong #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,         // pixel clock
    input  wire logic rst,             // reset
    output      logic [CORDW-1:0] sx,  // horizontal screen position
    output      logic [CORDW-1:0] sy,  // vertical screen position
    output      logic de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,     // 8-bit red
    output      logic [7:0] sdl_g,     // 8-bit green
    output      logic [7:0] sdl_b      // 8-bit blue
    );

    // display sync signals and coordinates
    simple_480p display_inst (
        .clk_pix,
        .rst,
        .sx,
        .sy,
        .hsync(),
        .vsync(),
        .de
    );

    // size of screen with and without blanking
    /* verilator lint_off UNUSED */
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES      = 640;
    localparam V_RES      = 480;
    /* verilator lint_on UNUSED */

    logic animate;  // high for one clock tick at start of vertical blanking
    always_comb animate = (sy == V_RES && sx == 0);

    // ball
    localparam B_SIZE = 8;      // size in pixels
    logic [CORDW-1:0] bx, by;   // position
    logic dx, dy;               // direction: 0 is right/down
    logic [CORDW-1:0] spx = 6;  // horizontal speed
    logic [CORDW-1:0] spy = 4;  // vertical speed
    logic b_draw;               // draw ball?

    // paddles
    localparam P_H = 40;         // height in pixels
    localparam P_W = 10;         // width in pixels
    localparam P_SP = 4;         // speed
    localparam P_OFFS = 32;      // offset from screen edge
    logic [CORDW-1:0] p1y, p2y;  // vertical position of paddles 1 and 2
    logic p1_draw, p2_draw;      // draw paddles?
    logic p1_col, p2_col;        // paddle collision?

    // paddle animation
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            // "AI" paddle 1
            if ((p1y + P_H/2) + P_SP/2 < (by + B_SIZE/2)) begin
                if (p1y < V_RES - (P_H + P_SP/2))  // screen bottom?
                    p1y <= p1y + P_SP;  // move down
            end else if ((p1y + P_H/2) > (by + B_SIZE/2) + P_SP/2) begin
                if (p1y > P_SP)  // screen top?
                    p1y <= p1y - P_SP;  // move up
            end

            // "AI" paddle 2
            if ((p2y + P_H/2) + P_SP/2 < (by + B_SIZE/2)) begin
                if (p2y < V_RES - (P_H + P_SP/2))
                    p2y <= p2y + P_SP;
            end else if ((p2y + P_H/2) > (by + B_SIZE/2) + P_SP/2) begin
                if (p2y > P_SP)
                    p2y <= p2y - P_SP;
            end
        end
    end

    // draw paddles - are paddles at current screen position?
    always_comb begin
        p1_draw = (sx >= P_OFFS) && (sx < P_OFFS + P_W)
               && (sy >= p1y) && (sy < p1y + P_H);
        p2_draw = (sx >= H_RES - P_OFFS - P_W) && (sx < H_RES - P_OFFS)
               && (sy >= p2y) && (sy < p2y + P_H);
    end

    // paddle collision detection
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            p1_col <= 0;
            p2_col <= 0;
        end else if (b_draw) begin
            if (p1_draw) p1_col <= 1;
            if (p2_draw) p2_col <= 1;
        end
    end

    // ball animation
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (p1_col) begin  // left paddle collision
                dx <= 0;
                bx <= bx + spx;
            end else if (p2_col) begin  // right paddle collision
                dx <= 1;
                bx <= bx - spx;
            end else if (bx >= H_RES - (spx + B_SIZE)) begin  // right edge
                dx <= 1;
                bx <= bx - spx;
            end else if (bx < spx) begin  // left edge
                dx <= 0;
                bx <= bx + spx;
            end else bx <= (dx) ? bx - spx : bx + spx;

            if (by >= V_RES - (spy + B_SIZE)) begin  // bottom edge
                dy <= 1;
                by <= by - spy;
            end else if (by < spy) begin  // top edge
                dy <= 0;
                by <= by + spy;
            end else by <= (dy) ? by - spy : by + spy;
        end
    end

    // draw ball - is ball at current screen position?
    always_comb begin
        b_draw = (sx >= bx) && (sx < bx + B_SIZE)
              && (sy >= by) && (sy < by + B_SIZE);
    end

    // SDL output
    always_ff @(posedge clk_pix) begin
        sdl_r <= (de && (b_draw | p1_draw | p2_draw)) ? 8'hFF : 8'h00;
        sdl_g <= (de && (b_draw | p1_draw | p2_draw)) ? 8'hFF : 8'h00;
        sdl_b <= (de && (b_draw | p1_draw | p2_draw)) ? 8'hFF : 8'h00;
    end
endmodule
