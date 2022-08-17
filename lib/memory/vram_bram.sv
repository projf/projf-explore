// Project F Library - VRAM in BRAM with nibble write
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module vram_bram #(
    parameter  WIDTH=16,              // data width
    parameter  DEPTH=16384,           // memory depth
    localparam ADDRW=$clog2(DEPTH),   // address width
    localparam NIB = 4,               // nibble width: 4 bits
    localparam NIB_CNT = WIDTH / NIB  // nibble count
    ) (
    input wire logic clk,
    input wire logic [NIB_CNT-1:0] we,
    input wire logic [ADDRW-1:0] addr,
    input wire logic [WIDTH-1:0] data_in,
    output     logic [WIDTH-1:0] data_out
    );

    logic [WIDTH-1:0] memory [DEPTH];

    integer i;  // for looping over nibbles
    always @(posedge clk) begin
        if (we == 0) begin  // read
            data_out <= memory[addr];
        end else begin
            for(i=0; i<NIB_CNT; i=i+1) begin
                if (we[i]) memory[addr][i*NIB +: NIB] <= data_in[i*NIB +:NIB];
            end
        end
    end
endmodule
