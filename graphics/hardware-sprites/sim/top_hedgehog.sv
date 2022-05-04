// Project F: Hardware Sprites - Hedgehog (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_hedgehog #(parameter CORDW=16) (  // coordinate width
    input  wire logic clk_pix,      // pixel clock
    input  wire logic rst_pix,      // sim reset
    output      logic signed [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic signed [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,       // data enable (low in blanking interval)
    output      logic sdl_frame,    // high at start of frame
    output      logic [7:0] sdl_r,  // 8-bit red
    output      logic [7:0] sdl_g,  // 8-bit green
    output      logic [7:0] sdl_b   // 8-bit blue
    );

    // display sync signals and coordinates
    logic signed [CORDW-1:0] sx, sy;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de,
        .frame,
        .line
    );

    // screen dimensions (must match display_inst)
    localparam H_RES = 640;

    // colour parameters
    localparam CHANW = 4;         // colour channel width (bits)
    localparam COLRW = 3*CHANW;   // colour width: three channels (bits)
    localparam CIDXW = 4;         // colour index width (bits)
    localparam TRANS_INDX = 'h9;  // transparant colour index
    localparam PAL_FILE = "../res/palettes/hedgehog-12b.mem";  // palette file

    // sprite parameters
    localparam SX_OFFS    =  3;  // horizontal screen offset (pixels): +1 for CLUT
    localparam SPR_WIDTH  = 32;  // width in pixels
    localparam SPR_HEIGHT = 20;  // height in pixels
    localparam SPR_SCALE  =  2;  // 2^2 = 4x scale
    localparam SPR_DRAWW  = SPR_WIDTH * 2**SPR_SCALE;  // draw width
    localparam SPR_SPX    =  2;  // horizontal speed (pixels/frame)
    localparam SPR_FILE   = "../res/sprites/hedgehog.mem";  // sprite bitmap file

    logic signed [CORDW-1:0] sprx, spry;  // draw sprite at position (sprx,spry)

    // update sprite position once per frame
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (sprx <= -SPR_DRAWW) sprx <= H_RES;  // move back to right of screen
            else sprx <= sprx - SPR_SPX;  // otherwise keep moving left
        end
        if (rst_pix) begin  // start off screen and level with grass
            sprx <= H_RES;
            spry <= 240;
        end
    end

    logic drawing;  // drawing at (sx,sy)
    logic [CIDXW-1:0] spr_pix_indx;  // pixel colour index
    sprite_scale #(
        .CORDW(CORDW),
        .H_RES(H_RES),
        .SX_OFFS(SX_OFFS),
        .SPR_FILE(SPR_FILE),
        .SPR_WIDTH(SPR_WIDTH),
        .SPR_HEIGHT(SPR_HEIGHT),
        .SPR_SCALE(SPR_SCALE),
        .SPR_DATAW(CIDXW)
        ) sprite_hedgehog (
        .clk(clk_pix),
        .rst(rst_pix),
        .line,
        .sx,
        .sy,
        .sprx,
        .spry,
        .pix(spr_pix_indx),
        .drawing
    );

    // colour lookup table
    logic [COLRW-1:0] spr_pix_colr;
    clut_simple #(
        .COLRW(COLRW),
        .CIDXW(CIDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(0),
        .cidx_write(0),
        .cidx_read(spr_pix_indx),
        .colr_in(0),
        .colr_out(spr_pix_colr)
    );

    // account for transparency and delay drawing signal to match CLUT delay (1 cycle)
    logic drawing_t1;
    always_ff @(posedge clk_pix) drawing_t1 <= drawing && (spr_pix_indx != TRANS_INDX);

    // background colour
    logic [COLRW-1:0] bg_colr;
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

    // paint colours
    logic [CHANW-1:0] paint_r, paint_g, paint_b;
    always_comb {paint_r, paint_g, paint_b} = (drawing_t1) ? spr_pix_colr : bg_colr;

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_frame <= frame;
        sdl_r <= {2{paint_r}};  // double signal width (assumes CHANW=4)
        sdl_g <= {2{paint_g}};
        sdl_b <= {2{paint_b}};
    end
endmodule
