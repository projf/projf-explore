// Project F: Ad Astra - Top Greetings v1 (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-ad-astra/

`default_nettype none
`timescale 1ns / 1ps

module top_greet_v1 (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       /* verilator lint_off PINCONNECTEMPTY */
       .clk_pix_5x(),  // not used for VGA output
       /* verilator lint_on PINCONNECTEMPTY */
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // greeting message ROM
    localparam GREET_MSGS   = 32;    // 32 messages
    localparam GREET_LENGTH = 16;    // each containing 16 code points
    localparam G_ROM_WIDTH  = $clog2('h5F);  // highest code point is U+005F
    localparam G_ROM_DEPTH  = GREET_MSGS * GREET_LENGTH;
    localparam GREET_FILE   = "greet.mem";

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
    localparam FONT_FILE   = "font_unscii_8x8_latin_uc.mem";

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
    logic [$clog2(FONT_HEIGHT)-1:0] spr_glyph_line [SPR_CNT];
    logic [SPR_CNT-1:0] spr_fdma;  // font ROM DMA slots
    always_comb begin
        font_rom_addr = 0;
        for (i = 0; i < SPR_CNT; i = i + 1) begin
            /* verilator lint_off WIDTH */
            spr_fdma[i] = (sx == SPR_DMA+i + 2);  // wait 2
            spr_glyph_addr[i] = (spr_cp[i] - CP_START) * FONT_HEIGHT;
            if (spr_fdma[i])
                font_rom_addr = spr_glyph_addr[i] + spr_glyph_line[i];
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
            .ADDRW($clog2(FONT_HEIGHT))
            ) spr0 (
            .clk(clk_pix),
            .rst(rst_pix),
            .start(spr_start),
            .dma_avail(spr_fdma[m]),
            .sx,
            .sprx(spr_x[m]),
            .data_in(font_rom_data),
            .pos(spr_glyph_line[m]),
            .pix(spr_pix[m]),
            /* verilator lint_off PINCONNECTEMPTY */
            .drawing(),
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
        .rst(rst_pix),
        .sf_on(sf1_on),
        .sf_star(sf1_star)
    );

    starfield #(.INC(-2), .SEED(21'hA9A9A)) sf2 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(rst_pix),
        .sf_on(sf2_on),
        .sf_star(sf2_star)
    );

    starfield #(.INC(-4), .MASK(21'h7FF)) sf3 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(rst_pix),
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
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= de ? (spr_pix != 0) ? red_spr   : starlight : 4'h0;
        vga_g <= de ? (spr_pix != 0) ? green_spr : starlight : 4'h0;
        vga_b <= de ? (spr_pix != 0) ? blue_spr  : starlight : 4'h0;
    end
endmodule
