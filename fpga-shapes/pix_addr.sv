// Project F: FPGA Shapes - Pixel Address
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module pix_addr #(
    parameter CORDW=10,  // framebuffer coordinate width in bits
    parameter ADDRW=13   // width of memory address bus
    ) (
    input  wire logic clk,                  // clock
    input  wire logic [CORDW-1:0] hres,     // horizontal framebuffer resolution
    input  wire logic [CORDW-1:0] px,       // horizontal pixel position
    input  wire logic [CORDW-1:0] py,       // vertical pixel position
    output      logic [ADDRW-1:0] pix_addr  // pixel address
    );

    always_ff @(posedge clk) begin
        /* verilator lint_off WIDTH */
        pix_addr <= (hres * py) + px;
        /* verilator lint_on WIDTH */
    end
endmodule
