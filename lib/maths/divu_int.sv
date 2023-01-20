// Project F Library - Division: Unsigned Integer with Remainder
// (C)2023 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io/verilog-lib/

`default_nettype none
`timescale 1ns / 1ps

module divu_int #(parameter WIDTH=5) ( // width of numbers in bits
    input wire logic clk,              // clock
    input wire logic rst,              // reset
    input wire logic start,            // start calculation
    output     logic busy,             // calculation in progress
    output     logic done,             // calculation is complete (high for one tick)
    output     logic valid,            // result is valid
    output     logic dbz,              // divide by zero
    input wire logic [WIDTH-1:0] a,    // dividend (numerator)
    input wire logic [WIDTH-1:0] b,    // divisor (denominator)
    output     logic [WIDTH-1:0] val,  // result value: quotient
    output     logic [WIDTH-1:0] rem   // result: remainder
    );

    logic [WIDTH-1:0] b1;             // copy of divisor
    logic [WIDTH-1:0] quo, quo_next;  // intermediate quotient
    logic [WIDTH:0] acc, acc_next;    // accumulator (1 bit wider)
    logic [$clog2(WIDTH)-1:0] i;      // iteration counter

    // division algorithm iteration
    always_comb begin
        if (acc >= {1'b0, b1}) begin
            acc_next = acc - b1;
            {acc_next, quo_next} = {acc_next[WIDTH-1:0], quo, 1'b1};
        end else begin
            {acc_next, quo_next} = {acc, quo} << 1;
        end
    end

    // calculation control
    always_ff @(posedge clk) begin
        done <= 0;
        if (start) begin
            valid <= 0;
            i <= 0;
            if (b == 0) begin  // catch divide by zero
                busy <= 0;
                done <= 1;
                dbz <= 1;
            end else begin
                busy <= 1;
                dbz <= 0;
                b1 <= b;
                {acc, quo} <= {{WIDTH{1'b0}}, a, 1'b0};  // initialize calculation
            end
        end else if (busy) begin
            if (i == WIDTH-1) begin  // we're done
                busy <= 0;
                done <= 1;
                valid <= 1;
                val <= quo_next;
                rem <= acc_next[WIDTH:1];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                acc <= acc_next;
                quo <= quo_next;
            end
        end
        if (rst) begin
            busy <= 0;
            done <= 0;
            valid <= 0;
            dbz <= 0;
            val <= 0;
            rem <= 0;
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
