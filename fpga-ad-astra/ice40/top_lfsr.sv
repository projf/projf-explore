// Project F: Top LFSR (iCEBreaker with 12-bit DVI Pmod)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none

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
    clock_gen clock_640x480 (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(dvi_hsync),
        .vsync(dvi_vsync),
        .de
    );

    logic sf_area;
    always_comb sf_area = (sx < 512 && sy < 256);

    // 17-bit LFSR
    logic [16:0] sf_reg;
    lfsr #(
        .LEN(17),
        .TAPS(17'b10010000000000000)
    ) lsfr_sf (
        .clk(clk_pix),
        .rst(!clk_locked),
        .en(sf_area && de),
        .sreg(sf_reg)
    );

    // DVI output
    logic star;
    always_comb begin
        star = &{sf_reg[16:9]};  // (~512 stars for 8 bits with 512x256)
        dvi_clk = clk_pix;
        dvi_de  = de;
        dvi_r = (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
        dvi_g = (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
        dvi_b = (de && sf_area && star) ? sf_reg[3:0] : 4'h0;
    end
endmodule
