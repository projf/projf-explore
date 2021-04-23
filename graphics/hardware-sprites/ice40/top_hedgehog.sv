// Project F: Hardware Sprites - Top Hedgehog (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_hedgehog (
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
    logic de, frame, line;
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

    // sprite
    localparam SPR_WIDTH    = 32;   // width in pixels
    localparam SPR_HEIGHT   = 20;   // number of lines
    localparam SPR_SCALE_X  = 4;    // width scale-factor
    localparam SPR_SCALE_Y  = 4;    // height scale-factor
    localparam COLR_BITS    = 4;    // bits per pixel (2^4=16 colours)
    localparam SPR_TRANS    = 9;    // transparent palette entry
    localparam SPR_FRAMES   = 3;    // number of frames in graphic
    localparam SPR_FILE     = "../res/hedgehog/hedgehog_walk.mem";
    localparam SPR_PALETTE  = "../res/hedgehog/hedgehog_palette.mem";

    localparam SPR_PIXELS = SPR_WIDTH * SPR_HEIGHT;
    localparam SPR_DEPTH  = SPR_PIXELS * SPR_FRAMES;
    localparam SPR_ADDRW  = $clog2(SPR_DEPTH);

    logic spr_start, spr_drawing;
    logic [COLR_BITS-1:0] spr_pix;

    // sprite graphic ROM
    logic [COLR_BITS-1:0] spr_rom_data;
    logic [SPR_ADDRW-1:0] spr_rom_addr, spr_base_addr;
    rom_sync #(
        .WIDTH(COLR_BITS),
        .DEPTH(SPR_DEPTH),
        .INIT_F(SPR_FILE)
    ) spr_rom (
        .clk(clk_pix),
        .addr(spr_base_addr + spr_rom_addr),
        .data(spr_rom_data)
    );

    // draw sprite at position
    localparam H_RES = 640;
    localparam SPR_SPEED_X = 2;
    logic signed [CORDW-1:0] sprx, spry;

    // sprite frame selector
    logic [5:0] cnt_anim;  // count from 0-63
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            // select sprite frame
            cnt_anim <= cnt_anim + 1;
            case (cnt_anim)
                0: spr_base_addr <= 0;
                15: spr_base_addr <= SPR_PIXELS;
                31: spr_base_addr <= 0;
                47: spr_base_addr <= 2 * SPR_PIXELS;
                default: spr_base_addr <= spr_base_addr;
            endcase

            // walk right-to-left: -132 covers sprite width and within blanking
            sprx <= (sprx > -132) ? sprx - SPR_SPEED_X : H_RES;
        end
        if (!clk_locked) begin
            sprx <= H_RES;
            spry <= 240;
        end
    end

    // signal to start sprite drawing
    always_comb spr_start = (line && sy == spry);

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
        .drawing(spr_drawing),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // background colour
    logic [11:0] bg_colr;
    always_comb begin
        bg_colr = 12'h260;  // default
        if (sy < 80)       bg_colr = 12'h239;
        else if (sy < 140) bg_colr = 12'h24A;
        else if (sy < 190) bg_colr = 12'h25B;
        else if (sy < 230) bg_colr = 12'h26C;
        else if (sy < 265) bg_colr = 12'h27D;
        else if (sy < 295) bg_colr = 12'h29E;
        else if (sy < 320) bg_colr = 12'h2BF;
    end

    // colour lookup table (ROM) 11x12-bit entries
    logic [11:0] clut_colr;
    rom_async #(
        .WIDTH(12),
        .DEPTH(11),
        .INIT_F(SPR_PALETTE)
    ) clut (
        .addr(spr_pix),
        .data(clut_colr)
    );

    // map sprite colour index to palette using CLUT and incorporate background
    logic spr_trans;  // sprite pixel transparent?
    logic [3:0] red_spr, green_spr, blue_spr;  // sprite colour components
    logic [3:0] red_bg,  green_bg,  blue_bg;   // background colour components
    logic [3:0] red, green, blue;              // final colour
    always_comb begin
        spr_trans = (spr_pix == SPR_TRANS);
        {red_spr, green_spr, blue_spr} = clut_colr;
        {red_bg,  green_bg,  blue_bg}  = bg_colr;
        red   = (spr_drawing && !spr_trans) ? red_spr   : red_bg;
        green = (spr_drawing && !spr_trans) ? green_spr : green_bg;
        blue  = (spr_drawing && !spr_trans) ? blue_spr  : blue_bg;
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
