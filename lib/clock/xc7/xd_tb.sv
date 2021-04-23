// Project F Library - Test Bench for Cross Domain Pulse
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module xd_tb();

    parameter CLK_SLOW_PERIOD = 10;  // 10 ns == 100 MHz
    parameter CLK_FAST_PERIOD =  4;  //  4 ns == 250 MHz

    logic clk_slow, clk_fast;
    logic rst_slow, rst_fast;
    logic pulse_a_src, pulse_a_dst;  // for slow->fast
    logic pulse_b_src, pulse_b_dst;  // for fast->slow

    xd xd_slowfast (
        .clk_i(clk_slow),
        .clk_o(clk_fast),
        .rst_i(rst_slow),
        .rst_o(rst_fast),
        .i(pulse_a_src),
        .o(pulse_a_dst)
    );

    xd xd_fastslow (
        .clk_i(clk_fast),
        .clk_o(clk_slow),
        .rst_i(rst_fast),
        .rst_o(rst_slow),        
        .i(pulse_b_src),
        .o(pulse_b_dst)
    );

    always #(CLK_SLOW_PERIOD / 2) clk_slow = ~clk_slow;
    always #(CLK_FAST_PERIOD / 2) clk_fast = ~clk_fast;

    initial begin
        clk_slow = 1;
        clk_fast = 1;
        rst_slow = 1;
        rst_fast = 1;
        pulse_a_src = 0;

        #100 rst_slow = 0;
             rst_fast = 0;

        #100 pulse_a_src = 1;
         #10 pulse_a_src = 0;
         #40 pulse_a_src = 1;
         #10 pulse_a_src = 0;

        #100 pulse_a_src = 1;
         #10 pulse_a_src = 0;
         #10 pulse_a_src = 1;
         #10 pulse_a_src = 0;
         #30 pulse_a_src = 1;
         #10 pulse_a_src = 0;
         #40 pulse_a_src = 1;
         #10 pulse_a_src = 0;

        #100 pulse_a_src = 1;  // two-cycles becomes two pulses in fast domain!
         #20 pulse_a_src = 0;

        #100 $finish;
    end

    initial begin
        pulse_b_src = 0;

        #200 pulse_b_src = 1;
          #4 pulse_b_src = 0;
         #16 pulse_b_src = 1;
          #4 pulse_b_src = 0;

        #100 pulse_b_src = 1;
          #4 pulse_b_src = 0;
          #4 pulse_b_src = 1;
          #4 pulse_b_src = 0;
         #12 pulse_b_src = 1;  // this is too close
          #4 pulse_b_src = 0;
         #16 pulse_b_src = 1;  // this is far enough apart
          #4 pulse_b_src = 0;

        #100 pulse_b_src = 1;  // two-cycles just vanish in slow domain!
          #8 pulse_b_src = 0;
    end
endmodule
