// Project F Library - UART 8N1 Transmitter
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module uart_tx (
    input  wire logic clk,
    input  wire logic rst,
    input  wire logic stb_baud,       // baud strobe
    input  wire logic tx_start,       // start transmission
    input  wire logic [7:0] data_in,  // data to transmit
    output      logic data_out,       // serial data out
    output      logic tx_busy,        // busy with transmission
    output      logic tx_next         // ready for next data in
    );

    enum {IDLE, START, DATA, STOP} state, state_next;
    logic [2:0] data_idx, data_idx_next;  // eight data bits: 0-7
    localparam LAST_BIT = 3'd7;

    always_ff @(posedge clk) begin
        if (stb_baud) begin
            state <= state_next;
            data_idx <= data_idx_next;
        end
        if (rst) begin
            state <= IDLE;
            data_idx <= 0;
        end
    end

    always_comb begin
        data_out = 1'b1;
        state_next = IDLE;
        data_idx_next = 0;

        case(state)
            IDLE: state_next = (tx_start) ? START : IDLE;
            STOP: state_next = IDLE;
            START: begin
                data_out = 0;
                state_next = DATA;
            end
            DATA: begin
                data_out = data_in[data_idx];
                data_idx_next = data_idx + 1;
                state_next = (data_idx == LAST_BIT) ? STOP : DATA;
            end
        endcase
    end

    always_comb begin
        tx_busy = (state != IDLE);
        tx_next = (state == STOP);  // safe to update data_in
    end
endmodule
