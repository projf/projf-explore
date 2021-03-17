// Project F: Lines and Triangles - Top Cube (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_cube (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst,          // reset button (active low)
    output      logic hdmi_tx_ch0_p,    // HDMI source channel 0 diff+
    output      logic hdmi_tx_ch0_n,    // HDMI source channel 0 diff-
    output      logic hdmi_tx_ch1_p,    // HDMI source channel 1 diff+
    output      logic hdmi_tx_ch1_n,    // HDMI source channel 1 diff-
    output      logic hdmi_tx_ch2_p,    // HDMI source channel 2 diff+
    output      logic hdmi_tx_ch2_n,    // HDMI source channel 2 diff-
    output      logic hdmi_tx_clk_p,    // HDMI source clock diff+
    output      logic hdmi_tx_clk_n     // HDMI source clock diff-
    );

    // pixel clocks
    logic clk_pix;                  // pixel clock (74.25 MHz)
    logic clk_pix_5x;               // 5x pixel clock for 10:1 DDR SerDes
    logic clk_pix_locked;           // pixel clocks locked?
    clock_gen_pix clock_pix_inst (
        .clk_100m,
        .rst(!btn_rst),             // reset button is active low
        .clk_pix,
        .clk_pix_5x,
        .clk_pix_locked
    );

    // display timings
    localparam CORDW = 11;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    display_timings_720p timings_720p (
        .clk_pix,
        .rst(!clk_pix_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 1650;
    localparam V_RES_FULL = 750;
    localparam H_RES = 1280;
    localparam V_RES = 720;

    // vertical blanking interval (will move to display_timings soon)
    logic vbi;
    always_comb vbi = (sy == V_RES && sx == 0);

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 240;
    localparam FB_CORDW   = $clog2(FB_WIDTH);  // assumes WIDTH>=HEIGHT
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_8bit_palette.mem";

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_cidx_write;
    logic [FB_DATAW-1:0] fb_cidx_read, fb_cidx_read_1;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
        ) fb_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb_cidx_read_1)
    );

    // draw cube in framebuffer
    localparam LINE_CNT=9;  // number of lines to draw
    logic [3:0] line_id;  // line identifier
    logic [FB_CORDW-1:0] lx0, ly0, lx1, ly1;  // line coords
    logic [FB_CORDW-1:0] px, py;  // drawing coordinates (pixels)
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk_pix) begin
        draw_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                fb_cidx_write <= 4'h8;  // red
                case (line_id)
                    4'd0: begin
                        lx0 <= 130; ly0 <=  90; lx1 <= 230; ly1 <=  90;
                    end
                    4'd1: begin
                        lx0 <= 230; ly0 <=  90; lx1 <= 230; ly1 <= 190;
                    end
                    4'd2: begin
                        lx0 <= 230; ly0 <= 190; lx1 <= 130; ly1 <= 190;
                    end
                    4'd3: begin
                        lx0 <= 130; ly0 <= 190; lx1 <= 130; ly1 <=  90;
                    end
                    4'd4: begin
                        lx0 <= 130; ly0 <= 190; lx1 <=  90; ly1 <= 150;
                    end
                    4'd5: begin
                        lx0 <=  90; ly0 <= 150; lx1 <=  90; ly1 <=  50;
                    end
                    4'd6: begin
                        lx0 <=  90; ly0 <=  50; lx1 <= 130; ly1 <=  90;
                    end
                    4'd7: begin
                        lx0 <=  90; ly0 <=  50; lx1 <= 190; ly1 <=  50;
                    end
                    4'd8: begin
                        lx0 <= 190; ly0 <=  50; lx1 <= 230; ly1 <=  90;
                    end
                    default: begin  // should never occur
                        lx0 <=   0; ly0 <=   0; lx1 <=   0; ly1 <=   0;
                    end
                endcase
            end
            DRAW: if (draw_done) begin
                if (line_id == LINE_CNT-1) begin
                    state <= DONE;
                end else begin
                    line_id <= line_id + 1;
                    state <= INIT;
                end
            end
            DONE: state <= DONE;
            default: if (vbi) state <= INIT;  // IDLE
        endcase
    end

    // control drawing output enable - wait 300 frames, then 1 pixel/frame
    localparam DRAW_WAIT = 300;
    logic [$clog2(DRAW_WAIT)-1:0] cnt_draw_wait;
    logic draw_oe;
    always_ff @(posedge clk_pix) begin
        draw_oe <= 0;
        if (vbi) begin
            if (cnt_draw_wait != DRAW_WAIT-1) begin
                cnt_draw_wait <= cnt_draw_wait + 1;
            end else draw_oe <= 1;
        end
    end

    draw_line #(.CORDW(FB_CORDW)) draw_line_inst (
        .clk(clk_pix),
        .rst(!clk_pix_locked),
        .start(draw_start),
        .oe(draw_oe),
        .x0(lx0),
        .y0(ly0),
        .x1(lx1),
        .y1(ly1),
        .x(px),
        .y(py),
        .drawing,
        .done(draw_done)
    );

    // pixel coordinate to memory address calculation takes one cycle
    always_ff @(posedge clk_pix) fb_we <= drawing;

    pix_addr #(
        .CORDW(FB_CORDW),
        .ADDRW(FB_ADDRW)
    ) pix_addr_inst (
        .clk(clk_pix),
        .hres(FB_WIDTH),
        .px,
        .py,
        .pix_addr(fb_addr_write)
    );

    // linebuffer (LB)
    localparam LB_SCALE = 3;       // scale (horizontal and vertical)
    localparam LB_LEN = FB_WIDTH;  // line length matches framebuffer
    localparam LB_BPC = 8;         // bits per colour channel

    // LB output to display
    logic lb_en_out;
    always_comb lb_en_out = (de && sx >= 160 && sx < 1120);  // 4:3

    // Load data from FB into LB
    logic lb_data_req;  // LB requesting data
    logic [$clog2(LB_LEN+1)-1:0] cnt_h;  // count pixels in line to read
    always_ff @(posedge clk_pix) begin
        if (vbi) fb_addr_read <= 0;   // new frame
        if (lb_data_req && sy != V_RES-1) begin  // load next line of data...
            cnt_h <= 0;                          // ...if not on last line
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            fb_addr_read <= fb_addr_read == FB_PIXELS-1 ? 0 : fb_addr_read + 1;
        end
    end

    // FB BRAM and CLUT pipeline adds three cycles of latency
    logic lb_en_in_2, lb_en_in_1, lb_en_in;
    always_ff @(posedge clk_pix) begin
        lb_en_in_2 <= (cnt_h < LB_LEN);
        lb_en_in_1 <= lb_en_in_2;
        lb_en_in <= lb_en_in_1;
    end

    // LB colour channels
    logic [LB_BPC-1:0] lb_in_0, lb_in_1, lb_in_2;
    logic [LB_BPC-1:0] lb_out_0, lb_out_1, lb_out_2;

    linebuffer #(
        .WIDTH(LB_BPC),     // data width of each channel
        .LEN(LB_LEN),       // length of line
        .SCALE(LB_SCALE)    // scaling factor (>=1)
        ) lb_inst (
        .clk_in(clk_pix),       // input clock
        .clk_out(clk_pix),      // output clock
        .data_req(lb_data_req), // request input data (clk_in)
        .en_in(lb_en_in),       // enable input (clk_in)
        .en_out(lb_en_out),     // enable output (clk_out)
        .vbi,                   // start of vertical blanking interval (clk_out)
        .din_0(lb_in_0),        // data in (clk_in)
        .din_1(lb_in_1),
        .din_2(lb_in_2),
        .dout_0(lb_out_0),      // data out (clk_out)
        .dout_1(lb_out_1),
        .dout_2(lb_out_2)
    );

    // improve timing with register between BRAM and async ROM
    always @(posedge clk_pix) begin
        fb_cidx_read <= fb_cidx_read_1;
    end

    // colour lookup table (ROM) 16x24-bit entries
    logic [23:0] clut_colr;
    rom_async #(
        .WIDTH(24),
        .DEPTH(16),
        .INIT_F(FB_PALETTE)
    ) clut (
        .addr(fb_cidx_read),
        .data(clut_colr)
    );

    // map colour index to palette using CLUT and read into LB
    always_ff @(posedge clk_pix) begin
        {lb_in_2, lb_in_1, lb_in_0} <= clut_colr;
    end

    // LB output adds one cycle of latency - need to correct display signals
    logic hsync_1, vsync_1, de_1, lb_en_out_1;
    always_ff @(posedge clk_pix) begin
        hsync_1 <= hsync;
        vsync_1 <= vsync;
        de_1 <= de;
        lb_en_out_1 <= lb_en_out;
    end

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync_1;
        dvi_vsync <= vsync_1;
        dvi_de    <= de_1;
        dvi_red   <= lb_en_out_1 ? lb_out_2 : 8'h00;
        dvi_green <= lb_en_out_1 ? lb_out_1 : 8'h00;
        dvi_blue  <= lb_en_out_1 ? lb_out_0 : 8'h00;
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst(!clk_pix_locked),
        .de(dvi_de),
        .data_in_ch0(dvi_blue),
        .data_in_ch1(dvi_green),
        .data_in_ch2(dvi_red),
        .ctrl_in_ch0({dvi_vsync, dvi_hsync}),
        .ctrl_in_ch1(2'b00),
        .ctrl_in_ch2(2'b00),
        .tmds_ch0_serial,
        .tmds_ch1_serial,
        .tmds_ch2_serial,
        .tmds_clk_serial
    );

    // TMDS output pins
    tmds_out tmds_ch0 (.tmds(tmds_ch0_serial),
        .pin_p(hdmi_tx_ch0_p), .pin_n(hdmi_tx_ch0_n));
    tmds_out tmds_ch1 (.tmds(tmds_ch1_serial),
        .pin_p(hdmi_tx_ch1_p), .pin_n(hdmi_tx_ch1_n));
    tmds_out tmds_ch2 (.tmds(tmds_ch2_serial),
        .pin_p(hdmi_tx_ch2_p), .pin_n(hdmi_tx_ch2_n));
    tmds_out tmds_clk (.tmds(tmds_clk_serial),
        .pin_p(hdmi_tx_clk_p), .pin_n(hdmi_tx_clk_n));
endmodule
