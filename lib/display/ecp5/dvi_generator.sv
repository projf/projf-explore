// Project F Library - DVI Generator (ECP5)
// Copyright Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module dvi_generator (
    input  wire logic clk_pix,
    input  wire logic clk_pix_5x,
    input  wire logic rst_pix,
    input  wire logic de,                 // data enable (high when drawing)
    input  wire logic [7:0] data_in_ch0,  // channel 0 - data
    input  wire logic [7:0] data_in_ch1,  // channel 1 - data
    input  wire logic [7:0] data_in_ch2,  // channel 2 - data
    input  wire logic [1:0] ctrl_in_ch0,  // channel 0 - control
    input  wire logic [1:0] ctrl_in_ch1,  // channel 1 - control
    input  wire logic [1:0] ctrl_in_ch2,  // channel 2 - control
    output logic tmds_ch0_serial,         // channel 0 - serial TMDS
    output logic tmds_ch1_serial,         // channel 1 - serial TMDS
    output logic tmds_ch2_serial,         // channel 2 - serial TMDS
    output logic tmds_clk_serial          // clock - serial TMDS
    );

    logic [9:0] tmds_ch0, tmds_ch1, tmds_ch2;

    tmds_encoder_dvi encode_ch0 (
        .clk_pix,
        .rst_pix,
        .data_in(data_in_ch0),
        .ctrl_in(ctrl_in_ch0),
        .de,
        .tmds(tmds_ch0)
    );

    tmds_encoder_dvi encode_ch1 (
        .clk_pix,
        .rst_pix,
        .data_in(data_in_ch1),
        .ctrl_in(ctrl_in_ch1),
        .de,
        .tmds(tmds_ch1)
    );

    tmds_encoder_dvi encode_ch2 (
        .clk_pix,
        .rst_pix,
        .data_in(data_in_ch2),
        .ctrl_in(ctrl_in_ch2),
        .de,
        .tmds(tmds_ch2)
    );

    logic [9:0] tmds_ch0_shift, tmds_ch1_shift, tmds_ch2_shift;
    logic [4:0] shift5 = 1;  // 5-bit circular shift buffer
    always_ff @(posedge clk_pix_5x) begin
        shift5 <= {shift5[3:0], shift5[4]};
        tmds_ch0_shift <= shift5[4] ? tmds_ch0 : tmds_ch0_shift >> 2;  // shift two bits for DDR
        tmds_ch1_shift <= shift5[4] ? tmds_ch1 : tmds_ch1_shift >> 2;
        tmds_ch2_shift <= shift5[4] ? tmds_ch2 : tmds_ch2_shift >> 2;
    end

    ODDRX1F serialize_ch0 (.D0(tmds_ch0_shift[0]), .D1(tmds_ch0_shift[1]), .Q(tmds_ch0_serial), .SCLK(clk_pix_5x), .RST(0));
    ODDRX1F serialize_ch1 (.D0(tmds_ch1_shift[0]), .D1(tmds_ch1_shift[1]), .Q(tmds_ch1_serial), .SCLK(clk_pix_5x), .RST(0));
    ODDRX1F serialize_ch2 (.D0(tmds_ch2_shift[0]), .D1(tmds_ch2_shift[1]), .Q(tmds_ch2_serial), .SCLK(clk_pix_5x), .RST(0));

    always_comb tmds_clk_serial = clk_pix;  // clock isn't following same path as other channels
endmodule
