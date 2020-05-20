// Project F: Top Square (iCEBreaker with Pmod VGA)
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none

module top_square_vga (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // VGA horizontal sync
    output      logic vga_vsync,    // VGA vertical sync
    output      logic vga_r0, vga_r1, vga_r2, vga_r3,   // 4-bit VGA red
    output      logic vga_g0, vga_g1, vga_g2, vga_g3,   // 4-bit VGA green
    output      logic vga_b0, vga_b1, vga_b2, vga_b3    // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_12m),
       .rst(btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    logic [9:0] sx, sy;
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
        {vga_r3, vga_r2, vga_r1, vga_r0} = !de ? 4'h0 : (q_draw ? 4'hD : 4'h3);
        {vga_g3, vga_g2, vga_g1, vga_g0} = !de ? 4'h0 : (q_draw ? 4'hA : 4'h7);
        {vga_b3, vga_b2, vga_b1, vga_b0} = !de ? 4'h0 : (q_draw ? 4'h3 : 4'hD);
    end
endmodule
