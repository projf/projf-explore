// Project F: FPGA Ad Astra - Top Hello EN (lichee Tang with LCD)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_hello_en (
    input  wire logic clk_24m,      // 24 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
	output      logic lcd_clk,
	output      logic lcd_den,
	output      logic lcd_pwm,
    output      logic lcd_hsync,    // horizontal sync
    output      logic lcd_vsync,    // vertical sync
    output      logic [7:0] lcd_r,  // 8-bit LCD red
    output      logic [7:0] lcd_g,  // 8-bit LCD green
    output      logic [7:0] lcd_b   // 8-bit LCD blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_800x480 (
       .clk(clk_24m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    display_timings #(
		.HACTIVE(800), .HFP(24), .HSYNC(72), .HBP(96),
		.VACTIVE(480), .VFP(3), .VSYNC(7), .VBP(10)
	) timings_800x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(lcd_hsync),
        .vsync(lcd_vsync),
        .de(lcd_den)
    );

    // font ROM
    localparam FONT_WIDTH  = 8;  // width in pixels
    localparam FONT_HEIGHT = 8;  // number of lines
    localparam FONT_DEPTH  = 64 * FONT_HEIGHT;    // 64 chars
    localparam FONT_ADDRW  = $clog2(FONT_DEPTH);  // font ROM address width
    localparam FONT_INIT_F = "../font_unscii_8x8_latin_uc.mem";

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
    localparam SPR_SCALE_X = 8;  // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 8;  // enlarge sprite height by this factor

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

    // subtract 0x20 from code points as font starts at U+0020
    localparam SPR0_CP = FONT_HEIGHT * 'h28; // H U+0048
    localparam SPR1_CP = FONT_HEIGHT * 'h25; // E U+0045
    localparam SPR2_CP = FONT_HEIGHT * 'h2C; // L U+004C
    localparam SPR3_CP = FONT_HEIGHT * 'h2C; // L U+004C
    localparam SPR4_CP = FONT_HEIGHT * 'h2F; // O U+004F

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

	localparam VSIZE = 500;
	localparam HSIZE = 992;

    // starfields
    logic sf1_on, sf2_on, sf3_on;
    logic [7:0] sf1_star, sf2_star, sf3_star;

    starfield #(.H(HSIZE), .V(VSIZE), .INC(-1), .SEED(21'h9A9A9)) sf1 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf1_on),
        .sf_star(sf1_star)
    );

    starfield #(.H(HSIZE), .V(VSIZE), .INC(-2), .SEED(21'hA9A9A)) sf2 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf2_on),
        .sf_star(sf2_star)
    );

    starfield #(.H(HSIZE), .V(VSIZE), .INC(-4), .MASK(21'h7FF)) sf3 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_locked),
        .sf_on(sf3_on),
        .sf_star(sf3_star)
    );

    logic spr_on;
    logic [7:0] red_spr, green_spr, blue_spr;
    logic [3:0] red_star, green_star, blue_star;
    always_comb begin
        spr_on = spr0_pix | spr1_pix | spr2_pix | spr3_pix | spr4_pix;
        red_spr    = (spr_on) ? 8'hFF : 8'h0;
        green_spr  = (spr_on) ? 8'hCF : 8'h0;
        blue_spr   = (spr_on) ? 8'h00 : 8'h0;
        red_star   = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                      sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
        green_star = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                      sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
        blue_star  = (sf1_on) ? sf1_star[7:4] : (sf2_on) ?
                      sf2_star[7:4] : (sf3_on) ? sf3_star[7:4] : 4'h0;
    end

    // LCD output
    always_comb begin
		lcd_clk = clk_pix;
		lcd_pwm = 1;
        lcd_r = (lcd_den) ? (spr_on) ? red_spr   : {red_star, 4'hf}   : 8'h0;
        lcd_g = (lcd_den) ? (spr_on) ? green_spr : {green_star, 4'hf} : 8'h0;
        lcd_b = (lcd_den) ? (spr_on) ? blue_spr  : {blue_star, 4'hf}  : 8'h0;
    end
endmodule
