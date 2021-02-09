// Project F: Linebuffer Test Bench (XC7)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer_tb();

    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    logic clk_25m;
    logic clk_100m;

    parameter LB_SCALE = 2;  // scale (horizontal and vertical)
    parameter LB_LEN = 3;    // 3 pixels in test line
    parameter LB_BPC = 4;    // bits per colour channel

    // test data 3x2 pixels (values defined later in module)
    parameter PIXEL_CNT = 6;
    logic [LB_BPC-1:0] ch0 [PIXEL_CNT];
    logic [LB_BPC-1:0] ch1 [PIXEL_CNT];
    logic [LB_BPC-1:0] ch2 [PIXEL_CNT];

    logic vbi = 0;
    logic data_req = 0;
    logic en_in = 0;
    logic last_line;
    logic en_out;
    logic [LB_BPC-1:0] din_0, din_1, din_2;
    logic [LB_BPC-1:0] dout_0, dout_1, dout_2;

    // Load test data
    logic [$clog2(PIXEL_CNT)-1:0] read_addr;
    logic [$clog2(LB_LEN+1)-1:0] cnt_h;  // count pixels in line to read
    always_ff @(posedge clk_100m) begin
        if (vbi) read_addr <= 0;  // new frame
        if (data_req && !last_line) begin  // load next line of data...
            cnt_h <= 0;                    // ...if not on last line
            en_in <= 1;
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            read_addr <= read_addr == PIXEL_CNT-1 ? 0 : read_addr + 1;
        end
        if (cnt_h == LB_LEN-1) en_in <= 0;  // disable en_in at line end
    end

    linebuffer #(
        .WIDTH(LB_BPC),
        .LEN(LB_LEN),
        .SCALE(LB_SCALE)
        ) lb_inst (
        .clk_in(clk_100m),
        .clk_out(clk_25m),
        .data_req,
        .en_in,
        .en_out,
        .vbi,
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
        vbi = 0;

        #120 vbi = 1;
         #40 vbi = 0;

        #1440 vbi = 1;
          #40 vbi = 0;

        #1440 vbi = 1;
          #40 vbi = 0;
    end

    // we should get 6x4 pixels of output (3x2 with scale=2)
    initial begin
        clk_25m  = 1;
        en_out = 0;
        last_line = 0;

        #320 en_out = 1;
        #240 en_out = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 en_out = 1;
             last_line = 1;
        #240 en_out = 0;
         #80 en_out = 1;
        #240 en_out = 0;

        #80 last_line = 0;
        #160 en_out = 1;
        #240 en_out = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 en_out = 1;
             last_line = 1;
        #240 en_out = 0;
         #80 en_out = 1;
        #240 en_out = 0;

        #80 last_line = 0;
        #160 en_out = 1;
        #240 en_out = 0;
         #80 en_out = 1;
        #240 en_out = 0;
         #80 en_out = 1;
             last_line = 1;
        #240 en_out = 0;
         #80 en_out = 1;
        #240 en_out = 0;

        #80 last_line = 0;
        #1000 $finish;
    end
endmodule
