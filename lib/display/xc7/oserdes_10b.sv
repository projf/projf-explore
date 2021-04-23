// Project F Library - XC7 10:1 Output Serializer
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// OSERDESE2 is documented in Xilinx UG471

module oserdes_10b (
    input  wire logic clk,              // parallel clock
    input  wire logic clk_hs,           // high-speed serial clock
    input  wire logic rst,              // reset from async reset
    input  wire logic [9:0] data_in,    // input parallel data
    output      logic serial_out        // output serial data
    );

    // use two OSERDES2 to serialize 10-bit TMDS data
    logic shift1, shift2;  // connection between master and slave

    OSERDESE2 #(
        .SERDES_MODE("MASTER"),
        .DATA_WIDTH(10),
        .TRISTATE_WIDTH(1),     // unused but required to be set
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR")    // unused but required to be set
    )  master10 (
        .OQ(serial_out),
        .CLK(clk_hs),
        .CLKDIV(clk),
        .D1(data_in[0]),
        .D2(data_in[1]),
        .D3(data_in[2]),
        .D4(data_in[3]),
        .D5(data_in[4]),
        .D6(data_in[5]),
        .D7(data_in[6]),
        .D8(data_in[7]),
        .OCE(1'b1),
        .RST(rst),
        .SHIFTIN1(shift1),
        .SHIFTIN2(shift2),
        /* verilator lint_off PINCONNECTEMPTY */
        .OFB(),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .TBYTEOUT(),
        .TFB(),
        .TQ(),
        .T1(),
        .T2(),
        .T3(),
        .T4(),
        .TBYTEIN(),
        .TCE()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    OSERDESE2 #(
        .SERDES_MODE("SLAVE"),
        .DATA_WIDTH(10),
        .TRISTATE_WIDTH(1),     // unused but required to be set
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR")    // unused but required to be set
    ) slave10 (
        .CLK(clk_hs),
        .CLKDIV(clk),
        .D1(1'b0),
        .D2(1'b0),
        .D3(data_in[8]),
        .D4(data_in[9]),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),
        .OCE(1'b1),
        .RST(rst),
        .SHIFTOUT1(shift1),
        .SHIFTOUT2(shift2),
        /* verilator lint_off PINCONNECTEMPTY */
        .OQ(),
        .OFB(),
        .SHIFTIN1(),
        .SHIFTIN2(),
        .TBYTEOUT(),
        .TFB(),
        .TQ(),
        .T1(),
        .T2(),
        .T3(),
        .T4(),
        .TBYTEIN(),
        .TCE()
        /* verilator lint_on PINCONNECTEMPTY */
    );

endmodule
