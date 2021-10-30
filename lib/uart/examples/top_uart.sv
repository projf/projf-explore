// Project F Library - UART 8N1 Example
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

// UART example that echos characters back to the transmitter
// Set for 9600 baud and 8N1 (8 data bits, no parity bit, one stop bit)

// Requires pin constraints for:
//   * btn_rst - reset button (assumed to be active low)
//   * uart_rx - receive pin (to FPGA)
//   * uart_tx - transmit pin (from FPGA)

`default_nettype none
`timescale 1ns / 1ps

module top_uart (
    input  wire logic clk_100m,  // assumes 100 MHz (adjust uart_baud params if not)
    input  wire logic btn_rst,   // assumes active low (adjust module instances if not)
    input  wire logic uart_rx,   // receive pin (to FPGA)
    output      logic uart_tx    // transmit pin (from FPGA)
    );

    // baud generator: 100 MHz -> 153,600 (16 x 9,600)
    // 100 MHz / 153,600 = 651.04; 2^24/651.04 = 25,770
    localparam CNT_W=24;            // baud counter width
    localparam CNT_INC=24'd25770;   // baud counter increment
    logic stb_baud, stb_sample;
    uart_baud #(
        .CNT_W(CNT_W),
        .CNT_INC(CNT_INC)
    ) baud_gen (
        .clk(clk_100m),
        .rst(),
        .stb_baud,
        .stb_sample
    );

    // receiver (to FPGA)
    logic rx_done;
    logic [7:0] received;
    uart_rx uart_rx_inst(
        .clk(clk_100m),
        .rst(!btn_rst),  // reset button is active low
        .stb_sample,
        .data_in(uart_rx),
        .data_out(received),
        .rx_done
    );

    // transmitter (from FPGA)
    logic tx_start, tx_busy, tx_next;
    uart_tx uart_tx_inst (
        .clk(clk_100m),
        .rst(!btn_rst),  // reset button is active low
        .stb_baud,
        .tx_start,
        .data_in(received),
        .data_out(uart_tx),
        .tx_busy,
        .tx_next
    );

    // buffer RX done signal for TX start
    always_ff @(posedge clk_100m) begin
        if (rx_done) tx_start <= 1;
        if (stb_baud) tx_start <= 0;
    end
endmodule
