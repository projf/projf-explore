// Project F: Hardware Sprites - Hourglass (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_hourglass (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       /* verilator lint_off PINCONNECTEMPTY */
       .clk_pix_5x(),  // not used for VGA output
       /* verilator lint_on PINCONNECTEMPTY */
       .clk_pix_locked
    );

    // reset in pixel clock domain
    logic rst_pix;
    always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // screen coordinate width in bits
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

    // screen dimensions (must match display_inst)
    localparam H_RES = 640;

    // colour parameters
    localparam CHANW = 4;         // colour channel width (bits)
    localparam COLRW = 3*CHANW;   // colour width: three channels (bits)
    localparam INDXW = 4;         // colour index width (bits)
    localparam TRANS_INDX = 'h0;  // transparant colour index
    localparam BG_COLR = 'h137;   // background colour
    localparam PAL_FILE = "teleport16_4b.mem";  // palette file

    // sprite parameters
    localparam SX_OFFS    = 3;  // horizontal screen offset (pixels): +1 for CLUT
    localparam SPR_WIDTH  = 8;  // width in pixels
    localparam SPR_HEIGHT = 8;  // height in pixels
    localparam SPR_SCALE  = 4;  // 2^4 = 16x scale
    localparam SPR_FILE   = "hourglass.mem";  // sprite bitmap file

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

    // VGA Pmod output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        if (de) begin
            vga_r <= paint_r;
            vga_g <= paint_g;
            vga_b <= paint_b;
        end else begin  // VGA colour should be black in blanking interval
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
    end
endmodule
