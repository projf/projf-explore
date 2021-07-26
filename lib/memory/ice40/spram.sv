// Project F Library - Single Port RAM (iCE40)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// iCE40 SPRAM is documented in Lattice TN-02022: iCE40 SPRAM Usage Guide

module spram #(
    localparam WIDTH=16,     // fixed data width: 16-bits
    localparam DEPTH=16384,  // fixed depth: 16K 
    localparam INIT_F="",    // not supported by SPRAM
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic clk,
    input wire logic [3:0] we,
    input wire logic [ADDRW-1:0] addr,
    input wire logic [WIDTH-1:0] data_in,
    output     logic [WIDTH-1:0] data_out
    );

	SB_SPRAM256KA spram_inst (
		.ADDRESS(addr),
		.DATAIN(data_in),
		.MASKWREN(we),
		.WREN(|we),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(data_out)
	);
endmodule
