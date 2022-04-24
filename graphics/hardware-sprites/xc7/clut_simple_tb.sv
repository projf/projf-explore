// Project F: Hardware Sprites - Simple CLUT Test Bench
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module clut_simple_tb();

    parameter CLK_PERIOD = 40;  // 40 ns == 25 MHz

    logic rst;
    logic clk_25m;

    // colour lookup table
    localparam COLRW = 12;  // 12 colour bits per pixel
    localparam INDXW = 4;   // 4 index bits per pixel

    localparam PAL_FILE = "step-12b.mem";
    logic we;
    logic [COLRW-1:0] pix_colr_in, pix_colr_out;
    logic [INDXW-1:0] pix_indx_write, pix_indx_read;
    clut_simple #(
        .COLRW(COLRW),
        .INDXW(INDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_25m),
        .clk_read(clk_25m),
        .we,
        .indx_write(pix_indx_write),
        .indx_read(pix_indx_read),
        .colr_in(pix_colr_in),
        .colr_out(pix_colr_out)
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_25m = ~clk_25m;

    initial begin
        rst = 1;
        clk_25m = 1;
        we = 0;
        pix_indx_write = 0;
        pix_indx_read  = 0;
        pix_colr_in = 0;

        #120 rst = 0;

        #120 pix_indx_read = 1;
        #120 pix_indx_read = 14;
        #120 pix_indx_read = 0;

        #40 pix_indx_read = 15;
        #40 pix_indx_read = 7;

        #120
        we = 1;
        pix_indx_write = 7;
        pix_colr_in = 12'h753;

        #40 we = 0;

        #120
        we = 1;
        pix_indx_write = 0;
        pix_colr_in = 12'hF00;

        #40
        pix_indx_write = 1;
        pix_colr_in = 12'hE00;

        #40
        pix_indx_write = 2;
        pix_colr_in = 12'hD00;

        #40
        pix_indx_write = 15;
        pix_colr_in = 12'h000;

        #40 we = 0;

        #40 pix_indx_read = 1;
        #40 pix_indx_read = 15;
        #40 pix_indx_read = 2;
        #40 pix_indx_read = 0;

        #120 $finish;
    end
endmodule
