// Project F: Hardware Sprites - Top Hedgehog v1 (iCEBreaker with 12-bit DVI Pmod)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps
`timescale 1ns / 1ps

module top_hedgehog_v1 (
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

    logic animate;  // high for one clock tick at start of blanking
    always_comb animate = (sy == V_RES && sx == 0);

    // sprite
    localparam SPR_WIDTH    = 32;   // width in pixels
    localparam SPR_HEIGHT   = 20;   // number of lines
    localparam SPR_SCALE_X  = 4;    // width scale-factor
    localparam SPR_SCALE_Y  = 4;    // height scale-factor
    localparam COLR_BITS    = 4;    // bits per pixel (2^4=16 colours)
    localparam SPR_TRANS    = 9;    // transparent palette entry
    localparam SPR_FRAMES   = 1;    // number of frames in graphic
    localparam SPR_FILE     = "../res/hedgehog/hedgehog.mem";
    localparam SPR_PALETTE  = "../res/hedgehog/hedgehog_palette.mem";

    localparam SPR_PIXELS = SPR_WIDTH * SPR_HEIGHT;
    localparam SPR_DEPTH  = SPR_PIXELS * SPR_FRAMES;
    localparam SPR_ADDRW  = $clog2(SPR_DEPTH);

    logic spr_start, spr_draw;
    logic [COLR_BITS-1:0] spr_pix;

    // sprite ROM
    logic [COLR_BITS-1:0] spr_rom_data;
    logic [SPR_ADDRW-1:0] spr_rom_addr;
    rom_sync #(
        .WIDTH(COLR_BITS),
        .DEPTH(SPR_DEPTH),
        .INIT_F(SPR_FILE)
    ) spr_rom (
        .clk(clk_pix),
        .addr(spr_rom_addr),
        .data(spr_rom_data)
    );

    // draw sprite at position
    localparam SPR_SPEED_X = 2;
    localparam SPR_SPEED_Y = 0;
    logic [CORDW-1:0] sprx, spry;

    always_ff @(posedge clk_pix) begin
        if (animate) begin
            // walk right-to-left (correct position for screen width)
            sprx <= (sprx > SPR_SPEED_X) ? sprx - SPR_SPEED_X : 
                                           H_RES_FULL - (SPR_SPEED_X - sprx);
        end
        if (!clk_locked) begin
            sprx <= 0;
            spry <= 200;
        end
    end

    // start sprite in blanking of line before first line drawn
    logic [CORDW-1:0] spry_cor;  // corrected for wrapping
    always_comb begin
        spry_cor = (spry == 0) ? V_RES_FULL - 1 : spry - 1;
        spr_start = (sy == spry_cor && sx == H_RES);
    end

    sprite #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .COLR_BITS(COLR_BITS),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .ADDRW(SPR_ADDRW)
        ) spr_instance (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .sx,
        .sprx,
        .data_in(spr_rom_data),
        .pos(spr_rom_addr),
        .pix(spr_pix),
        .draw(spr_draw),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // Colour Lookup Table
    logic [11:0] clut [11];  // 11 x 12-bit colour palette entries
    initial begin
        $display("Loading palette '%s' into CLUT.", SPR_PALETTE);
        $readmemh(SPR_PALETTE, clut);  // load palette into CLUT
    end

    // map colour index to palette using CLUT
    logic pix_trans;  // pixel transparent?
    logic [3:0] red_spr, green_spr, blue_spr;  // pixel colour components
    always_comb begin
        pix_trans = (spr_pix == SPR_TRANS);
        {red_spr, green_spr, blue_spr} = clut[spr_pix];
    end

    // generate final colours adjusting for transparency
    logic [3:0] red, green, blue;
    always_comb begin
        red   = (de && spr_draw && !pix_trans) ? red_spr   : 4'h0;
        green = (de && spr_draw && !pix_trans) ? green_spr : 4'h0;
        blue  = (de && spr_draw && !pix_trans) ? blue_spr  : 4'h0;
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
