// Project F: Racing the Beam - Hello (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_hello (
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
    /* verilator lint_off UNUSED */
    logic [CORDW-1:0] sx, sy;
    /* verilator lint_on UNUSED */
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

    // bitmap: big endian vector, so we can write pixels left to right
    /* verilator lint_off LITENDIAN */
    logic [0:19] bmap [15];  // 20 pixels by 15 lines
    /* verilator lint_on LITENDIAN */

    initial begin
        bmap[0]  = 20'b1010_1110_1000_1000_0110;
        bmap[1]  = 20'b1010_1000_1000_1000_1010;
        bmap[2]  = 20'b1110_1100_1000_1000_1010;
        bmap[3]  = 20'b1010_1000_1000_1000_1010;
        bmap[4]  = 20'b1010_1110_1110_1110_1100;
        bmap[5]  = 20'b0000_0000_0000_0000_0000;
        bmap[6]  = 20'b1010_0110_1110_1000_1100;
        bmap[7]  = 20'b1010_1010_1010_1000_1010;
        bmap[8]  = 20'b1010_1010_1100_1000_1010;
        bmap[9]  = 20'b1110_1010_1010_1000_1010;
        bmap[10] = 20'b1110_1100_1010_1110_1110;
        bmap[11] = 20'b0000_0000_0000_0000_0000;
        bmap[12] = 20'b0000_0000_0000_0000_0000;
        bmap[13] = 20'b0000_0000_0000_0000_0000;
        bmap[14] = 20'b0000_0000_0000_0000_0000;
    end

    // paint at 32x scale in active screen area
    logic picture;
    logic [4:0] x;  // 20 columns need five bits
    logic [3:0] y;  // 15 rows need four bits
    always_comb begin
        x = sx[9:5];  // every 32 horizontal pixels
        y = sy[8:5];  // every 32 vertical pixels
        picture = de ? bmap[y][x] : 0;  // look up pixel (unless we're in blanking)
    end

    // paint colours: yellow lines, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (picture) ? 4'hF : 4'h1;
        paint_g = (picture) ? 4'hC : 4'h3;
        paint_b = (picture) ? 4'h0 : 4'h7;
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
