// Project F: Hardware Sprites - Top Hedgehog (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_hedgehog (
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
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 16;  // screen coordinate width in bits
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix(!clk_locked),  // wait for clock lock
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
    localparam SPR_FILE     = "hedgehog_walk.mem";
    localparam SPR_PALETTE  = "hedgehog_palette.mem";

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
    always_ff @(posedge clk_pix) begin
        if (line) begin
            if      (sy == 0)   bg_colr <= 12'h239;
            else if (sy == 80)  bg_colr <= 12'h24A;
            else if (sy == 140) bg_colr <= 12'h25B;
            else if (sy == 190) bg_colr <= 12'h26C;
            else if (sy == 230) bg_colr <= 12'h27D;
            else if (sy == 265) bg_colr <= 12'h29E;
            else if (sy == 295) bg_colr <= 12'h2BF;
            else if (sy == 320) bg_colr <= 12'h260;
        end
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

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= de ? red   : 4'h0;
        vga_g <= de ? green : 4'h0;
        vga_b <= de ? blue  : 4'h0;
    end
endmodule
