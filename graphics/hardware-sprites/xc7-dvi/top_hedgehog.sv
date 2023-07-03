// Project F: Hardware Sprites - Hedgehog (Nexys Video)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_hedgehog (
    input  wire logic clk_100m,       // 100 MHz clock
    input  wire logic btn_rst_n,      // reset button
    output      logic hdmi_tx_ch0_p,  // HDMI source channel 0 diff+
    output      logic hdmi_tx_ch0_n,  // HDMI source channel 0 diff-
    output      logic hdmi_tx_ch1_p,  // HDMI source channel 1 diff+
    output      logic hdmi_tx_ch1_n,  // HDMI source channel 1 diff-
    output      logic hdmi_tx_ch2_p,  // HDMI source channel 2 diff+
    output      logic hdmi_tx_ch2_n,  // HDMI source channel 2 diff-
    output      logic hdmi_tx_clk_p,  // HDMI source clock diff+
    output      logic hdmi_tx_clk_n   // HDMI source clock diff-
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_5x;
    logic clk_pix_locked;
    logic rst_pix;
    clock_720p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x,
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_720p #(.CORDW(CORDW)) display_inst (
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
    localparam H_RES = 1280;

    // colour parameters
    localparam CHANW = 4;         // colour channel width (bits)
    localparam COLRW = 3*CHANW;   // colour width: three channels (bits)
    localparam CIDXW = 4;         // colour index width (bits)
    localparam TRANS_INDX = 'h9;  // transparant colour index
    localparam PAL_FILE = "hedgehog_4b.mem";  // palette file

    // sprite parameters
    localparam SX_OFFS    =  3;  // horizontal screen offset (pixels): +1 for CLUT
    localparam SPR_WIDTH  = 32;  // bitmap width in pixels
    localparam SPR_HEIGHT = 20;  // bitmap height in pixels
    localparam SPR_SCALE  =  3;  // 2^3 = 8x scale
    localparam SPR_DRAWW  = SPR_WIDTH * 2**SPR_SCALE;  // draw width
    localparam SPR_SPX    =  4;  // horizontal speed (pixels/frame)
    localparam SPR_FILE   = "hedgehog.mem";  // bitmap file

    logic signed [CORDW-1:0] sprx, spry;  // draw sprite at position (sprx,spry)

    // update sprite position once per frame
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (sprx <= -SPR_DRAWW) sprx <= H_RES;  // move back to right of screen
            else sprx <= sprx - SPR_SPX;  // otherwise keep moving left
        end
        if (rst_pix) begin  // start off screen and level with grass
            sprx <= H_RES;
            spry <= 320;
        end
    end

    logic drawing;  // drawing at (sx,sy)
    logic [CIDXW-1:0] spr_pix_indx;  // pixel colour index
    sprite #(
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
            else if (sy == 120) bg_colr <= 12'h24A;
            else if (sy == 220) bg_colr <= 12'h25B;
            else if (sy == 300) bg_colr <= 12'h26C;
            else if (sy == 360) bg_colr <= 12'h27D;
            else if (sy == 410) bg_colr <= 12'h29E;
            else if (sy == 450) bg_colr <= 12'h2BF;
            else if (sy == 480) bg_colr <= 12'h260;
        end
    end

    // paint colour: sprite or background
    logic [CHANW-1:0] paint_r, paint_g, paint_b;
    always_comb {paint_r, paint_g, paint_b} = (drawing_t1) ? spr_pix_colr : bg_colr;

    // display colour: paint colour but black in blanking interval
    logic [CHANW-1:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // DVI signals (8 bits per colour channel)
    logic [2*CHANW-1:0] dvi_r, dvi_g, dvi_b;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de    <= de;
        dvi_r <= {2{display_r}};
        dvi_g <= {2{display_g}};
        dvi_b <= {2{display_b}};
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst_pix,
        .de(dvi_de),
        .data_in_ch0(dvi_b),
        .data_in_ch1(dvi_g),
        .data_in_ch2(dvi_r),
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
