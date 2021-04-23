// Project F Library - Simple Dual-Port Block RAM (XC7)
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module bram_sdp #(
    parameter WIDTH=8, 
    parameter DEPTH=256, 
    parameter INIT_F="",
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic clk_write,                 // write clock (port a)
    input wire logic clk_read,                  // read clock (port b)
    input wire logic we,                        // write enable (port a)
    input wire logic [ADDRW-1:0] addr_write,    // write address (port a)
    input wire logic [ADDRW-1:0] addr_read,     // read address (port b)
    input wire logic [WIDTH-1:0] data_in,       // data in (port a)
    output     logic [WIDTH-1:0] data_out       // data out (port b)
    );

    /* verilator lint_off MULTIDRIVEN */
    logic [WIDTH-1:0] memory [DEPTH];
    /* verilator lint_on MULTIDRIVEN */

    initial begin
        if (INIT_F != 0) begin
            $display("Loading memory init file '%s' into bram_sdp.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    // Port A: Sync Write
    always_ff @(posedge clk_write) begin
        if (we) begin
            memory[addr_write] <= data_in;
        end
    end

    // Port B: Sync Read
    always_ff @(posedge clk_read) begin
        data_out <= memory[addr_read];
    end
endmodule
