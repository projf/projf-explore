// Project F: Framebuffers - Linebuffer Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_tb();

    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    logic clk_25m;
    logic clk_100m;
    logic rst_in;   // clk_100m domain
    logic rst_out;  // clk_25m domain

    parameter LB_SCALE = 2;  // scale (horizontal and vertical)
    parameter LB_LEN = 3;    // 3 pixels in test line
    parameter LB_BPC = 4;    // bits per colour channel

    // test data 3x2 pixels (values defined later in module)
    parameter PIXEL_CNT = 6;
    logic [LB_BPC-1:0] ch0 [PIXEL_CNT];
    logic [LB_BPC-1:0] ch1 [PIXEL_CNT];
    logic [LB_BPC-1:0] ch2 [PIXEL_CNT];

    logic data_req;
    logic en_in;
    logic en_out;
    logic frame;
    logic line;
    logic [LB_BPC-1:0] din_0, din_1, din_2;
    logic [LB_BPC-1:0] dout_0, dout_1, dout_2;

    // Load test data (clk_in domain)
    logic [$clog2(PIXEL_CNT)-1:0] read_addr;
    logic [$clog2(LB_LEN+1)-1:0] cnt_h;  // count pixels in line to read
    always_ff @(posedge clk_100m) begin
        if (data_req) begin
            cnt_h <= 0;
            en_in <= 1;
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            read_addr <= read_addr == PIXEL_CNT-1 ? 0 : read_addr + 1;
        end
        if (cnt_h == LB_LEN-1) en_in <= 0;  // disable en_in at line end
        if (frame) read_addr <= 0;  // start new frame
        if (rst_in) begin
            read_addr <= 0;
            cnt_h <= 0;
            en_in <= 0;
        end
    end

    linebuffer #(
        .WIDTH(LB_BPC),
        .LEN(LB_LEN),
        .SCALE(LB_SCALE)
        ) lb_inst (
        .clk_in(clk_100m),
        .clk_out(clk_25m),
        .rst_in,
        .rst_out,
        .data_req,
        .en_in,
        .en_out,
        .frame,
        .line,
        .din_0,
        .din_1,
        .din_2,
        .dout_0,
        .dout_1,
        .dout_2
    );

    // generate clocks
    always #(CLK_PERIOD_100M / 2) clk_100m = ~clk_100m;
    always #(CLK_PERIOD_25M / 2) clk_25m = ~clk_25m;

    // test data values
    initial begin
        ch0[0] = 4'b1010;  // 0xA
        ch1[0] = 4'b0101;  // 0x5
        ch2[0] = 4'b1111;  // 0xF

        ch0[1] = 4'b1000;  // 0x8
        ch1[1] = 4'b0100;  // 0x4
        ch2[1] = 4'b0010;  // 0x2

        ch0[2] = 4'b0000;  // 0x0
        ch1[2] = 4'b0010;  // 0x2
        ch2[2] = 4'b0001;  // 0x1

        ch0[3] = 4'b0101;  // 0x5
        ch1[3] = 4'b1010;  // 0xA
        ch2[3] = 4'b0000;  // 0x0

        ch0[4] = 4'b0000;  // 0x0
        ch1[4] = 4'b0010;  // 0x2
        ch2[4] = 4'b0001;  // 0x1

        ch0[5] = 4'b1000;  // 0x8
        ch1[5] = 4'b0100;  // 0x4
        ch2[5] = 4'b0010;  // 0x2
    end

    always_comb begin
        din_0 = ch0[read_addr];
        din_1 = ch1[read_addr];
        din_2 = ch2[read_addr];
    end

    initial begin
        clk_100m = 1;
        rst_in = 1;
        frame = 0;

         #100 rst_in = 0;

         #240 frame = 1;
          #40 frame = 0;

        #1800 frame = 1;
          #40 frame = 0;

        #1800 frame = 1;
          #40 frame = 0;

        #1800 frame = 1;
          #40 frame = 0;
    end

    // we should get 6x4 pixels of output (3x2 with scale=2)
    initial begin
        clk_25m = 1;
        rst_out = 1;
        en_out = 0;
        line = 0;

        #100 rst_out = 0;

        #300 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;

        #160 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;

        #160 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 line = 1;
         #40 line = 0;
         #80 en_out = 1;
        #240 en_out = 0;

        #1000 $finish;
    end
endmodule
