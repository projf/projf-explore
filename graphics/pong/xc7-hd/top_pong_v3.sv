// Project F: Pong - Top Pong v3 (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_pong_v3 (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst,          // reset button (active low)
    output      logic hdmi_tx_ch0_p,    // HDMI source channel 0 diff+
    output      logic hdmi_tx_ch0_n,    // HDMI source channel 0 diff-
    output      logic hdmi_tx_ch1_p,    // HDMI source channel 1 diff+
    output      logic hdmi_tx_ch1_n,    // HDMI source channel 1 diff-
    output      logic hdmi_tx_ch2_p,    // HDMI source channel 2 diff+
    output      logic hdmi_tx_ch2_n,    // HDMI source channel 2 diff-
    output      logic hdmi_tx_clk_p,    // HDMI source clock diff+
    output      logic hdmi_tx_clk_n     // HDMI source clock diff-
    );

    // generate pixel clocks
    logic clk_pix;                  // pixel clock
    logic clk_pix_5x;               // 5x pixel clock for 10:1 DDR SerDes
    logic clk_pix_locked;           // pixel clock locked?
    clock_gen_720p clock_pix_inst (
        .clk_100m,
        .rst(!btn_rst),             // reset button is active low
        .clk_pix,
        .clk_pix_5x,
        .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 12;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_720p display_inst (
        .clk_pix,
        .rst(!clk_pix_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking (720p/1080p)
    /* verilator lint_off UNUSED */
    localparam H_RES_FULL = 1650;  // 1650 / 2200
    localparam V_RES_FULL =  750;  //  750 / 1125
    localparam H_RES      = 1280;  // 1280 / 1920
    localparam V_RES      =  720;  //  720 / 1080
    /* verilator lint_on UNUSED */

    logic animate;  // high for one clock tick at start of vertical blanking
    always_comb animate = (sy == V_RES && sx == 0);

    // ball
    localparam B_SIZE = 16;     // size in pixels
    logic [CORDW-1:0] bx, by;   // position
    logic dx, dy;               // direction: 0 is right/down
    logic [CORDW-1:0] spx = 10; // horizontal speed
    logic [CORDW-1:0] spy = 6;  // vertical speed
    logic b_draw;               // draw ball?

    // paddles
    localparam P_H = 80;         // height in pixels
    localparam P_W = 15;         // width in pixels
    localparam P_SP = 6;         // speed
    localparam P_OFFS = 48;      // offset from screen edge
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

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de    <= de;
        dvi_red   <= (de && (b_draw | p1_draw | p2_draw)) ? 8'hFF : 8'h00;
        dvi_green <= (de && (b_draw | p1_draw | p2_draw)) ? 8'hFF : 8'h00;
        dvi_blue  <= (de && (b_draw | p1_draw | p2_draw)) ? 8'hFF : 8'h00;
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst(!clk_pix_locked),
        .de(dvi_de),
        .data_in_ch0(dvi_blue),
        .data_in_ch1(dvi_green),
        .data_in_ch2(dvi_red),
        .ctrl_in_ch0({dvi_vsync, dvi_hsync}),
        .ctrl_in_ch1(2'b00),
        .ctrl_in_ch2(2'b00),
        .tmds_ch0_serial,
        .tmds_ch1_serial,
        .tmds_ch2_serial,
        .tmds_clk_serial
    );

    // TMDS output pins
    tmds_out tmds_ch0 (.tmds(tmds_ch0_serial),
        .pin_p(hdmi_tx_ch0_p), .pin_n(hdmi_tx_ch0_n));
    tmds_out tmds_ch1 (.tmds(tmds_ch1_serial),
        .pin_p(hdmi_tx_ch1_p), .pin_n(hdmi_tx_ch1_n));
    tmds_out tmds_ch2 (.tmds(tmds_ch2_serial),
        .pin_p(hdmi_tx_ch2_p), .pin_n(hdmi_tx_ch2_n));
    tmds_out tmds_clk (.tmds(tmds_clk_serial),
        .pin_p(hdmi_tx_clk_p), .pin_n(hdmi_tx_clk_n));
endmodule
