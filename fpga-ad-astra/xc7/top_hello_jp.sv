// Project F: FPGA Ad Astra - Top Hello JP (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_hello_jp (
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

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    // font glyph ROM
    localparam FONT_WIDTH  = 16;  // width in pixels (also ROM width)
    localparam FONT_HEIGHT = 16;  // height in pixels
    localparam FONT_GLYPHS = 86;  // number of glyphs
    localparam F_ROM_DEPTH = FONT_GLYPHS * FONT_HEIGHT;
    localparam FONT_FILE   = "font_unscii_16x16_hiragana.mem";

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
    localparam SPR_SCALE_X = 4;  // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 4;  // enlarge sprite height by this factor

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

    // subtract 0x3041 from code points as font starts at U+3041
    logic [$clog2(F_ROM_DEPTH)-1:0] spr_cp_norm [SPR_CNT];
    initial begin
        spr_cp_norm[0] = 'h12;  // こ U+3053
        spr_cp_norm[1] = 'h52;  // ん U+3093
        spr_cp_norm[2] = 'h2A;  // に U+306B
        spr_cp_norm[3] = 'h20;  // ち U+3061
        spr_cp_norm[4] = 'h2E;  // は U+306F
    end

    integer i;  // for looping over sprite signals

    // font ROM address
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line [SPR_CNT];
    logic spr_fdma [SPR_CNT];  // font ROM DMA slots
    always_comb begin
        font_rom_addr = 0;
        for (i = 0; i < SPR_CNT; i = i + 1) begin
            /* verilator lint_off WIDTH */
            spr_fdma[i] = (sx == H_RES+i);
            if (spr_fdma[i]) font_rom_addr = FONT_HEIGHT * spr_cp_norm[i] + spr_glyph_line[i];
            /* verilator lint_on WIDTH */
        end
    end

    // sprite instances
    logic [SPR_CNT-1:0] spr_pix;  // sprite pixels

    genvar m;  // for looping over sprite instances
    generate for (m = 0; m < SPR_CNT; m = m + 1) begin : sprite_gen
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
            .dma_avail(spr_fdma[m]),
            .sx,
            .sprx(spr_x[m]),
            .data_in(font_rom_data),
            .pos(spr_glyph_line[m]),
            .pix(spr_pix[m]),
            /* verilator lint_off PINCONNECTEMPTY */
            .draw(),
            .done()
            /* verilator lint_on PINCONNECTEMPTY */
        );
    end endgenerate

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

    // VGA output
    always_comb begin
        vga_r = (de) ? (spr_pix != 0) ? red_spr   : starlight : 4'h0;
        vga_g = (de) ? (spr_pix != 0) ? green_spr : starlight : 4'h0;
        vga_b = (de) ? (spr_pix != 0) ? blue_spr  : starlight : 4'h0;
    end
endmodule
