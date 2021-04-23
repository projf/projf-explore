// Project F: Pong - Top Pong (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_pong (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    input  wire logic btn_up,       // up button
    input  wire logic btn_ctrl,     // control button
    input  wire logic btn_dn,       // down button
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_display_timings_480p display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    logic animate;  // high for one clock tick at start of vertical blanking
    always_comb animate = (sy == V_RES && sx == 0);

    // debounce buttons
    logic sig_ctrl, move_up, move_dn;
    /* verilator lint_off PINCONNECTEMPTY */
    debounce deb_ctrl
        (.clk(clk_pix), .in(btn_ctrl), .out(), .ondn(), .onup(sig_ctrl));
    debounce deb_up
        (.clk(clk_pix), .in(btn_up), .out(move_up), .ondn(), .onup());
    debounce deb_dn
        (.clk(clk_pix), .in(btn_dn), .out(move_dn), .ondn(), .onup());
    /* verilator lint_on PINCONNECTEMPTY */

    // ball
    localparam B_SIZE = 8;      // size in pixels
    logic [CORDW-1:0] bx, by;   // position
    logic dx, dy;               // direction: 0 is right/down
    logic [CORDW-1:0] spx;      // horizontal speed
    logic [CORDW-1:0] spy;      // vertical speed
    logic lft_col, rgt_col;     // flag collision with left or right of screen
    logic b_draw;               // draw ball?

    // paddles
    localparam P_H = 40;         // height in pixels
    localparam P_W = 10;         // width in pixels
    localparam P_SP = 4;         // speed
    localparam P_OFFS = 32;      // offset from screen edge
    logic [CORDW-1:0] p1y, p2y;  // vertical position of paddles 1 and 2
    logic p1_draw, p2_draw;      // draw paddles?
    logic p1_col, p2_col;        // paddle collision?

    // game state
    enum {INIT, IDLE, START, PLAY, POINT_END} state, state_next;
    always_comb begin
        case(state)
            INIT: state_next = IDLE;
            IDLE: state_next = (sig_ctrl) ? START : IDLE;
            START: state_next = (sig_ctrl) ? PLAY : START;
            PLAY: state_next = (lft_col || rgt_col) ? POINT_END : PLAY;
            POINT_END: state_next = (sig_ctrl) ? START : POINT_END;
            default: state_next = IDLE;
        endcase
    end

    always_ff @(posedge clk_pix) begin
        state <= state_next;
    end

    // paddle animation
    always_ff @(posedge clk_pix) begin
        if (state == INIT || state == START) begin  // reset paddle positions
            p1y <= (V_RES - P_H) >> 1;
            p2y <= (V_RES - P_H) >> 1;
        end else if (animate && state != POINT_END) begin
            if (state == PLAY) begin  // human paddle 1
                if (move_up) begin
                    if (p1y > P_SP) p1y <= p1y - P_SP;
                end
                if (move_dn) begin
                    if (p1y < V_RES - (P_H + P_SP)) p1y <= p1y + P_SP;
                end
            end else begin  // "AI" paddle 1
                if ((p1y + P_H/2) + P_SP/2 < (by + B_SIZE/2)) begin
                    if (p1y < V_RES - (P_H + P_SP/2))
                        p1y <= p1y + P_SP;
                end else if ((p1y + P_H/2) > (by + B_SIZE/2) + P_SP/2) begin
                    if (p1y > P_SP)
                        p1y <= p1y - P_SP;
                end
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

    // ball speed control
    localparam SPEED_STEP = 5;  // speed up after this many collisions
    logic [$clog2(SPEED_STEP)-1:0] cnt_sp;  // speed counter
    always_ff @(posedge clk_pix) begin
        if (state == INIT) begin  // demo speed
            spx <= 6;
            spy <= 4;
        end else if (state == START) begin  // initial game speed
            spx <= 4;
            spy <= 2;
        end else if (state == PLAY && animate && (p1_col || p2_col)) begin
            if (cnt_sp == SPEED_STEP-1) begin
                spx <= spx + 1;
                spy <= spy + 1;
                cnt_sp <= 0;
            end else begin
                cnt_sp <= cnt_sp + 1;
            end
        end
    end

    // ball animation
    always_ff @(posedge clk_pix) begin
        if (state == INIT || state == START) begin  // reset ball position
            bx <= (H_RES - B_SIZE) >> 1;
            by <= (V_RES - B_SIZE) >> 1;
            dx <= 0;  // serve towards player 2 (AI)
            dy <= ~dy;
            lft_col <= 0;
            rgt_col <= 0;
        end else if (animate && state != POINT_END) begin
            if (p1_col) begin  // left paddle collision
                dx <= 0;
                bx <= bx + spx;
                dy <= (by + B_SIZE/2 < p1y + P_H/2) ? 1 : 0;
            end else if (p2_col) begin  // right paddle collision
                dx <= 1;
                bx <= bx - spx;
                dy <= (by + B_SIZE/2 < p1y + P_H/2) ? 1 : 0;
            end else if (bx >= H_RES - (spx + B_SIZE)) begin  // right edge
                rgt_col <= 1;
            end else if (bx < spx) begin  // left edge
                lft_col <= 1;
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

    // colours
    logic [3:0] red, green, blue;
    always_comb begin
        red   = (de && (b_draw | p1_draw | p2_draw)) ? 4'hF : 4'h0;
        green = (de && (b_draw | p1_draw | p2_draw)) ? 4'hF : 4'h0;
        blue  = (de && (b_draw | p1_draw | p2_draw)) ? 4'hF : 4'h0;
    end

    // Output DVI clock: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // Output DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, red, green, blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
