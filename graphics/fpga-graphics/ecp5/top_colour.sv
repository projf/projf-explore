// Project F: FPGA Graphics - Colour Test (ULX3S)
// Copyright Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_colour (
    input  wire logic clk_25m,       // 25 MHz clock
    input  wire logic btn_rst_n,     // reset button
    output      logic [3:0] gpdi_dp  // DVI out
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_5x;
    logic clk_pix_locked;
    clock_720p clock_pix_inst (
       .clk_25m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x,
       .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 12;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_720p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // paint colour: based on screen position
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        if (sx < 512 && sy < 512) begin  // colour square in top-left 512x512 pixels
            paint_r = sx[8:5];  // 32 horizontal pixels of each red level
            paint_g = sy[8:5];  // 32 vertical pixels of each green level
            paint_b = 4'h4;     // constant blue level
        end else begin  // background colour
            paint_r = 4'h0;
            paint_g = 4'h1;
            paint_b = 4'h3;
        end
    end

    // display colour: paint colour but black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // DVI signals (8 bits per colour channel)
    logic [7:0] dvi_r, dvi_g, dvi_b;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de <= de;
        dvi_r <= {2{display_r}};  // double signal width from 4 to 8 bits
        dvi_g <= {2{display_g}};
        dvi_b <= {2{display_b}};
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst_pix(!clk_pix_locked),
        .de(dvi_de),
        .data_in_ch0(dvi_b),
        .data_in_ch1(dvi_g),
        .data_in_ch2(dvi_r),
        .ctrl_in_ch0({dvi_vsync, dvi_hsync}),
        .ctrl_in_ch1(2'b00),
        .ctrl_in_ch2(2'b00),
        .tmds_ch0_serial(gpdi_dp[0]),
        .tmds_ch1_serial(gpdi_dp[1]),
        .tmds_ch2_serial(gpdi_dp[2]),
        .tmds_clk_serial(gpdi_dp[3])
    );
endmodule
