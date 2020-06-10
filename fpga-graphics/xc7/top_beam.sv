// Project F: FPGA Graphics - Top Beam (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_beam (
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
    clock_gen clock_640x480 (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .de
    );

    // size of screen (including blanking)
    localparam H_RES = 800;
    localparam V_RES = 525;

    // square 'Q' - origin at top-left
    localparam Q_SIZE = 32;    // square size in pixels
    localparam Q_SPEED = 4;    // pixels moved per frame
    logic [CORDW-1:0] qx, qy;  // square position

    logic animate;  // high for one clock tick at start of blanking
    always_comb animate = (sy == 480 && sx == 0);

    // update square position once per frame
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (qx >= H_RES - Q_SIZE) begin
                qx <= 0;
                qy <= (qy >= V_RES - Q_SIZE) ? 0 : qy + Q_SIZE;
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

    // VGA output
    always_comb begin
        vga_r = !de ? 4'h0 : (q_draw ? 4'hF : 4'h0);
        vga_g = !de ? 4'h0 : (q_draw ? 4'h8 : 4'h8);
        vga_b = !de ? 4'h0 : (q_draw ? 4'h0 : 4'hF);
    end
endmodule
