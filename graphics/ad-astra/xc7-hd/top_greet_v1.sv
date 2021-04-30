// Project F: Ad Astra - Top Greetings v1 (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_greet_v1 (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst,          // reset button (active low)
    output      logic hdmi_tx_ch0_p,    // HDMI source channel 0 diff+
    output      logic hdmi_tx_ch0_n,    // HDMI source channel 0 diff-
    output      logic hdmi_tx_ch1_p,    // HDMI source channel 1 diff+
    output      logic hdmi_tx_ch1_n,    // HDMI source channel 1 diff-
    output      logic hdmi_tx_ch2_p,    // HDMI source channel 2 diff+
    output      logic hdmi_tx_ch2_n,    // HDMI source channel 2 diff-
    output      logic hdmi_tx_clk_p,    // HDMI source clock diff+
    output      logic hdmi_tx_clk_n     // HDMI source clock diff-
    );

    // generate pixel clocks
    logic clk_pix;                  // pixel clock
    logic clk_pix_5x;               // 5x pixel clock for 10:1 DDR SerDes
    logic clk_pix_locked;           // pixel clock locked?
    clock_gen_720p clock_pix_inst (
        .clk_100m,
        .rst(!btn_rst),             // reset button is active low
        .clk_pix,
        .clk_pix_5x,
        .clk_pix_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_720p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_pix_locked),  // wait for pixel clock lock
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
    localparam V_RES = 720;        // vertical screen resolution
    localparam SPR_CNT = 8;        // number of sprites
    localparam LINE2 = V_RES / 2;  // where to consider second line of sprites
    localparam SPR_SCALE_X = 16;   // enlarge sprite width by this factor
    localparam SPR_SCALE_Y = 16;   // enlarge sprite height by this factor
    localparam SPR_DMA = 0 - 2*SPR_CNT;  // start sprite DMA in h-blanking

    // horizontal and vertical screen position of letters
    logic signed [CORDW-1:0] spr_x [SPR_CNT];
    logic signed [CORDW-1:0] spr_y [2];  // 2 lines of sprites
    initial begin
        spr_x[0] = 128;
        spr_x[1] = 256;
        spr_x[2] = 384;
        spr_x[3] = 512;
        spr_x[4] = 640;
        spr_x[5] = 768;
        spr_x[6] = 896;
        spr_x[7] = 1024;

        spr_y[0] = 225;
        spr_y[1] = 375;
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
            .rst(!clk_pix_locked),
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

    starfield #(.H(1650), .V(750), .INC(-1), .SEED(21'h9A9A9)) sf1 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_pix_locked),
        .sf_on(sf1_on),
        .sf_star(sf1_star)
    );

    starfield #(.H(1650), .V(750), .INC(-2), .SEED(21'hA9A9A)) sf2 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_pix_locked),
        .sf_on(sf2_on),
        .sf_star(sf2_star)
    );

    starfield #(.H(1650), .V(750), .INC(-4), .MASK(21'h7FF)) sf3 (
        .clk(clk_pix),
        .en(1'b1),
        .rst(!clk_pix_locked),
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

    // pixel colour components
    logic [3:0] red, green, blue;
    always_comb begin
        red   = de ? (spr_pix != 0) ? red_spr   : starlight : 4'h0;
        green = de ? (spr_pix != 0) ? green_spr : starlight : 4'h0;
        blue  = de ? (spr_pix != 0) ? blue_spr  : starlight : 4'h0;
    end

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de    <= de;
        dvi_red   <= {red,red};  // double up: our output is 8 bit per channel
        dvi_green <= {green,green};
        dvi_blue  <= {blue,blue};
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst(!clk_pix_locked),
        .de(dvi_de),
        .data_in_ch0(dvi_blue),
        .data_in_ch1(dvi_green),
        .data_in_ch2(dvi_red),
        .ctrl_in_ch0({dvi_vsync, dvi_hsync}),
        .ctrl_in_ch1(2'b00),
        .ctrl_in_ch2(2'b00),
        .tmds_ch0_serial,
        .tmds_ch1_serial,
        .tmds_ch2_serial,
        .tmds_clk_serial
    );

    // TMDS output pins
    tmds_out tmds_ch0 (.tmds(tmds_ch0_serial),
        .pin_p(hdmi_tx_ch0_p), .pin_n(hdmi_tx_ch0_n));
    tmds_out tmds_ch1 (.tmds(tmds_ch1_serial),
        .pin_p(hdmi_tx_ch1_p), .pin_n(hdmi_tx_ch1_n));
    tmds_out tmds_ch2 (.tmds(tmds_ch2_serial),
        .pin_p(hdmi_tx_ch2_p), .pin_n(hdmi_tx_ch2_n));
    tmds_out tmds_clk (.tmds(tmds_clk_serial),
        .pin_p(hdmi_tx_clk_p), .pin_n(hdmi_tx_clk_n));
endmodule
