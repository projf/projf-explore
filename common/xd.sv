// Project F: Cross Domain Pulse
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module xd (
    input  wire logic clk_i,  //  input clock: source domain
    input  wire logic clk_o,  // output clock: destination domain
    input  wire logic rst_i,  // reset (source domain)
    input  wire logic rst_o,  // reset (destination domain)
    input  wire logic i,      //  input pulse: source domain
    output      logic o       // output pulse: destination domain
    );

    // toggle reg when pulse received in source domain
    logic toggle_i;
    always_ff @(posedge clk_i) begin
        toggle_i <= toggle_i ^ i;
        if (rst_i) toggle_i <= 1'b0;
    end

    // cross to destination domain via shift reg
    logic [3:0] shr_o;
    always_ff @(posedge clk_o) begin
        shr_o <= {shr_o[2:0], toggle_i};
        if (rst_o) shr_o <= 4'b0;
    end

    // output pulse when transition occurs
    always_comb begin
        o = shr_o[3] ^ shr_o[2];
    end
endmodule
