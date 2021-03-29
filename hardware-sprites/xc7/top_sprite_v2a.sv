// Project F: Hardware Sprites - Top Sprite v2a (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v2a (
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

    // display timings
    localparam H_RES = 640;
    localparam V_RES = 480;
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_480p display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // sprite
    localparam SPR_WIDTH   = 8;   // width in pixels
    localparam SPR_HEIGHT  = 8;   // number of lines
    localparam SPR_SCALE_X = 6;   // width scale-factor
    localparam SPR_SCALE_Y = 6;   // height scale-factor
    localparam SPR_FILE = "saucer.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam SPR_SPEED_X = 4;
    localparam SPR_SPEED_Y = 0;
    logic [CORDW-1:0] sprx, spry;
    logic dx;  // direction: 0 is right/down

    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (sprx >= H_RES - (SPR_SPEED_X + SPR_WIDTH * SPR_SCALE_X)) begin  // right edge
                dx <= 1;
                sprx <= sprx - SPR_SPEED_X;
            end else if (sprx < SPR_SPEED_X) begin  // left edge
                dx <= 0;
                sprx <= sprx + SPR_SPEED_X;
            end else sprx <= (dx) ? sprx - SPR_SPEED_X : sprx + SPR_SPEED_X;
        end
        if (!clk_locked) begin
            sprx <= 296;
            spry <= 216;
            dx <= 0;
        end
    end

    // signal to start sprite drawing
    always_comb spr_start = (line && sy == spry);

    sprite_v2 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .SPR_FILE(SPR_FILE)
        ) spr_instance (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .sx,
        .sprx,
        .pix(spr_pix)
    );

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= (de && spr_pix) ? 4'hF: 4'h0;
        vga_g <= (de && spr_pix) ? 4'hC: 4'h0;
        vga_b <= (de && spr_pix) ? 4'h0: 4'h0;
    end
endmodule
