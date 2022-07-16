// Project F Library - Test Bench for Cross Domain Flag
// (C)2022 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module xd2_tb();

    parameter CLK_SLOW_PERIOD = 10;  // 10 ns == 100 MHz
    parameter CLK_FAST_PERIOD =  4;  //  4 ns == 250 MHz

    logic clk_slow, clk_fast;
    logic flag_a_src, flag_a_dst;  // for slow->fast
    logic flag_b_src, flag_b_dst;  // for fast->slow

    xd2 xd_slowfast (
        .clk_src(clk_slow),
        .clk_dst(clk_fast),
        .flag_src(flag_a_src),
        .flag_dst(flag_a_dst)
    );

    xd2 xd_fastslow (
        .clk_src(clk_fast),
        .clk_dst(clk_slow),       
        .flag_src(flag_b_src),
        .flag_dst(flag_b_dst)
    );

    always #(CLK_SLOW_PERIOD / 2) clk_slow = ~clk_slow;
    always #(CLK_FAST_PERIOD / 2) clk_fast = ~clk_fast;

    initial begin
        clk_slow = 1;
        flag_a_src = 0;

        #100 flag_a_src = 1;
         #10 flag_a_src = 0;
         #40 flag_a_src = 1;
         #10 flag_a_src = 0;

        #100 flag_a_src = 1;
         #10 flag_a_src = 0;
         #10 flag_a_src = 1;
         #10 flag_a_src = 0;
         #30 flag_a_src = 1;
         #10 flag_a_src = 0;
         #40 flag_a_src = 1;
         #10 flag_a_src = 0;

        #100 flag_a_src = 1;  // two-cycles becomes two pulses in fast domain!
         #20 flag_a_src = 0;

        #100 $finish;
    end

    initial begin
        clk_fast = 1;
        flag_b_src = 0;

        #200 flag_b_src = 1;
          #4 flag_b_src = 0;
         #16 flag_b_src = 1;
          #4 flag_b_src = 0;

        #100 flag_b_src = 1;
          #4 flag_b_src = 0;
          #4 flag_b_src = 1;
          #4 flag_b_src = 0;
         #12 flag_b_src = 1;  // this is too close
          #4 flag_b_src = 0;
         #16 flag_b_src = 1;  // this is far enough apart
          #4 flag_b_src = 0;

        #100 flag_b_src = 1;  // two-cycles just vanish in slow domain!
          #8 flag_b_src = 0;
    end
endmodule
