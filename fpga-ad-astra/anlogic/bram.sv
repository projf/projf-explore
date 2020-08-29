// Project F: FPGA Ad Astra - BRAM (iCE40)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module bram #(
    parameter WIDTH=8, 
    parameter DEPTH=512, 
    parameter INIT_F="",
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic clk,
    input wire logic [ADDRW-1:0] addr,
    input wire logic we,
    input wire logic [WIDTH-1:0] data_in,
    output     logic [WIDTH-1:0] data
    );

    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Creating bram from init file '%s'.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    always_ff @(posedge clk) begin
        if (we) memory[addr] <= data_in;
        data = memory[addr];
    end

endmodule
