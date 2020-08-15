// Project F: FPGA Ad Astra - Top Hello JP (iCEBreaker with 12-bit DVI Pmod)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none

module top_hello_jp (
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
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(dvi_hsync),
        .vsync(dvi_vsync),
        .de
    );

    // font ROM
    localparam FONT_WIDTH  = 16;  // width in pixels
    localparam FONT_HEIGHT = 16;  // number of lines
    localparam FONT_DEPTH  = 86 * FONT_HEIGHT;    // 86 chars
    localparam FONT_ADDRW  = $clog2(FONT_DEPTH);  // font ROM address width
    localparam FONT_INIT_F = "../font_unscii_16x16_hiragana.mem";

    logic [FONT_ADDRW-1:0] font_addr;
    logic [FONT_WIDTH-1:0] font_data;

    bram #(
        .INIT_F(FONT_INIT_F),
        .WIDTH(FONT_WIDTH),
        .DEPTH(FONT_DEPTH)
    ) font_rom (
        .clk(clk_pix),
        .addr(font_addr),
        .we(1'b0),
        .data_in(),
        .data(font_data)
    );

    // sprites - drawn position is one pixel left and down from sprite coordinate
    localparam SPR_SCALE_X = 4;  // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 4;  // enlarge sprite height by this factor

    logic spr_start;
    logic [FONT_ADDRW-1:0] spr0_gfx_addr, spr1_gfx_addr, spr2_gfx_addr, spr3_gfx_addr, spr4_gfx_addr;
    logic spr0_dma, spr0_pix, spr0_done;
    logic spr1_dma, spr1_pix, spr1_done;
    logic spr2_dma, spr2_pix, spr2_done;
    logic spr3_dma, spr3_pix, spr3_done;
    logic spr4_dma, spr4_pix, spr4_done;

    always_comb begin
        spr_start = (sy == 208 && sx == 0);
        spr0_dma = (sx >= 640 && sx < 642);  // 2 clock cycles
        spr1_dma = (sx >= 642 && sx < 644);
        spr2_dma = (sx >= 644 && sx < 646);
        spr3_dma = (sx >= 646 && sx < 648);
        spr4_dma = (sx >= 648 && sx < 650);

        font_addr = 0;
        if (spr0_dma) font_addr = spr0_gfx_addr;
        if (spr1_dma) font_addr = spr1_gfx_addr;
        if (spr2_dma) font_addr = spr2_gfx_addr;
        if (spr3_dma) font_addr = spr3_gfx_addr;
        if (spr4_dma) font_addr = spr4_gfx_addr;
    end

    // subtract 0x3041 from code points as font starts at U+3041
    localparam SPR0_CP = FONT_HEIGHT * 'h12; // こ U+3053
    localparam SPR1_CP = FONT_HEIGHT * 'h52; // ん U+3093
    localparam SPR2_CP = FONT_HEIGHT * 'h2A; // に U+306B
    localparam SPR3_CP = FONT_HEIGHT * 'h20; // ち U+3061
    localparam SPR4_CP = FONT_HEIGHT * 'h2E; // は U+306F

    sprite #(
        .LSB(0),
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .ADDRW(FONT_ADDRW),
        .CORDW(CORDW)
        ) spr0 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr0_dma),
        .sx,
        .sprx(158),
        .gfx_data(font_data),
        .gfx_addr_base(SPR0_CP),
        .gfx_addr(spr0_gfx_addr),
        .pix(spr0_pix),
        .done(spr0_done)
    );

    sprite #(
        .LSB(0),
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .ADDRW(FONT_ADDRW),
        .CORDW(CORDW)
        ) spr1 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr1_dma),
        .sx,
        .sprx(222),
        .gfx_data(font_data),
        .gfx_addr_base(SPR1_CP),
        .gfx_addr(spr1_gfx_addr),
        .pix(spr1_pix),
        .done(spr1_done)
    );

    sprite #(
        .LSB(0),
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .ADDRW(FONT_ADDRW),
        .CORDW(CORDW)
        ) spr2 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr2_dma),
        .sx,
        .sprx(286),
        .gfx_data(font_data),
        .gfx_addr_base(SPR2_CP),
        .gfx_addr(spr2_gfx_addr),
        .pix(spr2_pix),
        .done(spr2_done)
    );

    sprite #(
        .LSB(0),
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .ADDRW(FONT_ADDRW),
        .CORDW(CORDW)
        ) spr3 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr3_dma),
        .sx,
        .sprx(350),
        .gfx_data(font_data),
        .gfx_addr_base(SPR3_CP),
        .gfx_addr(spr3_gfx_addr),
        .pix(spr3_pix),
        .done(spr3_done)
    );

    sprite #(
        .LSB(0),
        .WIDTH(FONT_WIDTH),
        .HEIGHT(FONT_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .ADDRW(FONT_ADDRW),
        .CORDW(CORDW)
        ) spr4 (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .dma_avail(spr4_dma),
        .sx,
        .sprx(414),
        .gfx_data(font_data),
        .gfx_addr_base(SPR4_CP),
        .gfx_addr(spr4_gfx_addr),
        .pix(spr4_pix),
        .done(spr4_done)
    );

    // starfields
    logic sf1_on, sf2_on, sf3_on;
    logic [7:0] sf1_star, sf2_star, sf3_star;

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

    logic spr_on;
    logic [3:0] red_spr, green_spr, blue_spr, red_star, green_star, blue_star;
    always_comb begin
        spr_on = spr0_pix | spr1_pix | spr2_pix | spr3_pix | spr4_pix;
        red_spr    = (spr_on) ? 4'hF : 4'h0;
        green_spr  = (spr_on) ? 4'hC : 4'h0;
        blue_spr   = (spr_on) ? 4'h0 : 4'h0;
        red_star   = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                      sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
        green_star = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                      sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
        blue_star  = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                      sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
    end

    // DVI output
    always_comb begin
        dvi_clk = clk_pix;
        dvi_de  = de;
        dvi_r = (de) ? (spr_on) ? red_spr   : red_star   : 4'h0;
        dvi_g = (de) ? (spr_on) ? green_spr : green_star : 4'h0;
        dvi_b = (de) ? (spr_on) ? blue_spr  : blue_star  : 4'h0;
    end
endmodule
