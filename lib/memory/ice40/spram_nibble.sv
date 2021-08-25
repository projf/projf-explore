// Project F Library - Single Port RAM with Nibble Interface (iCE40)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// iCE40 SPRAM is documented in Lattice TN-02022: iCE40 SPRAM Usage Guide

module spram_nibble #(
    localparam WIDTH=4,      // fixed data width: 4 bits
    localparam DEPTH=65536,  // fixed depth: 64K
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic clk,
    input wire logic we,
    input wire logic [ADDRW-1:0] addr,
    input wire logic [WIDTH-1:0] data_in,
    output     logic [WIDTH-1:0] data_out
    );

    logic we_p1;
    logic  [3:0] nibble;
    logic [13:0] addr_14;
    logic  [1:0] addr_02, addr_02_p1;
    logic [15:0] dout_16, din_16;


    always_ff @(posedge clk) begin
        {addr_14,addr_02} <= addr;  // split the address
        addr_02_p1 <= addr_02;      // delay one cycle for read output
        we_p1 <= we;				// delay one cycle for address split
    end

    always_ff @(posedge clk) begin
        case (addr_02_p1)
            2'b00: data_out <= dout_16[3:0];
            2'b01: data_out <= dout_16[7:4];
            2'b10: data_out <= dout_16[11:8];
            2'b11: data_out <= dout_16[15:12];
        endcase
    end

    always_ff @(posedge clk) begin
        case (addr[1:0])  // use lowest two bits for write selection
            2'b00: begin
                din_16 <= {12'b0,data_in};
                nibble <= 4'b0001;
            end
            2'b01: begin
                din_16 <= {8'b0,data_in,4'b0};
                nibble <= 4'b0010;
            end
            2'b10: begin
                din_16 <= {4'b0,data_in,8'b0};
                nibble <= 4'b0100;
            end
            2'b11: begin
                din_16 <= {data_in,12'b0};
                nibble <= 4'b1000;
            end
        endcase
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
