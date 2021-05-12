// Project F: Ad Astra - Top Greetings (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_greet (
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
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, line, frame;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
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

    // greeting message ROM
    localparam GREET_MSGS   = 32;  // 32 messages
    localparam GREET_LENGTH = 16;  // each containing 16 code points
    localparam G_ROM_WIDTH  = $clog2('h5F);  // highest code point is U+005F
    localparam G_ROM_DEPTH  = GREET_MSGS * GREET_LENGTH;
    localparam GREET_FILE   = "../res/greet.mem";

    logic [$clog2(G_ROM_DEPTH)-1:0] greet_rom_addr;
    logic [G_ROM_WIDTH-1:0] greet_rom_data;  // code point

    rom_sync #(
        .WIDTH(G_ROM_WIDTH),
        .DEPTH(G_ROM_DEPTH),
        .INIT_F(GREET_FILE)
    ) greet_rom (
        .clk(clk_pix),
        .addr(greet_rom_addr),
        .data(greet_rom_data)
    );

    // greeting selector
    localparam MSG_CHG = 80;  // change message every N frames
    logic [$clog2(MSG_CHG)-1:0] cnt_frm;  // frame counter
    logic [$clog2(GREET_MSGS)-1:0] greeting;  // greeting line chosen
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            cnt_frm <= cnt_frm + 1;
            if (cnt_frm == MSG_CHG) begin
                greeting <= greeting + 1;
                cnt_frm <= 0;
            end
        end
    end

    // font glyph ROM
    localparam FONT_WIDTH  = 8;   // width in pixels (also ROM width)
    localparam FONT_HEIGHT = 8;   // height in pixels
    localparam FONT_GLYPHS = 64;  // number of glyphs (0x00 - 0x3F)
    localparam F_ROM_DEPTH = FONT_GLYPHS * FONT_HEIGHT;
    localparam CP_START    = 'h20;  // first code point (0x5F - 0x20 = 0x3F)
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
    localparam V_RES = 480;        // vertical screen resolution
    localparam SPR_CNT = 8;        // number of sprites
    localparam LINE2 = V_RES / 2;  // where to consider second line of sprites
    localparam SPR_SCALE_X = 8;    // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 8;    // enlarge sprite height by this factor
    localparam SPR_DMA = 0 - 2*SPR_CNT;  // start sprite DMA in h-blanking

    // horizontal and vertical screen position of letters
    logic signed [CORDW-1:0] spr_x [SPR_CNT];
    logic signed [CORDW-1:0] spr_y [2];  // 2 lines of sprites
    initial begin
        spr_x[0] = 64;
        spr_x[1] = 128;
        spr_x[2] = 192;
        spr_x[3] = 256;
        spr_x[4] = 320;
        spr_x[5] = 384;
        spr_x[6] = 448;
        spr_x[7] = 512;

        spr_y[0] = 150;
        spr_y[1] = 250;
    end

    // signal to start sprite drawing for two rows of text
    logic spr_start;
    always_comb begin
        spr_start = (sy < LINE2) ? (line && sy == spr_y[0]) :
                                   (line && sy == spr_y[1]);
    end
    integer i;  // for looping over sprite signals

    // greeting ROM address
    logic [$clog2(G_ROM_DEPTH)-1:0] msg_start;
    always_comb begin
        greet_rom_addr = 0;
        msg_start = greeting * GREET_LENGTH;  // calculate start of message
        for (i = 0; i < SPR_CNT; i = i + 1) begin
            /* verilator lint_off WIDTH */
            if (sx == SPR_DMA+i)
                greet_rom_addr = (sy < LINE2) ? (msg_start+i) :
                                                (msg_start+i+GREET_LENGTH/2);
            /* verilator lint_on WIDTH */
        end
    end

    // load code point from greeting ROM
    logic [G_ROM_WIDTH-1:0] spr_cp [SPR_CNT];
    always_ff @(posedge clk_pix) begin
        for (i = 0; i < SPR_CNT; i = i + 1) begin
            /* verilator lint_off WIDTH */
            if (sx == SPR_DMA+i + 1) spr_cp[i] <= greet_rom_data;  // wait 1
            /* verilator lint_on WIDTH */
        end
    end

    // font ROM address
    logic [$clog2(F_ROM_DEPTH)-1:0] spr_glyph_addr [SPR_CNT];
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_0;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_1;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_2;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_3;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_4;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_5;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_6;
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line_7;
    logic spr_fdma [SPR_CNT];  // font ROM DMA slots
    always_comb begin
        font_rom_addr = 0;
        /* verilator lint_off WIDTH */
        for (i = 0; i < SPR_CNT; i = i + 1) begin
            spr_fdma[i] = (sx == SPR_DMA+i + 2);  // wait 2
            spr_glyph_addr[i] = (spr_cp[i] - CP_START) * FONT_HEIGHT;
        end
        if (spr_fdma[0]) font_rom_addr = spr_glyph_addr[0] + spr_glyph_line_0;
        if (spr_fdma[1]) font_rom_addr = spr_glyph_addr[1] + spr_glyph_line_1;
        if (spr_fdma[2]) font_rom_addr = spr_glyph_addr[2] + spr_glyph_line_2;
        if (spr_fdma[3]) font_rom_addr = spr_glyph_addr[3] + spr_glyph_line_3;
        if (spr_fdma[4]) font_rom_addr = spr_glyph_addr[4] + spr_glyph_line_4;
        if (spr_fdma[5]) font_rom_addr = spr_glyph_addr[5] + spr_glyph_line_5;
        if (spr_fdma[6]) font_rom_addr = spr_glyph_addr[6] + spr_glyph_line_6;
        if (spr_fdma[7]) font_rom_addr = spr_glyph_addr[7] + spr_glyph_line_7;
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
        .drawing(),
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
        .drawing(),
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
        .drawing(),
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
        .drawing(),
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
        .drawing(),
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
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr5 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[5]),
        .sx,
        .sprx(spr_x[5]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_5),
        .pix(spr_pix[5]),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
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
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr6 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[6]),
        .sx,
        .sprx(spr_x[6]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_6),
        .pix(spr_pix[6]),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
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
        .ADDRW($clog2(FONT_HEIGHT))
        ) spr7 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr_fdma[7]),
        .sx,
        .sprx(spr_x[7]),
        .data_in(font_rom_data),
        .pos(spr_glyph_line_7),
        .pix(spr_pix[7]),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
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

    // font colours
    localparam COLR_A   = 'h125;  // initial colour A
    localparam COLR_B   = 'h421;  // initial colour B
    localparam SLIN_1A  = 'd150;  // 1st line of colour A
    localparam SLIN_1B  = 'd178;  // 1st line of colour B
    localparam SLIN_2A  = 'd250;  // 2nd line of colour A
    localparam SLIN_2B  = 'd278;  // 2nd line of colour B
    localparam LINE_INC = 3;      // lines of each colour

    logic [11:0] font_colr;  // 12 bit colour (4-bit per channel)
    logic [$clog2(LINE_INC)-1:0] cnt_line;
    always_ff @(posedge clk_pix) begin
        if (line) begin
            if (sy == SLIN_1A || sy == SLIN_2A) begin
                cnt_line <= 0;
                font_colr <= COLR_A;
            end else if (sy == SLIN_1B || sy == SLIN_2B) begin
                cnt_line <= 0;
                font_colr <= COLR_B;
            end else begin
                cnt_line <= cnt_line + 1;
                if (cnt_line == LINE_INC-1) begin
                    cnt_line <= 0;
                    font_colr <= font_colr + 'h111;
                end
            end
        end
    end

    // sprite colour & star brightness
    logic [3:0] red_spr, green_spr, blue_spr, starlight;
    always_comb begin
        {red_spr, green_spr, blue_spr} = (spr_pix != 0) ? font_colr : 12'h000;
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
