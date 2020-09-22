// Project F: Life on Screen - Top Life Bitmap (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_life (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    parameter GEN_FRAMES = 15;  // each generation lasts this many frames
    parameter SEED_FILE = "simple_life.mem";  // seed to initiate universe with

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .de
    );

    logic frame_end;   // high for one clycle at the end of a frame
    logic line_start;  // high for one cycle at line start (drawing lines only)
    always_comb begin
        frame_end = (sy == 524 && sx == 799);
        line_start = (sy < 480 && sx == 0);
    end

    // life bitmap
    localparam BMP_COUNT  = 2;  // double buffered
    localparam BMP_WIDTH  = 80;
    localparam BMP_HEIGHT = 60;
    localparam BMP_PIXELS = BMP_WIDTH * BMP_HEIGHT;
    localparam BMP_DEPTH  = BMP_COUNT * BMP_PIXELS;
    localparam BMP_ADDRW  = $clog2(BMP_DEPTH);
    localparam BMP_DATAW  = 1;

    logic bmp_we;
    logic [BMP_ADDRW-1:0] bmp_addr_read, bmp_addr_write;
    logic [BMP_DATAW-1:0] bmp_data_in, bmp_data_out;

    bram_sdp #(
        .WIDTH(BMP_DATAW),
        .DEPTH(BMP_DEPTH),
        .INIT_F(SEED_FILE)
    ) bmp_life (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(bmp_we),
        .addr_write(bmp_addr_write),
        .addr_read(bmp_addr_read),
        .data_in(bmp_data_in),
        .data_out(bmp_data_out)
    );

    // update frame counter
    logic life_start;  // trigger next calculation
    logic life_done;   // signals complete calculation
    logic front_buffer;  // which buffer to draw the display from
    logic [$clog2(GEN_FRAMES)-1:0] cnt_frames;
    always_ff @(posedge clk_pix) begin
        if (frame_end) cnt_frames <= cnt_frames + 1;
        if (cnt_frames == GEN_FRAMES - 1) begin
            front_buffer <= ~front_buffer;
            cnt_frames <= 0;
            life_start <= 1;
        end else life_start <= 0;
    end

    logic life_run;
    logic [BMP_ADDRW-1:0] cell_id;
    life #(
        .WORLD_WIDTH(BMP_WIDTH),
        .WORLD_HEIGHT(BMP_HEIGHT),
        .ADDRW(BMP_ADDRW)
    ) life_sim (
        .clk(clk_pix),
        .start(life_start),
        .run(life_run),
        .id(cell_id),
        .r_status(bmp_data_out),
        .w_status(bmp_data_in),
        .we(bmp_we),
        .done(life_done)
    );

    // line buffer
    localparam LB_SCALE_V = 8;                // factor to scale vertical drawing
    localparam LB_SCALE_H = 8;                // factor to scale horizontal drawing
    localparam LB_LINE  = 640 / LB_SCALE_H;   // line length
    localparam LB_ADDRW = $clog2(LB_LINE);    // line address width
    localparam LB_WIDTH = 4;                  // 4-bits per colour channel

    // line buffer read port (pixel clock)
    logic [LB_ADDRW-1:0] lb_addr_read_pix;
    logic [LB_WIDTH-1:0] lb0_out_pix, lb1_out_pix, lb2_out_pix;

    // line buffer write port (system clock - latency corrected)
    logic lb_re;  // signals when the line buffer needs to read data from bitmap
    logic [2:0] lb_we, lb_we_l1;
    logic [LB_ADDRW-1:0] lb_addr_write, lb_addr_write_l1;
    logic [LB_WIDTH-1:0] lb0_in, lb1_in, lb2_in;

    // latency correction
    always_ff @(posedge clk_pix) begin
        lb_we_l1 <= lb_we;
        lb_addr_write_l1 <= lb_addr_write;
    end

    linebuffer #(
        .WIDTH(LB_WIDTH),
        .DEPTH(LB_LINE)
        ) lb (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(lb_we_l1),                  // use lb_we_l1 to correct for latency
        .addr_write(lb_addr_write_l1),  // use lb_addr_write_l1 to correct for latency
        .addr_read(lb_addr_read_pix),
        .data_in_0(lb0_in),
        .data_in_1(lb1_in),
        .data_in_2(lb2_in),
        .data_out_0(lb0_out_pix),
        .data_out_1(lb1_out_pix),
        .data_out_2(lb2_out_pix)
    );

    // address for lb to read from bitmap
    logic [BMP_ADDRW-1:0] lb_bmp_addr_read;
    always_ff @(posedge clk_pix) begin
        if (frame_end) begin
            lb_bmp_addr_read <= 0;
        end else if (lb_re) begin
            lb_bmp_addr_read <= lb_bmp_addr_read + 1;
        end
    end

    // calculate linebuffer system address
    logic [$clog2(LB_SCALE_V)-1:0] lb_repeat;  // repeat line based on scale
    always_ff @(posedge clk_pix) begin
        if (line_start) begin  // start new line
            if (lb_repeat == 0) begin  // time to read a fresh line of data?
                lb_re <= 1;
                lb_we <= 3'b111;
                lb_addr_write <= 0;
            end
            lb_repeat <= (lb_repeat == LB_SCALE_V-1) ? 0 : lb_repeat + 1;
        end else begin
            if (lb_addr_write < LB_LINE-1) begin  // next pixel
                lb_addr_write <= lb_addr_write + 1;
            end else begin  // disable drawing at end of line
                lb_re <= 0;
                lb_we <= 0;
            end
        end
    end

    // sim can run when linebuffer is not requesting data (leave one line empty)
    always_comb life_run = (lb_repeat > 1 && lb_repeat < LB_SCALE_V-1);

    // calculate linebuffer pixel address
    logic [$clog2(LB_SCALE_H)-1:0] scale_pix_cnt;
    always_ff @(posedge clk_pix) begin
        if (sx == 798) begin  // address 0 when sx=799, so we need to set when sx=798 (latency=1)
            lb_addr_read_pix <= 0;
            scale_pix_cnt <= 0;
        end else if (lb_addr_read_pix < LB_LINE-1) begin
            scale_pix_cnt <= (scale_pix_cnt < LB_SCALE_H-1) ? scale_pix_cnt + 1 : 0;
            if (scale_pix_cnt == LB_SCALE_H-1) lb_addr_read_pix <= lb_addr_read_pix + 1;
        end
    end

    // read into line buffer
    always_comb begin
        bmp_addr_read = (lb_re) ? lb_bmp_addr_read : cell_id;
        if (front_buffer == 1) bmp_addr_read = bmp_addr_read + BMP_PIXELS;
        bmp_addr_write = (front_buffer == 1) ? cell_id : cell_id + BMP_PIXELS;
        lb0_in = (bmp_data_out) ? 4'hF : 4'h9;
        lb1_in = (bmp_data_out) ? 4'hF : 4'h0;
        lb2_in = (bmp_data_out) ? 4'hF : 4'h0;
    end

    // VGA output
    always_comb begin
        vga_r = de ? lb2_out_pix : 4'h0;
        vga_g = de ? lb1_out_pix : 4'h0;
        vga_b = de ? lb0_out_pix : 4'h0;
    end
endmodule
