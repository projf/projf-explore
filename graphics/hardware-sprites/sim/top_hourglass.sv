// Project F: Hardware Sprites - Hourglass (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_hourglass #(parameter CORDW=16) (  // coordinate width
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
    localparam INDXW = 4;         // colour index width (bits)
    localparam TRANS_INDX = 'h0;  // transparant colour index
    localparam BG_COLR = 'h137;   // background colour
    localparam PAL_FILE = "../res/palettes/step-12b.mem";  // palette file

    // sprite parameters
    localparam SX_OFFS    = 3;  // horizontal screen offset (pixels): +1 for CLUT
    localparam SPR_WIDTH  = 8;  // width in pixels
    localparam SPR_HEIGHT = 8;  // height in pixels
    localparam SPR_SCALE  = 4;  // 2^4 = 16x scale
    localparam SPR_FILE   = "../res/sprites/hourglass.mem";  // sprite bitmap file

    logic drawing;  // drawing at (sx,sy)
    logic [INDXW-1:0] spr_pix_indx;  // pixel colour index
    sprite_scale #(
        .CORDW(CORDW),
        .H_RES(H_RES),
        .SX_OFFS(SX_OFFS),
        .SPR_FILE(SPR_FILE),
        .SPR_WIDTH(SPR_WIDTH),
        .SPR_HEIGHT(SPR_HEIGHT),
        .SPR_SCALE(SPR_SCALE),
        .SPR_DATAW(INDXW)
        ) sprite_hourglass (
        .clk(clk_pix),
        .rst(rst_pix),
        .line,
        .sx,
        .sy,
        .sprx(32),
        .spry(16),
        .pix(spr_pix_indx),
        .drawing
    );

    // frame counter to rotate sprite colours
    localparam FRAME_NUM = 15;  // rotate colour every N frames
    logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
    logic [INDXW-1:0] indx_offs;  // pixel colour offset
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            cnt_frame <= (cnt_frame == FRAME_NUM-1) ? 0 : cnt_frame + 1;
            if (cnt_frame == 0) indx_offs <= indx_offs - 1;
        end
    end

    // colour lookup table
    logic [COLRW-1:0] spr_pix_colr;
    clut_simple #(
        .COLRW(COLRW),
        .INDXW(INDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(0),
        .indx_write(0),
        .indx_read(spr_pix_indx + indx_offs),
        .colr_in(0),
        .colr_out(spr_pix_colr)
    );

    // account for transparency and delay drawing signal to match CLUT delay (1 cycle)
    logic drawing_t1;
    always_ff @(posedge clk_pix) drawing_t1 <= drawing && (spr_pix_indx != TRANS_INDX);

    // paint colours
    logic [CHANW-1:0] paint_r, paint_g, paint_b;
    always_comb {paint_r, paint_g, paint_b} = (drawing_t1) ? spr_pix_colr : BG_COLR;

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
