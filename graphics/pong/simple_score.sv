// Project F: FPGA Pong - Simple Score Drawing
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-pong/

`default_nettype none
`timescale 1ns / 1ps

module simple_score #(
    parameter CORDW=10,                // coordinate width
    parameter H_RES=640                // horizontal screen resolution
    ) (
    input  wire logic clk_pix,         // pixel clock
    input  wire logic [CORDW-1:0] sx,  // horizontal screen position
    input  wire logic [CORDW-1:0] sy,  // vertical screen position
    input  wire logic [3:0] score_l,   // score for left-side player (0-9)
    input  wire logic [3:0] score_r,   // score for right-side player (0-9)
    output      logic pix              // draw pixel at this position?
    );

    // number characters: MSB first, so we can write pixels left to right
    /* verilator lint_off LITENDIAN */
    logic [0:14] chars [10];  // ten characters of 15 pixels each
    /* verilator lint_on LITENDIAN */
    initial begin
        chars[0] = 15'b111_101_101_101_111;
        chars[1] = 15'b110_010_010_010_111;
        chars[2] = 15'b111_001_111_100_111;
        chars[3] = 15'b111_001_011_001_111;
        chars[4] = 15'b101_101_111_001_001;
        chars[5] = 15'b111_100_111_001_111;
        chars[6] = 15'b100_100_111_101_111;
        chars[7] = 15'b111_001_001_001_001;
        chars[8] = 15'b111_101_111_101_111;
        chars[9] = 15'b111_101_111_001_001;
    end

    // ensure score in range of characters (0-9)
    logic [3:0] char_l, char_r;
    always_comb begin
        char_l = (score_l < 10) ? score_l : 0;
        char_r = (score_r < 10) ? score_r : 0;
    end

    // set screen region for each score: 12x20 pixels (8,8) from corner
    // subtract one from 'sx' to account for latency for registering 'pix'
    logic score_l_region, score_r_region;
    always_comb begin
        score_l_region = (sx >= 7 && sx < 19 && sy >= 8 && sy < 28);
        score_r_region = (sx >= H_RES-22 && sx < H_RES-10 && sy >= 8 && sy < 28);
    end

    // determine character pixel address from screen position (scale 4x)
    logic [3:0] pix_addr;
    always_comb begin
        /* verilator lint_off WIDTH */
        if (score_l_region) pix_addr = (sx-7)/4 + 3*((sy-8)/4);
        else if (score_r_region) pix_addr = (sx-(H_RES-22))/4 + 3*((sy-8)/4);
        else pix_addr = 0;
        /* verilator lint_on WIDTH */
    end

    // score pixel for current screen position
    always_ff @(posedge clk_pix) begin
        if (score_l_region) pix <= chars[char_l][pix_addr];
        else if (score_r_region) pix <= chars[char_r][pix_addr];
        else pix <= 0;
    end
endmodule
