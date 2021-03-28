// Project F: FPGA Graphics - Top Bounce (iCEBreaker with 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_bounce (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
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
    display_timings_480p display_timings_inst (
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

    // squares - origin at top-left
    localparam Q1_SIZE = 100;   // square 1 size in pixels
    localparam Q2_SIZE = 150;   // square 2 size in pixels
    localparam Q3_SIZE = 200;   // square 3 size in pixels
    logic [CORDW-1:0] q1x, q1y; // square 1 position
    logic [CORDW-1:0] q2x, q2y; // square 2 position
    logic [CORDW-1:0] q3x, q3y; // square 3 position
    logic q1dx, q1dy;           // square 1 direction: 0 is right/down
    logic q2dx, q2dy;           // square 2 direction: 0 is right/down
    logic q3dx, q3dy;           // square 3 direction: 0 is right/down
    logic [CORDW-1:0] q1s = 2;  // square 1 speed
    logic [CORDW-1:0] q2s = 1;  // square 2 speed
    logic [CORDW-1:0] q3s = 1;  // square 3 speed

    // update square position once per frame
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (q1x >= H_RES - (Q1_SIZE + q1s)) begin  // right edge
                q1dx <= 1;
                q1x <= q1x - q1s;
            end else if (q1x < q1s) begin  // left edge
                q1dx <= 0;
                q1x <= q1x + q1s;
            end else q1x <= (q1dx) ? q1x - q1s : q1x + q1s;

            if (q1y >= V_RES - (Q1_SIZE + q1s)) begin  // bottom edge
                q1dy <= 1;
                q1y <= q1y - q1s;
            end else if (q1y < q1s) begin  // top edge
                q1dy <= 0;
                q1y <= q1y + q1s;
            end else q1y <= (q1dy) ? q1y - q1s : q1y + q1s;

            if (q2x >= H_RES - (Q2_SIZE + q2s)) begin
                q2dx <= 1;
                q2x <= q2x - q2s;
            end else if (q2x < q2s) begin
                q2dx <= 0;
                q2x <= q2x + q2s;
            end else q2x <= (q2dx) ? q2x - q2s : q2x + q2s;

            if (q2y >= V_RES - (Q2_SIZE + q2s)) begin
                q2dy <= 1;
                q2y <= q2y - q2s;
            end else if (q2y < q2s) begin
                q2dy <= 0;
                q2y <= q2y + q2s;
            end else q2y <= (q2dy) ? q2y - q2s : q2y + q2s;

            if (q3x >= H_RES - (Q3_SIZE + q3s)) begin
                q3dx <= 1;
                q3x <= q3x - q3s;
            end else if (q3x < q3s) begin
                q3dx <= 0;
                q3x <= q3x + q3s;
            end else q3x <= (q3dx) ? q3x - q3s : q3x + q3s;

            if (q3y >= V_RES - (Q3_SIZE + q3s)) begin
                q3dy <= 1;
                q3y <= q3y - q3s;
            end else if (q3y < q3s) begin
                q3dy <= 0;
                q3y <= q3y + q3s;
            end else q3y <= (q3dy) ? q3y - q3s : q3y + q3s;
        end
    end

    // are any squares at current screen position?
    logic q1_draw, q2_draw, q3_draw;
    always_comb begin
        q1_draw = (sx >= q1x) && (sx < q1x + Q1_SIZE)
              && (sy >= q1y) && (sy < q1y + Q1_SIZE);
        q2_draw = (sx >= q2x) && (sx < q2x + Q2_SIZE)
              && (sy >= q2y) && (sy < q2y + Q2_SIZE);
        q3_draw = (sx >= q3x) && (sx < q3x + Q3_SIZE)
              && (sy >= q3y) && (sy < q3y + Q3_SIZE);
    end

    // colours
    logic [3:0] red, green, blue;
    always_comb begin
        red   = (de && q1_draw) ? 4'hF : 4'h0;
        green = (de && q2_draw) ? 4'hF : 4'h0;
        blue  = (de && q3_draw) ? 4'hF : 4'h0;
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
