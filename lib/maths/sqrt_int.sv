// Project F Library - Square Root (Integer)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sqrt_int #(parameter WIDTH=8) (      // width of radicand
    input wire logic clk,
    input wire logic start,             // start signal
    output     logic busy,              // calculation in progress
    output     logic valid,             // root and rem are valid
    input wire logic [WIDTH-1:0] rad,   // radicand
    output     logic [WIDTH-1:0] root,  // root
    output     logic [WIDTH-1:0] rem    // remainder
    );

    logic [WIDTH-1:0] x, x_next;    // radicand copy
    logic [WIDTH-1:0] q, q_next;    // intermediate root (quotient)
    logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res;     // sign test result (2 bits wider)

    localparam ITER = WIDTH >> 1;   // iterations are half radicand width
    logic [$clog2(ITER)-1:0] i;     // iteration counter

    always_comb begin
        test_res = ac - {q, 2'b01};
        if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
            {ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
            q_next = {q[WIDTH-2:0], 1'b1};
        end else begin
            {ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
            q_next = q << 1;
        end
    end

    always_ff @(posedge clk) begin
        if (start) begin
            busy <= 1;
            valid <= 0;
            i <= 0;
            q <= 0;
            {ac, x} <= {{WIDTH{1'b0}}, rad, 2'b0};
        end else if (busy) begin
            if (i == ITER-1) begin  // we're done
                busy <= 0;
                valid <= 1;
                root <= q_next;
                rem <= ac_next[WIDTH+1:2];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                x <= x_next;
                ac <= ac_next;
                q <= q_next;
            end
        end
    end
endmodule
