// Project F Library - Simple Linebuffer
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_simple #(
    parameter DATAW=4,  // data width of each channel
    parameter LEN=640,  // length of line
    parameter SCALEW=6  // scale width (max scale == 2^SCALEW-1)
    ) (
    input  wire logic clk_sys,   // input clock
    input  wire logic clk_pix,   // output clock
    input  wire logic line,      // line start (clk_pix)
    input  wire logic line_sys,  // line start (clk_sys)
    input  wire logic en_in,     // enable input (clk_sys)
    input  wire logic en_out,    // enable output (clk_pix)
    input  wire logic [SCALEW-1:0] scale,   // scale factor (>=1)
    input  wire logic [DATAW-1:0] data_in,  // data in (clk_sys)
    output      logic [DATAW-1:0] data_out  // data out (clk_pix)
    );

    // output data
    logic [$clog2(LEN)-1:0] addr_out;  // output address (pixel counter)
    logic [SCALEW-1:0] cnt_h;  // horizontal scale counter
    always_ff @(posedge clk_pix) begin
        if (en_out) begin
            if (cnt_h == scale-1) begin
                cnt_h <= 0;
                if (addr_out != LEN-1) addr_out <= addr_out + 1;
            end else cnt_h <= cnt_h + 1;
        end
        if (line) begin
            addr_out <= 0;
            cnt_h <= 0;
        end
    end

    // read data in
    logic [$clog2(LEN)-1:0] addr_in;
    logic we;
    always_ff @(posedge clk_sys) begin
        if (en_in) we <= 1;
        if (addr_in == LEN-1) we <= 0;
        if (we) addr_in <= addr_in + 1;
        if (line_sys) begin
            we <= 0;
            addr_in <= 0;
        end
    end

    bram_sdp #(
        .WIDTH(DATAW),
        .DEPTH(LEN)
        ) bram_lb (
        .clk_write(clk_sys),
        .clk_read(clk_pix),
        .we,
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in,
        .data_out
    );
endmodule
