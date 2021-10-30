// Project F Library - UART Baud Generator
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

// baud generator: 100 MHz -> 153,600 (16 x 9,600)
// 100 MHz / 153,600 = 651.04; 2^24/651.04 = 25,770

module uart_baud #(
    parameter CNT_W=24,          // counter width
    parameter CNT_INC=24'd25770  // counter increment
    ) (
    input  wire logic clk,
    input  wire logic rst,
    output      logic stb_baud,   // baud strobe
    output      logic stb_sample  // over-sampling baud strobe
    );

    logic [CNT_W+3:0] cnt;
    logic [CNT_W-1:0] cnt_16x;

    always_ff @(posedge clk) begin
        {stb_baud, cnt} <= cnt + {4'b0000, CNT_INC};

        if (rst) begin
            stb_baud <= 1'b0;
            cnt <= {CNT_W+4{1'b0}};
        end
    end

    always_ff @(posedge clk) begin
        {stb_sample, cnt_16x} <= cnt_16x + CNT_INC;

        if (rst) begin
            stb_sample <= 1'b0;
            cnt_16x <= {CNT_W{1'b0}};
        end
    end
endmodule
