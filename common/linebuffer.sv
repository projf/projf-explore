// Project F: Linebuffer
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer #(
    parameter WIDTH=8,   // data width of each channel
    parameter LEN=2048,  // length of line
    parameter SCALEW=6   // horizontal scaling width
    ) (
    input  wire logic clk_in,
    input  wire logic clk_out,
    input  wire logic en_in,
    input  wire logic en_out,
    input  wire logic rst_in,
    input  wire logic rst_out,
    input  wire logic [SCALEW-1:0] scale,
    input  wire logic [WIDTH-1:0] data_in_0, data_in_1, data_in_2,
    output      logic [WIDTH-1:0] data_out_0, data_out_1, data_out_2
    );

    logic [$clog2(LEN)-1:0] addr_in, addr_out;
    logic [SCALEW-1:0] cnt_scale;

    // correct scale: if scale is 0, set to 1
    logic [SCALEW-1:0] scale_cor;
    always_comb scale_cor = (scale == 0) ? 1 : scale;

    always_ff @(posedge clk_in) begin
        /* verilator lint_off WIDTH */
        if (en_in) addr_in <= (addr_in == LEN-1) ? 0 : addr_in + 1;
        /* verilator lint_on WIDTH */
        if (rst_in) addr_in <= 0;  // reset takes precedence
    end

    always_ff @(posedge clk_out) begin
        if (en_out) begin
            cnt_scale <= (cnt_scale == scale_cor-1) ? 0 : cnt_scale + 1;
            /* verilator lint_off WIDTH */
            if (cnt_scale == scale_cor-1) addr_out <= (addr_out == LEN-1) ? 0 : addr_out + 1;
            /* verilator lint_on WIDTH */
        end
        if (rst_out) begin  // reset takes precedence
            addr_out <= 0;
            cnt_scale <= 0;
        end
    end

    // channel 0
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(LEN)) ch0 (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in(data_in_0),
        .data_out(data_out_0)
    );

    // channel 1
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(LEN)) ch1 (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in(data_in_1),
        .data_out(data_out_1)
    );

    // channel 2
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(LEN)) ch2 (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in(data_in_2),
        .data_out(data_out_2)
    );
endmodule
