// Project F: FPGA Graphics - Sprite v3 Test Bench
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sprite_v3_tb();

    parameter CLK_PERIOD = 40;  // 40 ns == 25 MHz

    logic rst;
    logic clk_25m;

    // size of screen with and without blanking
    localparam H_RES_FULL = 40;
    localparam V_RES_FULL = 27;
    localparam H_RES = 32;
    localparam V_RES = 24;

    localparam CORDW = 6;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic de;
    always_ff @(posedge clk_25m) begin
        if (sx == H_RES_FULL - 1) begin  // last pixel on line?
            sx <= 0;
            sy <= (sy == V_RES_FULL - 1) ? 0 : sy + 1;  // last line on screen?
        end else begin
            sx <= sx + 1;
        end
        if (rst) begin
            sx <= 0;
            sy <= 0;
        end
    end
    always_comb de = (sx < H_RES && sy < V_RES);

    // sprite
    localparam SPR_WIDTH   = 8;  // width in pixels
    localparam SPR_HEIGHT  = 8;  // number of lines
    localparam SPR_SCALE_X = 3;  // width scale-factor
    localparam SPR_SCALE_Y = 2;  // height scale-factor
    localparam SPR_FILE = "letter_f.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam DRAW_X = 0;
    localparam DRAW_Y = 0;

    // start sprite in blanking of line before first line drawn
    logic [CORDW-1:0] draw_y_cor;  // corrected for wrapping
    always_comb begin
        draw_y_cor = (DRAW_Y == 0) ? V_RES_FULL - 1 : DRAW_Y - 1;
        spr_start = (sy == draw_y_cor && sx == H_RES);
    end

    sprite_v3 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .SPR_FILE(SPR_FILE)
        ) spr_instance (
        .clk(clk_25m),
        .rst,
        .start(spr_start),
        .sx,
        .sprx(DRAW_X),
        .pix(spr_pix)
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_25m = ~clk_25m;

    initial begin
        rst = 1;
        clk_25m = 1;
        #100 rst = 0;

        #100_000 $finish;
    end
endmodule
