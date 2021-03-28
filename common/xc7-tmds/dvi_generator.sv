// Project F: DVI Generator
// (C)2021 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module dvi_generator (
    input  wire logic clk_pix,
    input  wire logic clk_pix_5x,
    input  wire logic rst,
    input  wire logic de,                   // data enable (high when drawing)
    input  wire logic [7:0] data_in_ch0,    // channel 0 - data
    input  wire logic [7:0] data_in_ch1,    // channel 1 - data
    input  wire logic [7:0] data_in_ch2,    // channel 2 - data
    input  wire logic [1:0] ctrl_in_ch0,    // channel 0 - control
    input  wire logic [1:0] ctrl_in_ch1,    // channel 1 - control
    input  wire logic [1:0] ctrl_in_ch2,    // channel 2 - control
    output logic tmds_ch0_serial,           // channel 0 - serial TMDS
    output logic tmds_ch1_serial,           // channel 1 - serial TMDS
    output logic tmds_ch2_serial,           // channel 2 - serial TMDS
    output logic tmds_clk_serial            // clock - serial TMDS
    );

    logic [9:0] tmds_ch0, tmds_ch1, tmds_ch2;

    tmds_encoder_dvi encode_ch0 (
        .clk_pix,
        .rst,
        .data_in(data_in_ch0),
        .ctrl_in(ctrl_in_ch0),
        .de,
        .tmds(tmds_ch0)
    );

    tmds_encoder_dvi encode_ch1 (
        .clk_pix,
        .rst,
        .data_in(data_in_ch1),
        .ctrl_in(ctrl_in_ch1),
        .de,
        .tmds(tmds_ch1)
    );

    tmds_encoder_dvi encode_ch2 (
        .clk_pix,
        .rst,
        .data_in(data_in_ch2),
        .ctrl_in(ctrl_in_ch2),
        .de,
        .tmds(tmds_ch2)
    );

    // common async reset for serdes
    logic rst_oserdes;
    async_reset async_reset_inst (
        .clk(clk_pix),
        .rst_in(rst),
        .rst_out(rst_oserdes)
    );

    oserdes_10b serialize_ch0 (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_oserdes),
        .data_in(tmds_ch0),
        .serial_out(tmds_ch0_serial)
    );

    oserdes_10b serialize_ch1 (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_oserdes),
        .data_in(tmds_ch1),
        .serial_out(tmds_ch1_serial)
    );

    oserdes_10b serialize_ch2 (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_oserdes),
        .data_in(tmds_ch2),
        .serial_out(tmds_ch2_serial)
    );

    oserdes_10b serialize_chc (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_oserdes),
        .data_in(10'b0000011111),
        .serial_out(tmds_clk_serial)
    );

endmodule
