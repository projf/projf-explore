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

    // screen dimensions (must match display_inst)
    localparam H_RES = 24;

    // display flags in system clock domain
    logic line_sys;
    xd xd_line (.clk_src(clk_25m), .clk_dst(clk_100m), .flag_src(line), .flag_dst(line_sys));

    // simple linebuffer
    localparam DATAW=1;
    localparam SCALEW=6;
    localparam SCALE=2;

    logic gfx_in, gfx_out;
    linebuffer_simple #(
        .DATAW(DATAW),
        .LEN(H_RES),
        .SCALEW(SCALEW)
    ) linebuffer_simple_inst (
        .clk_sys(clk_100m),
        .clk_pix(clk_25m),
        .line,
        .line_sys,
        .en_in(!rst_100m),
        .en_out(sy >= 0 && sx >= -1),  // account for BRAM latency
        .scale(SCALE),  // scale factor (>=1)
        .data_in(gfx_in),
        .data_out(gfx_out)
    );

    // simple input data (alternate 0 and 1)
    always @(posedge clk_100m) begin
        gfx_in <= ~gfx_in;
        if (rst_100m) gfx_in <= 0;
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
        #100_000 $finish;
    end

endmodule