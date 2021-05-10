// Project F: Hello Arty L - Top Traffic Lights
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top (
    input wire logic clk,
    output      logic led_main_r,
    output      logic led_main_g,
    output      logic led_main_b,
    output      logic led_side_r,
    output      logic led_side_g,
    output      logic led_side_b
    );

    logic [7:0] duty_main_r, duty_main_g, duty_main_b;
    logic [7:0] duty_side_r, duty_side_g, duty_side_b;

    pwm pwm_main_r (.clk, .duty(duty_main_r), .pwm_out(led_main_r));
    pwm pwm_main_g (.clk, .duty(duty_main_g), .pwm_out(led_main_g));
    pwm pwm_main_b (.clk, .duty(duty_main_b), .pwm_out(led_main_b));

    pwm pwm_side_r (.clk, .duty(duty_side_r), .pwm_out(led_side_r));
    pwm pwm_side_g (.clk, .duty(duty_side_g), .pwm_out(led_side_g));
    pwm pwm_side_b (.clk, .duty(duty_side_b), .pwm_out(led_side_b));

    always_comb begin
        // // red
        // duty_main_r = 8'd64;
        // duty_main_g = 8'd0;
        // duty_main_b = 8'd0;

        // red-amber
        duty_side_r = 8'd56;
        duty_side_g = 8'd8;
        duty_side_b = 8'd0;

        // amber
        duty_main_r = 8'd48;
        duty_main_g = 8'd16;
        duty_main_b = 8'd0;

        // // green
        // duty_side_r = 8'd0;
        // duty_side_g = 8'd64;
        // duty_side_b = 8'd0;
    end
endmodule
