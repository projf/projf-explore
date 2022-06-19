// Project F Library - Simple Linebuffer Test Bench (XC7)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_simple_tb();
    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    // 100 MHz clock domain (LB input)
    logic clk_100m;
    logic rst_100m;

    // 25 MHz clock domain (LB output)
    logic clk_25m;
    logic rst_25m;

    // display sync signals and coordinates
    localparam CORDW = 16;  // screen coordinate width in bits
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_24x18 #(.CORDW(CORDW)) display_inst (
        .clk_pix(clk_25m),
        .rst_pix(rst_25m),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // test graphic
    localparam GFX_WIDTH  = 8;
    localparam GFX_HEIGHT = 8;
    /* verilator lint_off LITENDIAN */
    logic [0:GFX_WIDTH-1] bmap [GFX_HEIGHT];
    /* verilator lint_on LITENDIAN */
    initial begin  // big endian vector, so we can write initial block left to right
        bmap[0]  = 8'b1111_1100;
        bmap[1]  = 8'b1100_0000;
        bmap[2]  = 8'b1100_0000;
        bmap[3]  = 8'b1111_1000;
        bmap[4]  = 8'b1100_0000;
        bmap[5]  = 8'b1100_0000;
        bmap[6]  = 8'b1100_0011;
        bmap[7]  = 8'b0000_0011;
    end

    // generate clocks
    always #(CLK_PERIOD_100M / 2) clk_100m = ~clk_100m;
    always #(CLK_PERIOD_25M / 2) clk_25m = ~clk_25m;

    initial begin
        clk_100m = 1;
        rst_100m = 1;

        #100 rst_100m = 0;
    end

    initial begin
        clk_25m = 1;
        rst_25m = 1;

        #100 rst_25m = 0;
    end

endmodule