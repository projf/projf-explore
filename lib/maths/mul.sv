// Project F Library - Multiplication: Signed Fixed-Point
// (C)2023 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io/verilog-lib/

`default_nettype none
`timescale 1ns / 1ps

module mul #(
    parameter WIDTH=8,  // width of numbers in bits (integer and fractional)
    parameter FBITS=4   // fractional bits within WIDTH
    ) (
    input wire logic clk,    // clock
    input wire logic rst,    // reset
    input wire logic start,  // start calculation
    output     logic busy,   // calculation in progress
    output     logic done,   // calculation is complete (high for one tick)
    output     logic valid,  // result is valid
    output     logic ovf,    // overflow
    input wire logic signed [WIDTH-1:0] a,   // multiplier (factor)
    input wire logic signed [WIDTH-1:0] b,   // mutiplicand (factor)
    output     logic signed [WIDTH-1:0] val  // result value: product
    );

    // for selecting result
    localparam IBITS = WIDTH - FBITS;
    localparam MSB = 2*WIDTH - IBITS - 1;
    localparam LSB = WIDTH - IBITS;

    // for rounding
    localparam HALF = {1'b1, {FBITS-1{1'b0}}};

    logic signed [WIDTH-1:0] a1, b1;  // copy of inputs
    logic signed [WIDTH-1:0] c1;      // unrounded, truncated product
    logic signed [2*WIDTH-1:0] cf;    // full product
    logic [FBITS-1:0] rbits;          // rounding bits
    logic round;  // rounding required
    logic even;   // even number

    // calculation state machine
    enum {IDLE, CALC, TRUNC, ROUND} state;
    always_ff @(posedge clk) begin
        done <= 0;
        case (state)
            CALC: begin
                state <= TRUNC;
                cf <= a1 * b1;
            end
            TRUNC: begin
                // need to check for overflow (need to look at MSB)
                state <= ROUND;
                c1    <= cf[MSB:LSB];
                rbits <= cf[FBITS-1:0];
                round <= cf[FBITS-1+:1];
                even  <= ~cf[FBITS+:1];
            end
            ROUND: begin  // round half to even
                $display("cf: %b (even=%b) (round=%b)", cf, even, round);
                $display("overflow bits: %b", cf[2*WIDTH-1:MSB+1]);
                state <= IDLE;
                val <= (round && !(even && rbits == HALF)) ? c1 + 1 : c1;

                // this check isn't enough as mul can cause "sign change" obscuring overflow
                if (cf[2*WIDTH-1:MSB+1] == '0 || cf[2*WIDTH-1:MSB+1] == '1) begin // check overflow
                    valid <= 1;
                    ovf <= 0;
                end else begin
                    valid <= 0;
                    ovf <= 1;
                end

                busy <= 0;
                done <= 1;
            end
            default: begin
                if (start) begin
                    state <= CALC;
                    a1 <= a;
                    b1 <= b;
                    busy <= 1;
                    ovf <= 0;
                end
            end
        endcase
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            valid <= 0;
            ovf <= 0;
            val <= 0;
        end
    end

    // generate waveform file with cocotb
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile($sformatf("%m.vcd"));
        $dumpvars;
    end
    `endif
endmodule
