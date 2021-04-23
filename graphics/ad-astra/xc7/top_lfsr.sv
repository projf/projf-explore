// Project F: Ad Astra - Top LFSR (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_lfsr (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        /* verilator lint_off PINCONNECTEMPTY */
        .frame(),
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    logic sf_area;
    always_comb sf_area = (sx < 512 && sy < 256);

    // 17-bit LFSR
    /* verilator lint_off UNUSED */
    logic [16:0] sf_reg;
    /* verilator lint_on UNUSED */
    lfsr #(
        .LEN(17),
        .TAPS(17'b10010000000000000)
    ) lsfr_sf (
        .clk(clk_pix),
        .rst(!clk_locked),
        .en(sf_area && de),
        .sreg(sf_reg)
    );

    // adjust star density (~512 stars for AND 8 bits with 512x256)
    logic star;
    always_comb star = &{sf_reg[16:9]};

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
        vga_g <= (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
        vga_b <= (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
    end
endmodule
