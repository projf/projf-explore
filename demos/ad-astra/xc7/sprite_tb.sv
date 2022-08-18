// Project F: Ad Astra - Sprite (1-bit per Pixel) Test Bench
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-ad-astra/

`default_nettype none
`timescale 1ns / 1ps

module sprite_tb();

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

    // font ROM
    localparam FONT_WIDTH  = 8;  // width in pixels
    localparam FONT_HEIGHT = 8;  // number of lines
    localparam FONT_DEPTH  = 64 * FONT_HEIGHT;    // 64 chars
    localparam FONT_ADDRW  = $clog2(FONT_DEPTH);  // font ROM address width
    localparam FONT_INIT_F = "font_unscii_8x8_latin_uc.mem";

    logic [FONT_ADDRW-1:0] font_addr;
    logic [FONT_WIDTH-1:0] font_data;

    rom_sync #(
        .INIT_F(FONT_INIT_F),
        .WIDTH(FONT_WIDTH),
        .DEPTH(FONT_DEPTH)
    ) font_rom (
        .clk(clk_25m),
        .addr(font_addr),
        .data(font_data)
    );

    // sprite
    logic spr_start;
    logic [FONT_ADDRW-1:0] spr0_gfx_addr, spr1_gfx_addr;
    logic spr0_dma, spr0_pix, spr0_drawing, spr0_done;
    logic spr1_dma, spr1_pix, spr1_drawing, spr1_done;

    // horizontal position of letters
    localparam SPR0_X = 0;
    localparam SPR1_X = 10;

    localparam SPR0_CP = FONT_HEIGHT * ('h4C - 'h20); // L
    localparam SPR1_CP = FONT_HEIGHT * ('h45 - 'h20); // E

    always_comb begin
        spr_start = (sy == 4 && sx == 0);
        spr0_dma = (sx >= 25 && sx < 27);  // 2 cycles
        spr1_dma = (sx >= 27 && sx < 29);
        font_addr = 0;
        if (spr0_dma) font_addr = SPR0_CP + spr0_gfx_addr;
        if (spr1_dma) font_addr = SPR1_CP + spr1_gfx_addr;
    end

    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .LSB(0),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .ADDRW(FONT_ADDRW)
        ) spr0 (
        .clk(clk_25m),
        .rst,
        .start(spr_start),
        .dma_avail(spr0_dma),
        .sx,
        .sprx(SPR0_X),
        .data_in(font_data),
        .pos(spr0_gfx_addr),
        .pix(spr0_pix),
        .drawing(spr0_drawing),
        .done(spr0_done)
    );

    sprite #(
        .LSB(0),
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .ADDRW(FONT_ADDRW),
        .CORDW(CORDW)
        ) spr1 (
        .clk(clk_25m),
        .rst,
        .start(spr_start),
        .dma_avail(spr1_dma),
        .sx,
        .sprx(SPR1_X),
        .data_in(font_data),
        .pos(spr1_gfx_addr),
        .pix(spr1_pix),
        .drawing(spr1_drawing),
        .done(spr1_done)
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
