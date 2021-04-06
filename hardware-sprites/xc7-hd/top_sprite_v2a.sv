// Project F: Hardware Sprites - Top Sprite v2a (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v2a (
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
    localparam H_RES = 1280;
    localparam V_RES = 720;
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_720p display_timings_inst (
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

    // sprite
    localparam SPR_WIDTH   = 8;   // width in pixels
    localparam SPR_HEIGHT  = 8;   // number of lines
    localparam SPR_SCALE_X = 12;  // width scale-factor
    localparam SPR_SCALE_Y = 12;  // height scale-factor
    localparam SPR_FILE = "saucer.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam SPR_SPEED_X = 8;
    localparam SPR_SPEED_Y = 0;
    logic signed [CORDW-1:0] sprx, spry;
    logic dx;  // direction: 0 is right/down

    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (sprx >= H_RES - (SPR_SPEED_X + SPR_WIDTH * SPR_SCALE_X)) begin  // right edge
                dx <= 1;
                sprx <= sprx - SPR_SPEED_X;
            end else if (sprx < SPR_SPEED_X) begin  // left edge
                dx <= 0;
                sprx <= sprx + SPR_SPEED_X;
            end else sprx <= (dx) ? sprx - SPR_SPEED_X : sprx + SPR_SPEED_X;
        end
        if (!clk_pix_locked) begin
            sprx <= 592;
            spry <= 312;
            dx <= 0;
        end
    end

    // signal to start sprite drawing
    always_comb spr_start = (line && sy == spry);

    sprite_v2 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .SPR_FILE(SPR_FILE)
        ) spr_instance (
        .clk(clk_pix),
        .rst(!clk_pix_locked),
        .start(spr_start),
        .sx,
        .sprx,
        .pix(spr_pix)
    );

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de    <= de;
        dvi_red   <= (de && spr_pix) ? 8'hFF: 8'h00;
        dvi_green <= (de && spr_pix) ? 8'hCC: 8'h00;
        dvi_blue  <= (de && spr_pix) ? 8'h00: 8'h00;
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
