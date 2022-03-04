// Project F: FPGA Graphics - Flag of Sweden (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_flag_sweden (
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

    // flag of Sweden (16:10 ratio)
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        if (sy > 160 && sy < 240) begin  // yellow cross horizontal
            paint_r = 4'hF;
            paint_g = 4'hC;
            paint_b = 4'h0;
        end else if (sy < 400 && sx > 200 && sx < 280) begin  // yellow cross vertical
            paint_r = 4'hF;
            paint_g = 4'hC;
            paint_b = 4'h0;
        end else if (sy < 400) begin  // blue flag background
            paint_r = 4'h0;
            paint_g = 4'h6;
            paint_b = 4'hA;
        end else begin  // black outside flag
            paint_r = 4'h0;
            paint_g = 4'h0;
            paint_b = 4'h0;
        end
    end

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