// Project F: Hardware Sprites - Sprite v1 Test Bench
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sprite_v1_tb();

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
    localparam SPR_WIDTH  = 8;  // width in pixels
    localparam SPR_HEIGHT = 8;  // number of lines
    localparam SPR_FILE = "letter_f.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam DRAW_X = 4;
    localparam DRAW_Y = 4;

    // signal to start sprite drawing
    always_comb begin
        spr_start = (sy == DRAW_Y && sx == 0);
    end

    sprite_v1 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .SPR_FILE(SPR_FILE),
        .CORDW(CORDW)
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
