// Project F: Racing the Beam - Raster Bars (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars (
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
    localparam V_RES_FULL = 525;
    localparam H_RES      = 640;

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
