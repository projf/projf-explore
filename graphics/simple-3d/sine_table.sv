// Project F: Simple 3D - Sine Table
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sine_table #(
    parameter ROM_DEPTH=64,  // entires in sine ROM 0°-90°
    parameter ROM_WIDTH=8,   // width of sine ROM data
    parameter ROM_FILE="",   // file to populate ROM
    parameter ADDRW=$clog2(4*ROM_DEPTH)  // full table contains -180° to +180°
    ) (
    input  wire logic [ADDRW-1:0] id,  // table ID to lookup
    output      logic signed [2*ROM_WIDTH-1:0] data  // answer
    );

    // sine table ROM: 0°-90°
    logic [$clog2(ROM_DEPTH)-1:0] tab_id;
    logic [ROM_WIDTH-1:0] tab_data;
    rom_async #(
        .WIDTH(ROM_WIDTH),
        .DEPTH(ROM_DEPTH),
        .INIT_F(ROM_FILE)
    ) sine_rom (
        .addr(tab_id),
        .data(tab_data)
    );

    logic [1:0] quad;  // quadrant we're in 0-3
    always_comb begin
        quad = id[ADDRW-1:ADDRW-2];
        case (quad)
            /* verilator lint_off WIDTH */
            2'b00: tab_id = id[ADDRW-3:0];
            2'b01: tab_id = 2*ROM_DEPTH - id[ADDRW-3:0];
            2'b10: tab_id = id[ADDRW-3:0] - 2*ROM_DEPTH;
            2'b11: tab_id = 4*ROM_DEPTH - id[ADDRW-3:0];
            /* verilator lint_on WIDTH */
        endcase
    end

    always_comb begin
        if (id == ROM_DEPTH) begin  // sin(-90°) = -1
            data = {{ROM_WIDTH{1'b1}}, {ROM_WIDTH{1'b0}}};
        end else if (id == 3*ROM_DEPTH) begin  // sin(90°) = 0
            data = {{ROM_WIDTH-1{1'b0}}, 1'b1, {ROM_WIDTH{1'b0}}};
        end else begin
            if (quad[1] == 1) begin  // positive
                data = {{ROM_WIDTH{1'b0}}, tab_data};
            end else begin
                data = {2*ROM_WIDTH{1'b0}} - {{ROM_WIDTH{1'b0}}, tab_data};
            end
        end
    end
endmodule
