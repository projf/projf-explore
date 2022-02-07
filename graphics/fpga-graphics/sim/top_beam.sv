// Project F: FPGA Graphics - Top Beam (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_beam #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,             // pixel clock
    input  wire logic rst,                 // reset
    output      logic [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,         // 8-bit red
    output      logic [7:0] sdl_g,         // 8-bit green
    output      logic [7:0] sdl_b          // 8-bit blue
    );

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic de;
    simple_480p display_inst (
        .clk_pix,
        .rst,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
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

    // square 'Q' - origin at top-left
    localparam Q_SIZE = 32;    // square size in pixels
    localparam Q_SPEED = 4;    // pixels moved per frame
    logic [CORDW-1:0] qx, qy;  // square position

    // update square position once per frame
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (qx >= H_RES_FULL - Q_SIZE) begin
                qx <= 0;
                qy <= (qy >= V_RES_FULL - Q_SIZE) ? 0 : qy + Q_SIZE;
            end else begin
                qx <= qx + Q_SPEED;
            end
        end
    end

    // is square at current screen position?
    logic q_draw;
    always_comb begin
        q_draw = (sx >= qx) && (sx < qx + Q_SIZE)
              && (sy >= qy) && (sy < qy + Q_SIZE);
    end

    // SDL output
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r <= !de ? 8'h00 : (q_draw ? 8'hFF : 8'h00);
        sdl_g <= !de ? 8'h00 : (q_draw ? 8'h88 : 8'h88);
        sdl_b <= !de ? 8'h00 : (q_draw ? 8'h00 : 8'hFF);
    end
endmodule
