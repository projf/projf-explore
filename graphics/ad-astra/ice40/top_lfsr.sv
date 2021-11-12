// Project F: Ad Astra - Top LFSR (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_lfsr (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
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
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_locked),
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

    // colours
    logic [3:0] red, green, blue;
    always_comb begin
        red   = (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
        green = (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
        blue  = (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
    end

    // Output DVI clock: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // Output DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, red, green, blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
