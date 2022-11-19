// Project F: Rasterbars (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/rasterbars/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars #(parameter CORDW=16) (  // signed coordinate width (bits)
    input  wire logic clk_pix,      // pixel clock
    input  wire logic rst_pix,      // sim reset
    output      logic signed [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic signed [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,       // data enable (low in blanking interval)
    output      logic sdl_frame,    // high at start of frame
    output      logic [7:0] sdl_r,  // 8-bit red
    output      logic [7:0] sdl_g,  // 8-bit green
    output      logic [7:0] sdl_b   // 8-bit blue
    );

    // display sync signals and coordinates
    logic signed [CORDW-1:0] sx, sy;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de,
        .frame,
        .line
    );

    // library resource path
    localparam LIB_RES = "../../../lib/res";

    logic [11:0] bar_colr;
    /* verilator lint_off UNUSED */
    logic bar_up;  // current bar is moving up
    /* verilator lint_on UNUSED */
    render_rasterbars #(
        .VCENTER(220),  // 480 vertical pixels and bars are 40 pixels high
        .COLR_LINES(2),
        .SIN_FILE({LIB_RES,"/../maths/res/sine_table_64x8.mem"}),
        .SIN_SHIFT(1)
    ) rasters_instance (
        .clk(clk_pix),
        .start(frame),
        .line,
        .sy,
        .bar_colr,
        .bar_up
    );

    // separate colour channels
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb {paint_r, paint_g, paint_b} = bar_colr;

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_frame <= frame;
        sdl_r <= {2{paint_r}};  // double signal width (assumes CHANW=4)
        sdl_g <= {2{paint_g}};
        sdl_b <= {2{paint_b}};
    end
endmodule
