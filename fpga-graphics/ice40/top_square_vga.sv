// Project F: FPGA Graphics - Top Square (iCEBreaker with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none

module top_square_vga (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    output      logic vga_hsync,    // VGA horizontal sync
    output      logic vga_vsync,    // VGA vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
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
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .de
    );

    // 32 x 32 pixel square
    logic q_draw;
    always_comb q_draw = (sx < 32 && sy < 32) ? 1 : 0;

    // VGA output
    always_comb begin
        vga_r = !de ? 4'h0 : (q_draw ? 4'hF : 4'h0);
        vga_g = !de ? 4'h0 : (q_draw ? 4'h8 : 4'h8);
        vga_b = !de ? 4'h0 : (q_draw ? 4'h0 : 4'hF);
    end
endmodule
