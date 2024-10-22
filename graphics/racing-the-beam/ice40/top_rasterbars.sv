// Project F: Racing the Beam - Raster Bars (iCEBreaker 12-bit DVI Pmod)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    clock_480p clock_pix_inst (
       .clk_12m,
       .rst(btn_rst),
       .clk_pix,
       .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // screen dimensions (must match display_inst)
    localparam V_RES_FULL = 525;  // vertical screen resolution (including blanking)
    localparam H_RES      = 640;  // horizontal screen resolution

    localparam START_COLR = 12'h126;  // bar start colour (blue: 12'h126) (gold: 12'h640)
    localparam COLR_NUM   = 10;       // colours steps in each bar (don't overflow)
    localparam LINE_NUM   =  2;       // lines of each colour

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

    // DVI Pmod output
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, display_r, display_g, display_b}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // DVI Pmod clock output: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );
endmodule
