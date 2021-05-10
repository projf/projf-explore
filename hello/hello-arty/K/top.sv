// Project F: Hello Arty K - Top
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    input wire logic btn_ctrl,
    input wire logic btn_0,
    input wire logic btn_1,
    output     logic [3:0] led
    );

    localparam FLASH_TIME = 4;  // seconds to flash at end of timer
    logic [$clog2(FLASH_TIME+1)-1:0] cnt_flash;  // counter for done flashing

    // debounce buttons
    logic sig_ctrl, sig_0, sig_1;  // signal button presses
    debounce deb_ctrl (.clk, .in(btn_ctrl), .out(), .ondn(), .onup(sig_ctrl));
    debounce deb_0 (.clk, .in(btn_0), .out(), .ondn(), .onup(sig_0));
    debounce deb_1 (.clk, .in(btn_1), .out(), .ondn(), .onup(sig_1));

    // finite state machine control process
    enum {IDLE, SET_TIME, COUNTDOWN, DONE} state, state_next;
    always_comb begin
        case (state)
            IDLE:      state_next = (sig_ctrl) ? SET_TIME : IDLE;
            SET_TIME:  state_next = (sig_ctrl) ? COUNTDOWN : SET_TIME;
            COUNTDOWN: state_next = (led == 0) ? DONE : COUNTDOWN;
            DONE:      state_next = (cnt_flash == 0) ? IDLE : DONE;
            default:   state_next = IDLE;
        endcase
    end

    // save next FSM state
    always_ff @(posedge clk) state <= state_next;

    // generate 1 second strobe from 100 MHz clock
    localparam DIV_BY = 27'd100_000_000;  // 100 million
    logic stb;
    logic [26:0] cnt = 0;
    always_ff @(posedge clk) begin
        if (cnt != DIV_BY-1) begin
            stb <= 0;
            cnt <= cnt + 1;
        end else begin
            stb <= 1;
            cnt <= 0;
        end
    end

    // finite state machine output process
    always_ff @(posedge clk) begin
        case (state)
            IDLE: cnt_flash <= FLASH_TIME;  // initialize flash timer
            SET_TIME: begin
                if (sig_0) led <= {led[2:0], 1'b0};  // user pressed 0
                else if (sig_1) led <= {led[2:0], 1'b1};  // user pressed 1
            end
            COUNTDOWN: if (stb) led <= led - 1;
            DONE: begin
                led <= {4{cnt[23]}};  // flash rate is 2^23 x 10ns
                if (stb) cnt_flash <= cnt_flash - 1;
            end
        endcase
    end
endmodule
