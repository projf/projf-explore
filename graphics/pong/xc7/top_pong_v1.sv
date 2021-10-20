// Project F: Pong - Top Pong v1 (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_pong_v1 (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_480p display_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
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
    logic [CORDW-1:0] spx = 1;  // horizontal speed
    logic [CORDW-1:0] spy = 1;  // vertical speed
    logic b_draw;               // draw ball?

    // ball animation
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (bx >= H_RES - (spx + B_SIZE)) begin  // right edge
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

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= (de && b_draw) ? 4'hF : 4'h0;
        vga_g <= (de && b_draw) ? 4'hF : 4'h0;
        vga_b <= (de && b_draw) ? 4'hF : 4'h0;
    end
endmodule
