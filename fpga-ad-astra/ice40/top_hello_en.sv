// Project F: FPGA Ad Astra - Top Hello EN (iCEBreaker with 12-bit DVI Pmod)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_hello_en (
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
    clock_gen clock_640x480 (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de;
    display_timings timings_640x480 (
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

    // font glyph ROM
    localparam FONT_WIDTH  = 8;   // width in pixels (also ROM width)
    localparam FONT_HEIGHT = 8;   // height in pixels
    localparam FONT_GLYPHS = 64;  // number of glyphs
    localparam F_ROM_DEPTH = FONT_GLYPHS * FONT_HEIGHT;
    localparam FONT_FILE   = "../res/font_unscii_8x8_latin_uc.mem";

    logic [$clog2(F_ROM_DEPTH)-1:0] font_rom_addr;
    logic [FONT_WIDTH-1:0] font_rom_data;  // line of glyph pixels

    rom_sync #(
        .WIDTH(FONT_WIDTH),
        .DEPTH(F_ROM_DEPTH),
        .INIT_F(FONT_FILE)
    ) font_rom (
        .clk(clk_pix),
        .addr(font_rom_addr),
        .data(font_rom_data)
    );

    // sprites
    localparam SPR_CNT = 5;      // number of sprites
    localparam SPR_SCALE_X = 8;  // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 8;  // enlarge sprite height by this factor

    // horizontal and vertical screen position of letters
    logic [CORDW-1:0] spr_x [SPR_CNT];
    logic [CORDW-1:0] spr_y;
    initial begin
        spr_x[0] = 158;
        spr_x[1] = 222;
        spr_x[2] = 286;
        spr_x[3] = 350;
        spr_x[4] = 414;
        spr_y    = 208;
    end

    // start sprite in blanking of line before first line drawn
    logic [CORDW-1:0] spr_y_cor;  // corrected for wrapping
    logic spr_start;
    always_comb begin
        spr_y_cor = (spr_y == 0) ? V_RES_FULL - 1 : spr_y - 1;
        spr_start = (sy == spr_y_cor && sx == 0);
    end

    // subtract 0x20 from code points as font starts at U+0020
    logic [$clog2(F_ROM_DEPTH)-1:0] spr_cp_norm [SPR_CNT];
    initial begin
        spr_cp_norm[0] = 'h28;  // H U+0048
        spr_cp_norm[1] = 'h25;  // E U+0045
        spr_cp_norm[2] = 'h2C;  // L U+004C
        spr_cp_norm[3] = 'h2C;  // L U+004C
        spr_cp_norm[4] = 'h2F;  // O U+004F
    end

    integer i;  // for looping over sprite signals

    // font ROM address
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_0;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_1;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_2;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_3;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_4;
    logic spr_fdma [SPR_CNT];  // font ROM DMA slots
    always_comb begin
        font_rom_addr = 0;
        /* verilator lint_off WIDTH */
        for (i = 0; i < SPR_CNT; i = i + 1) begin
            spr_fdma[i] = (sx == H_RES+i);
        end
        if (spr_fdma[0]) font_rom_addr = FONT_HEIGHT * spr_cp_norm[0] + spr_glyph_line_0;
        if (spr_fdma[1]) font_rom_addr = FONT_HEIGHT * spr_cp_norm[1] + spr_glyph_line_1;
        if (spr_fdma[2]) font_rom_addr = FONT_HEIGHT * spr_cp_norm[2] + spr_glyph_line_2;
        if (spr_fdma[3]) font_rom_addr = FONT_HEIGHT * spr_cp_norm[3] + spr_glyph_line_3;
        if (spr_fdma[4]) font_rom_addr = FONT_HEIGHT * spr_cp_norm[4] + spr_glyph_line_4;
        /* verilator lint_on WIDTH */
    end

    // sprite instances
    logic [SPR_CNT-1:0] spr_pix;  // sprite pixels

    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .LSB(0),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr0 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[0]),
        .sx,
        .sprx(spr_x[0]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_0),
        .pix(spr_pix[0]),
        /* verilator lint_off PINCONNECTEMPTY */
        .draw(),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );
    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .LSB(0),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr1 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[1]),
        .sx,
        .sprx(spr_x[1]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_1),
        .pix(spr_pix[1]),
        /* verilator lint_off PINCONNECTEMPTY */
        .draw(),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );
    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .LSB(0),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr2 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[2]),
        .sx,
        .sprx(spr_x[2]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_2),
        .pix(spr_pix[2]),
        /* verilator lint_off PINCONNECTEMPTY */
        .draw(),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );
    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .LSB(0),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr3 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[3]),
        .sx,
        .sprx(spr_x[3]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_3),
        .pix(spr_pix[3]),
        /* verilator lint_off PINCONNECTEMPTY */
        .draw(),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );
    sprite #(
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .LSB(0),
        .CORDW(CORDW),
        .H_RES_FULL(H_RES_FULL),
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr4 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[4]),
        .sx,
        .sprx(spr_x[4]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_4),
        .pix(spr_pix[4]),
        /* verilator lint_off PINCONNECTEMPTY */
        .draw(),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // starfields
    logic sf1_on, sf2_on, sf3_on;
    /* verilator lint_off UNUSED */
    logic [7:0] sf1_star, sf2_star, sf3_star;
    /* verilator lint_on UNUSED */

    starfield #(.INC(-1), .SEED(21'h9A9A9)) sf1 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf1_on),
        .sf_star(sf1_star)
    );

    starfield #(.INC(-2), .SEED(21'hA9A9A)) sf2 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf2_on),
        .sf_star(sf2_star)
    );

    starfield #(.INC(-4), .MASK(21'h7FF)) sf3 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf3_on),
        .sf_star(sf3_star)
    );

    // sprite colour & star brightness
    logic [3:0] red_spr, green_spr, blue_spr, starlight;
    always_comb begin
        {red_spr, green_spr, blue_spr} = (spr_pix != 0) ? 12'hFC0 : 12'h000;
        starlight = (sf1_on) ? sf1_star[7:4] :
                    (sf2_on) ? sf2_star[7:4] :
                    (sf3_on) ? sf3_star[7:4] : 4'h0;
    end

    // colours
    logic [3:0] red, green, blue;
    always_comb begin
        red   = de ? (spr_pix != 0) ? red_spr   : starlight : 4'h0;
        green = de ? (spr_pix != 0) ? green_spr : starlight : 4'h0;
        blue  = de ? (spr_pix != 0) ? blue_spr  : starlight : 4'h0;
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
