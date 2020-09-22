// Project F: Life on Screen - Life Simulation Test Bench (XC7)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module life_tb();
    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic rst;  // not (yet) used by life module
    logic clk_100m;

    parameter WORLD_WIDTH  = 6;
    parameter WORLD_HEIGHT = 6;
    parameter GENERATIONS  = 2;
    parameter DATA_WIDTH   = 1;
    parameter SEED_File = "test_toad.mem";
    parameter CELL_COUNT = WORLD_WIDTH * WORLD_HEIGHT;
    parameter DEPTH = CELL_COUNT * GENERATIONS;
    parameter ADDRW = $clog2(DEPTH);

    logic bmp_we;
    logic [DATA_WIDTH-1:0] r_status, w_status;
    logic [ADDRW-1:0] id;
    logic [ADDRW-1:0] bmp_addr_read, bmp_addr_write;

    logic frontbuffer;
    logic start;
    logic run;
    logic done;

    always_comb begin
        if (frontbuffer == 0) begin
            bmp_addr_read = id;
            bmp_addr_write = id + CELL_COUNT;
        end else begin
            bmp_addr_read = id + CELL_COUNT;
            bmp_addr_write = id;
        end
    end

    bram_sdp #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .INIT_F(SEED_File)
    ) bmp_life (
        .clk_read(clk_100m),
        .clk_write(clk_100m),
        .we(bmp_we),
        .addr_write(bmp_addr_write),
        .addr_read(bmp_addr_read),
        .data_in(w_status),
        .data_out(r_status)
    );

    life #(
        .WORLD_WIDTH(WORLD_WIDTH),
        .WORLD_HEIGHT(WORLD_HEIGHT),
        .ADDRW(ADDRW)
    ) life_sim (
        .clk(clk_100m),
        .start,
        .run,
        .id,
        .r_status,
        .w_status,
        .we(bmp_we),
        .done
    );

    // generate clock
    always #(CLK_PERIOD / 2) clk_100m = ~clk_100m;

    initial begin
        rst = 1;
        clk_100m = 1;

        frontbuffer = 0;
        start = 0;
        run = 0;

        #100 rst = 0;
        start = 1;
        run = 1;
        #10 start = 0;

        #5000 frontbuffer = 1;
        #10 start = 1;
        #10 start = 0;

        #5000 frontbuffer = 0;
        #10 start = 1;
        #10 start = 0;

        #5000 frontbuffer = 1;
        #10 start = 1;
        #10 start = 0;
        
        #5000 $finish;
    end

endmodule
