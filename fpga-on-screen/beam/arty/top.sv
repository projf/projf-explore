// Project F: Beam - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-on-screen/

`default_nettype none
`timescale 1ns / 1ps

module top (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst,          // reset button (active low)
    output      logic vga_hsync,        // horizontal sync
    output      logic vga_vsync,        // vertical sync
    output      logic [3:0] vga_red,    // 4-bit VGA red
    output      logic [3:0] vga_green,  // 4-bit VGA green
    output      logic [3:0] vga_blue    // 4-bit VGA blue
    );

    // divide 100 MHz clock by four to create 25 MHz strobe
    logic stb_pix;
    logic [1:0] cnt;
    always_ff @(posedge clk_100m) begin
        {stb_pix, cnt} <= cnt + 1;
    end

    // screen position
    logic [9:0] sx;
    logic [9:0] sy;

    // blanking signals: sync and data enable
    logic vsync;
    logic hsync;
    logic de;

    // frame start: high for one cycle at frame start
    logic frame_start;

    display_timings timings_640x480 (
        .clk(clk_100m),
        .stb_pix,
        .rst(!btn_rst),  // reset button is active low
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame_start
    );

    // size of screen (including blanking)
    localparam H_RES = 800;
    localparam V_RES = 525;

    // square 'Q' - origin at top-left
    localparam Q_SIZE = 32; // square size in pixels
    localparam Q_SPEED = 4; // pixels moved per frame
    logic [9:0] qx;         // horizontal square position
    logic [9:0] qy;         // vertical square position

    // update square position once per frame
    always_ff @(posedge clk_100m) begin
        if (stb_pix && frame_start) begin
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
        vga_hsync = hsync;
        vga_vsync = vsync;
        vga_red   = !de ? 4'h0 : (q_draw ? 4'hD : 4'h3);
        vga_green = !de ? 4'h0 : (q_draw ? 4'hA : 4'h7);
        vga_blue  = !de ? 4'h0 : (q_draw ? 4'h3 : 4'hD);
    end
endmodule
