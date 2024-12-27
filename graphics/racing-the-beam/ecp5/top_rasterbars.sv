// Project F: Racing the Beam - Raster Bars (ULX3S)
// Copyright Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars (
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

    // screen dimensions (must match display_inst)
    localparam V_RES_FULL =  750;  // vertical screen resolution (including blanking)
    localparam H_RES      = 1280;  // horizontal screen resolution

    localparam START_COLR = 12'h126;  // bar start colour (blue: 12'h126) (gold: 12'h640)
    localparam COLR_NUM   = 10;       // colours steps in each bar (don't overflow)
    localparam LINE_NUM   =  4;       // lines of each colour

    logic [11:0] bar_colr;  // 12 bit colour (4 bits per channel)
    logic bar_inc;  // increase (or decrease) brightness
    logic [$clog2(COLR_NUM):0] cnt_colr;  // count colours in each bar
    logic [$clog2(LINE_NUM):0] cnt_line;  // count lines of each colour

    // update colour for each screen line
    always_ff @(posedge clk_pix) begin
        if (sx == H_RES) begin  // on each screen line at the start of blanking
            if (sy == V_RES_FULL-1) begin  // reset colour on last line of screen
                bar_colr <= START_COLR;
                bar_inc <= 1;  // start by increasing brightness
                cnt_colr <= 0;
                cnt_line <= 0;
            end else if (cnt_line == LINE_NUM-1) begin  // colour complete
                cnt_line <= 0;
                if (cnt_colr == COLR_NUM-1) begin  // switch increase/decrease
                    bar_inc <= ~bar_inc;
                    cnt_colr <= 0;
                end else begin
                    bar_colr <= (bar_inc) ? bar_colr + 12'h111 : bar_colr - 12'h111;
                    cnt_colr <= cnt_colr + 1;
                end
            end else cnt_line <= cnt_line + 1;
        end
    end

    // separate colour channels
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb {paint_r, paint_g, paint_b} = bar_colr;

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
        dvi_r <= {2{display_r}};
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
