// Project F: Life on Screen - Linebuffer
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer #(
    parameter WIDTH=8,              // data width per channel
    parameter DEPTH=2048,           // length of line
    parameter ADDRW=$clog2(DEPTH)   // address width
    ) (
    input  wire logic clk_write,
    input  wire logic clk_read, 
    input  wire logic we,
    input  wire logic [ADDRW-1:0] addr_write,
    input  wire logic [ADDRW-1:0] addr_read,
    input  wire logic [WIDTH-1:0] data_in_0, data_in_1, data_in_2,
    output      logic [WIDTH-1:0] data_out_0, data_out_1, data_out_2
    );

    // channel 0
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH)) ch0 (
        .clk_write,
        .clk_read,
        .we,
        .addr_write,
        .addr_read,
        .data_in(data_in_0),
        .data_out(data_out_0)
    );

    // channel 1
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH)) ch1 (
        .clk_write,
        .clk_read,
        .we,
        .addr_write,
        .addr_read,
        .data_in(data_in_1),
        .data_out(data_out_1)
    );

    // channel 2
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(DEPTH)) ch2 (
        .clk_write,
        .clk_read,
        .we,
        .addr_write,
        .addr_read,
        .data_in(data_in_2),
        .data_out(data_out_2)
    );
endmodule
