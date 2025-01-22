// Project F: Racing the Beam - Hitomezashi (ULX3S)
// Copyright Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hitomezashi (
    input  wire logic clk_25m,       // 25 MHz clock
    input  wire logic btn_rst_n,     // reset button
    output      logic [3:0] gpdi_dp  // DVI out
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_5x;
    logic clk_pix_locked;
    clock2_gen #(  // 74 MHz (PLL can't do exact 74.25 MHz for 720p)
        .CLKI_DIV(5),
        .CLKFB_DIV(74),
        .CLKOP_DIV(2),
        .CLKOS_DIV(10)
    ) clock2_gen_inst (
       .clk_in(clk_25m),
       .clk_5x_out(clk_pix_5x),
       .clk_out(clk_pix),
       .clk_locked(clk_pix_locked)
    );

    // display sync signals and coordinates
    localparam CORDW = 12;  // screen coordinate width in bits
    /* verilator lint_off UNUSED */
    logic [CORDW-1:0] sx, sy;
    /* verilator lint_on UNUSED */
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

    // stitch start values: MSB first, so we can write left to right
    /* verilator lint_off LITENDIAN */
    logic [0:39] v_start;  // 40 vertical lines
    logic [0:21] h_start;  // 22 horizontal lines
    /* verilator lint_on LITENDIAN */

    initial begin  // random start values
        v_start = 40'b01100_00101_00110_10011_10101_10101_01111_01101;
        h_start = 22'b10111_01001_00001_10100_00;
    end

    // paint stitch pattern with 32x32 pixel grid
    logic stitch;
    logic v_line, v_on;
    logic h_line, h_on;
    logic last_h_stitch;
    always_comb begin
        v_line = (sx[4:0] == 5'b00000);
        h_line = (sy[4:0] == 5'b00000);
        v_on = sy[5] ^ v_start[sx[10:5]];
        h_on = sx[5] ^ h_start[sy[9:5]];
        stitch = (v_line && v_on) || (h_line && h_on) || last_h_stitch;
    end

    // last stich fix thanks to Serg Ko (@vfr1200f)
    always_ff @(posedge clk_pix) last_h_stitch <= h_line && h_on;

    // paint colour: yellow lines, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (stitch) ? 4'hF : 4'h1;
        paint_g = (stitch) ? 4'hC : 4'h3;
        paint_b = (stitch) ? 4'h0 : 4'h7;
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
