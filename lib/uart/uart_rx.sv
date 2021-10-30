// Project F Library - UART 8N1 Receiver
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module uart_rx (
    input  wire logic clk,
    input  wire logic rst,
    input  wire logic stb_sample,      // over-sampling baud strobe
    input  wire logic data_in,         // serial data in
    output      logic [7:0] data_out,  // data recevived
    output      logic rx_done          // data receive complete
    );

    // sync serial data_in to combat metastability
    logic rx_0, rx;
    always_ff @(posedge clk) begin
        rx_0 <= data_in;
        rx <= rx_0;
        if (rst) begin  // default high as start is triggered by rx going low
            rx_0 <= 1;
            rx <= 1;
        end
    end

    enum {IDLE, START, DATA, STOP} state, state_next;

    logic [2:0] data_idx, data_idx_next;  // eight data bits: 0-7
    localparam LAST_BIT = 3'd7;

    // 16x oversampling - must match stb_sample
    logic [3:0] s_cnt, s_cnt_next;  // sample counter (16x): 0-15
    localparam S_SAMPLE_A = 4'd6;   // 1st sample position
    localparam S_SAMPLE_B = 4'd7;   // 2nd sample position
    localparam S_SAMPLE_C = 4'd8;   // 3rd sample position
    localparam S_END = 4'd15;       // sample end

    logic sample_a, sample_a_next;  // 1st sample data
    logic sample_b, sample_b_next;  // 2nd sample data
    logic sample_c, sample_c_next;  // 3rd sample data
    logic bit_done, bit_done_next;  // bit ready to save
    logic rx_done_next;             // receive done

    always_ff @(posedge clk) begin
        state <= state_next;
        data_idx <= data_idx_next;
        s_cnt <= s_cnt_next;
        sample_a <= sample_a_next;
        sample_b <= sample_b_next;
        sample_c <= sample_c_next;
        bit_done <= bit_done_next;
        rx_done <= rx_done_next;

        if (rst) begin
            state <= IDLE;
            data_idx <= 0;
            s_cnt <= 0;
            sample_a <= 0;
            sample_b <= 0;
            sample_c <= 0;
        end
    end

    always_comb begin
        state_next = state;  // remain in existing state by default
        data_idx_next = data_idx;
        s_cnt_next = s_cnt;
        sample_a_next = sample_a;
        sample_b_next = sample_b;
        sample_c_next = sample_c;
        bit_done_next = 0;  // default to 0 (high for one tick only)
        rx_done_next = 0;

        case(state)
            IDLE: begin  // rx going low signals start
                if (rx == 0) begin  // should we consider multiple samples?
                    state_next = START;
                    s_cnt_next = 0;
                end
            end
            START: begin
                if (stb_sample) begin
                    if (s_cnt == S_END) begin  // end of start bit
                        state_next = DATA;
                        data_idx_next = 0;
                        s_cnt_next = 0;
                    end else s_cnt_next = s_cnt + 1;
                end
            end
            DATA: begin
                if (stb_sample) begin
                    if (s_cnt == S_SAMPLE_A) begin
                        sample_a_next = rx;
                        s_cnt_next = s_cnt + 1;
                    end else if (s_cnt == S_SAMPLE_B) begin
                        sample_b_next = rx;
                        s_cnt_next = s_cnt + 1;
                    end else if (s_cnt == S_SAMPLE_C) begin
                        sample_c_next = rx;
                        bit_done_next = 1;  // final sample
                        s_cnt_next = s_cnt + 1;
                    end else if (s_cnt == S_END) begin
                        if (data_idx == LAST_BIT) state_next = STOP;  // last data bit done?
                        data_idx_next = data_idx + 1;
                        s_cnt_next = 0;
                    end else s_cnt_next = s_cnt + 1;
                end
            end
            STOP: begin
                if (stb_sample) begin
                    if (s_cnt == S_END) begin
                        state_next = IDLE;
                        rx_done_next = 1;
                    end else s_cnt_next = s_cnt + 1;
                end
            end
        endcase
    end

    // We only considers one sample (sample_b) at the moment
    // Using sample_a and sample_c will help with noise etc.
    always @(posedge clk) begin
        if (bit_done) data_out[data_idx] <= (sample_b) ? 1 : 0;
    end
endmodule
