// Project F Library - Single Port RAM with Nibble Interface (iCE40)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// iCE40 SPRAM is documented in Lattice TN-02022: iCE40 SPRAM Usage Guide

module spram_nibble #(
    localparam WIDTH=4,      // fixed data width: 4 bits
    localparam DEPTH=65536,  // fixed depth: 64K
    localparam INIT_F="",    // not supported by SPRAM
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic clk,
    input wire logic we,
    input wire logic [ADDRW-1:0] addr,
    input wire logic [WIDTH-1:0] data_in,
    output     logic [WIDTH-1:0] data_out
    );

	logic we_p1;
	logic [3:0] nibble, nibble_p1;
	logic [15:0] dout_16, din_16;
	logic [13:0] addr_14;

	always_ff @(posedge clk) begin
		case (nibble_p1)
			4'b0001: data_out <= dout_16[3:0];
			4'b0010: data_out <= dout_16[7:4];
			4'b0100: data_out <= dout_16[11:8];
			4'b1000: data_out <= dout_16[15:12];
			default: data_out <= 4'b0000;  // should never occur
		endcase
	end

	always_ff @(posedge clk) begin
		we_p1 <= we;
		addr_14 <= addr[15:2];  // discard the lowest two bits of address
		case (addr[1:0])  // use lowest two bits for nibble selection
			2'b00: din_16 <= {12'b0,data_in};
			2'b01: din_16 <= {8'b0,data_in,4'b0};
			2'b10: din_16 <= {4'b0,data_in,8'b0};
			2'b11: din_16 <= {data_in,12'b0};
		endcase
	end

	always_ff @(posedge clk) begin
		case (addr[1:0])
			2'b00: nibble <= 4'b0001;
			2'b01: nibble <= 4'b0010;
			2'b10: nibble <= 4'b0100;
			2'b11: nibble <= 4'b1000;
		endcase
		nibble_p1 <= nibble;
	end

	SB_SPRAM256KA spram_inst (
		.ADDRESS(addr_14),
		.DATAIN(din_16),
		.MASKWREN(nibble),
		.WREN(we_p1),
		.CHIPSELECT(1'b1),
		.CLOCK(clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(dout_16)
	);
endmodule
