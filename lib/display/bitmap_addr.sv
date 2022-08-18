// Project F Library - Bitmap Address
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// three-cycle address calculation
// NB. doesn't handle coordinate wrapping using offsets

module bitmap_addr #(
    parameter CORDW=16,  // signed coordinate width (bits)
    parameter ADDRW=24   // address width (bits)
    ) (
    input  wire logic clk,                      // clock
    input  wire logic signed [CORDW-1:0] bmpw,  // bitmap width
    input  wire logic signed [CORDW-1:0] bmph,  // bitmap height
    input  wire logic signed [CORDW-1:0] x,     // horizontal pixel coordinate
    input  wire logic signed [CORDW-1:0] y,     // vertical pixel coordinate
    input  wire logic signed [CORDW-1:0] offx,  // horizontal offset
    input  wire logic signed [CORDW-1:0] offy,  // vertical offset
    output      logic [ADDRW-1:0] addr,         // pixel memory address
    output      logic clip                      // pixel coordinate outside bitmap
    );

    logic signed [CORDW-1:0] addr_y1, addr_x1, addr_x2;
    logic [ADDRW-1:0] addr_mul;
    logic clip_t1;  // clip check temporary

    always_ff @(posedge clk) begin
        // step 1
        addr_y1 <= y + offy;
        addr_x1 <= x + offx;

        // step 2
        /* verilator lint_off WIDTH */
        addr_mul <= bmpw * addr_y1;
        /* verilator lint_on WIDTH */
        addr_x2  <= addr_x1;
        clip_t1  <= (addr_x1 < 0 || addr_x1 > bmpw-1 || addr_y1 < 0 || addr_y1 > bmph-1);

        // step 3
        clip <= clip_t1;
        /* verilator lint_off WIDTH */
        addr <= addr_mul + addr_x2;
        /* verilator lint_on WIDTH */
    end
endmodule
