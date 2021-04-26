// Project F Library - Division (Integer)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module div_int #(parameter WIDTH=4) (
    input wire logic clk,
    input wire logic start,          // start signal
    output     logic busy,           // calculation in progress
    output     logic valid,          // quotient and remainder are valid
    output     logic dbz,            // divide by zero flag
    input wire logic [WIDTH-1:0] x,  // dividend
    input wire logic [WIDTH-1:0] y,  // divisor
    output     logic [WIDTH-1:0] q,  // quotient
    output     logic [WIDTH-1:0] r   // remainder
    );

    logic [WIDTH-1:0] y1;            // copy of divisor
    logic [WIDTH-1:0] q1, q1_next;   // intermediate quotient
    logic [WIDTH:0] ac, ac_next;     // accumulator (1 bit wider)
    logic [$clog2(WIDTH)-1:0] i;     // iteration counter

    always_comb begin
        if (ac >= {1'b0,y1}) begin
            ac_next = ac - y1;
            {ac_next, q1_next} = {ac_next[WIDTH-1:0], q1, 1'b1};
        end else begin
            {ac_next, q1_next} = {ac, q1} << 1;
        end
    end

    always_ff @(posedge clk) begin
        if (start) begin
            valid <= 0;
            i <= 0;
            if (y == 0) begin  // catch divide by zero
                busy <= 0;
                dbz <= 1;
            end else begin  // initialize values
                busy <= 1;
                dbz <= 0;
                y1 <= y;
                {ac, q1} <= {{WIDTH{1'b0}}, x, 1'b0};
            end
        end else if (busy) begin
            if (i == WIDTH-1) begin  // we're done
                busy <= 0;
                valid <= 1;
                q <= q1_next;
                r <= ac_next[WIDTH:1];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                ac <= ac_next;
                q1 <= q1_next;
            end
        end
    end
endmodule
