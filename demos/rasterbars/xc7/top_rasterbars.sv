// Project F: Rasterbars (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/rasterbars/

`default_nettype none
`timescale 1ns / 1ps

module top_rasterbars (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    output      logic vga_hsync,    // VGA horizontal sync
    output      logic vga_vsync,    // VGA vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       /* verilator lint_off PINCONNECTEMPTY */
       .clk_pix_5x(),  // not used for VGA output
       /* verilator lint_on PINCONNECTEMPTY */
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        /* verilator lint_on PINCONNECTEMPTY */
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    logic [11:0] bar_colr;
    /* verilator lint_off UNUSED */
    logic bar_up;  // current bar is moving up
    /* verilator lint_on UNUSED */
    render_rasterbars #(
        .VCENTER(220),  // 480 vertical pixels and bars are 40 pixels high
        .COLR_LINES(2),
        .SIN_FILE("sine_table_64x8.mem"),
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
