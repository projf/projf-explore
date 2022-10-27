// Project F Library - Clock Domain Crossing (CDC) for Flag
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module xd (
    input  wire logic clk_src,   // source domain clock
    input  wire logic clk_dst,   // destination domain clock
    input  wire logic flag_src,  // flag in source domain
    output      logic flag_dst   // flag in destination domain
    );

    // toggle reg when pulse received in source domain
    logic toggle_src = 1'b0;
    always_ff @(posedge clk_src) toggle_src <= toggle_src ^ flag_src;

    // cross to destination domain via shift reg
    logic [3:0] shr_dst = 4'b0;
    always_ff @(posedge clk_dst) shr_dst <= {shr_dst[2:0], toggle_src};

    // output pulse when transition occurs
    always_comb flag_dst = shr_dst[3] ^ shr_dst[2];
endmodule
