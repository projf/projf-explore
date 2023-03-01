// Project F: FPGA Graphics - Flag of Sweden (Verilator SDL)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_flag_sweden #(parameter CORDW=10) (  // coordinate width
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

    // paint colour: flag of Sweden (16:10 ratio)
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        if (sy >= 400) begin  // black outside the flag area
            paint_r = 4'h0;
            paint_g = 4'h0;
            paint_b = 4'h0;
        end else if (sy > 160 && sy < 240) begin  // yellow cross horizontal
            paint_r = 4'hF;
            paint_g = 4'hC;
            paint_b = 4'h0;
        end else if (sx > 200 && sx < 280) begin  // yellow cross vertical
            paint_r = 4'hF;
            paint_g = 4'hC;
            paint_b = 4'h0;
        end else begin  // blue flag background
            paint_r = 4'h0;
            paint_g = 4'h6;
            paint_b = 4'hA;
        end
    end

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
