// Project F Library - Bitmap Address
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// one-cycle address calculation that doesn't handle offset wrapping

module bitmap_addr #(
    parameter CORDW=16,  // signed coordinate width (bits)
    parameter ADDRW=24   // address width (bits)
    ) (
    input  wire logic clk,  // clock
    input  wire logic signed [CORDW-1:0] bmpw,  // bitmap width
    input  wire logic signed [CORDW-1:0] bmph,  // bitmap height
    input  wire logic signed [CORDW-1:0] x,     // horizontal pixel coordinate
    input  wire logic signed [CORDW-1:0] y,     // vertical pixel coordinate
    input  wire logic signed [CORDW-1:0] offx,  // horizontal offset
    input  wire logic signed [CORDW-1:0] offy,  // vertical offset
    output      logic [ADDRW-1:0] addr,         // pixel memory address
    output      logic clip                      // pixel coordinate outside bitmap
    );

    always_ff @(posedge clk) begin
        // check for clipping in pixel and offset
        if (x < 0 || x > bmpw-1 || 
            y < 0 || y > bmph-1 || 
            offx < 0 || offx > bmpw-1 || 
            offy < 0 || offy > bmph-1
        ) begin
            clip <= 1;
            addr <= 0;
        end else begin
            clip <= 0;
            addr <= bmpw * (y + offy) + x + offx;
        end
    end    
endmodule
