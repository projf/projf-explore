// Project F Library - Simple Linebuffer
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_simple #(
    parameter DATAW=4,  // data width of each channel
    parameter LEN=640,  // length of line
    parameter SCALE=1   // scaling factor (>=1)
    ) (
    input  wire logic clk_in,    // input clock
    input  wire logic clk_out,   // output clock
    input  wire logic rst_in,    // reset (clk_in)
    input  wire logic rst_out,   // reset (clk_out)
    input  wire logic en_in,     // enable input (clk_in)
    input  wire logic en_out,    // enable output (clk_out)
    input  wire logic [DATAW-1:0] data_in,  // data in (clk_in)
    output      logic [DATAW-1:0] data_out  // data out (clk_out)
    );

    // output data
    logic [$clog2(LEN)-1:0] addr_out;  // output address (pixel counter)
    logic [$clog2(SCALE):0] cnt_h;     // horizontal scale counter
    always_ff @(posedge clk_out) begin
        if (en_out) begin
            if (cnt_h == SCALE-1) begin
                cnt_h <= 0;
                if (addr_out != LEN-1) addr_out <= addr_out + 1;
            end else cnt_h <= cnt_h + 1;
        end
        if (rst_out) begin
            addr_out <= 0;
            cnt_h <= 0;
        end
    end

    // read data in
    logic [$clog2(LEN)-1:0] addr_in;
    always_ff @(posedge clk_in) begin
        if (addr_in != LEN-1) addr_in <= addr_in + 1;
        if (rst_in) addr_in <= 0;
    end

    logic we;
    always_comb we = (addr_in == LEN-1) ? 0 : en_in;

    bram_sdp #(
        .WIDTH(DATAW), 
        .DEPTH(LEN)
        ) bram_lb (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we,
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in,
        .data_out
    );
endmodule
