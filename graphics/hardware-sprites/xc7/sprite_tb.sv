// Project F: Hardware Sprites - Sprite with Scaling Test Bench
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module sprite_tb();

    parameter CLK_PERIOD = 40;  // 40 ns == 25 MHz

    logic rst;
    logic clk_25m;

    // display sync signals and coordinates
    localparam CORDW = 16;  // screen coordinate width in bits
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_24x18 #(.CORDW(CORDW)) display_inst (
        .clk_pix(clk_25m),
        .rst_pix(rst),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // screen dimensions (must match display_inst)
    localparam H_RES = 24;

    // sprite parameters
    localparam SX_OFFS    = 2;  // horizontal screen offset (pixels)
    localparam SPR_FILE   = "letter_f.mem";
    localparam SPR_WIDTH  = 8;  // width in pixels
    localparam SPR_HEIGHT = 8;  // height in pixels
    localparam SPR_SCALE  = 2;  // 2^1 = 2x scale
    localparam SPR_DATAW  = 1;  // bits per pixel

    // draw sprite at position (sprx,spry)
    logic signed [CORDW-1:0] sprx, spry;

    logic pix, drawing;
    sprite #(
        .CORDW(CORDW),
        .H_RES(H_RES),
        .SX_OFFS(SX_OFFS),
        .SPR_FILE(SPR_FILE),
        .SPR_WIDTH(SPR_WIDTH),
        .SPR_HEIGHT(SPR_HEIGHT),
        .SPR_SCALE(SPR_SCALE),
        .SPR_DATAW(SPR_DATAW)
    ) sprite_scale_instance (
        .clk(clk_25m),
        .rst,
        .line,
        .sx,
        .sy,
        .sprx,
        .spry,
        .pix,
        .drawing
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_25m = ~clk_25m;

    initial begin
        rst = 1;
        clk_25m = 1;
        sprx = 0;
        spry = 0;
        #120 rst = 0;

        #43_000
        sprx = -7;
        spry = -7;

        #43_000
        sprx = 20;
        spry = 4;

        #43_000
        sprx = 20;
        spry = 16;

        #43_000
        sprx = 0;
        spry = 0;

        #50_000 $finish;
    end
endmodule
