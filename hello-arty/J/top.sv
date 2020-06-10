// Project F: Hello Arty J - Top
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top(
    input  wire logic clk,
    output      logic [3:0] led_r,
    output      logic [3:0] led_g,
    output      logic [3:0] led_b
    );

    pwm pwm_led_r0 (.clk, .duty(0),  .pwm_out(led_r[0]));
    pwm pwm_led_g0 (.clk, .duty(64), .pwm_out(led_g[0]));
    pwm pwm_led_b0 (.clk, .duty(64), .pwm_out(led_b[0]));
endmodule
