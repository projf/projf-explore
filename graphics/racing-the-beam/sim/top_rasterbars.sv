// Project F: Racing the Beam - Raster Bars (Verilator SDL)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,             // pixel clock
    input  wire logic sim_rst,             // sim reset
    output      logic [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,         // 8-bit red
    output      logic [7:0] sdl_g,         // 8-bit green
    output      logic [7:0] sdl_b          // 8-bit blue
    );

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(sim_rst),
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
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

    // display colour: black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r <= {2{display_r}};  // double signal width from 4 to 8 bits
        sdl_g <= {2{display_g}};
        sdl_b <= {2{display_b}};
    end
endmodule
