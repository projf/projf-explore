// Project F: Framebuffers - Top David v3 (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_david_v3 (
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

    // generate pixel clocks
    logic clk_pix;                  // pixel clock
    logic clk_pix_5x;               // 5x pixel clock for 10:1 DDR SerDes
    logic clk_pix_locked;           // pixel clock locked?
    clock_gen_720p clock_pix_inst (
        .clk_100m,
        .rst(!btn_rst),             // reset button is active low
        .clk_pix,
        .clk_pix_5x,
        .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame;
    display_720p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_pix_locked),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        /* verilator lint_off PINCONNECTEMPTY */
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // framebuffer (FB)
    localparam FB_WIDTH   = 160;
    localparam FB_HEIGHT  = 120;
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "david.mem";
    localparam FB_PALETTE = "david_palette.mem";

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_cidx_write, fb_cidx_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb_cidx_read)
    );

    // draw box around framebuffer
    logic [$clog2(FB_WIDTH)-1:0] cnt_draw;
    enum {IDLE, TOP, RIGHT, BOTTOM, LEFT, DONE} state;
    always_ff @(posedge clk_pix) begin
        case (state)
            TOP:
                if (cnt_draw < FB_WIDTH-1) begin
                    fb_addr_write <= fb_addr_write + 1;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    cnt_draw <= 0;
                    state <= RIGHT;
                end
            RIGHT:
                if (cnt_draw < FB_HEIGHT-1) begin
                    fb_addr_write <= fb_addr_write + FB_WIDTH;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    fb_addr_write <= 0;
                    cnt_draw <= 0;
                    state <= LEFT;
                end
            LEFT:
                if (cnt_draw < FB_HEIGHT-1) begin
                    fb_addr_write <= fb_addr_write + FB_WIDTH;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    cnt_draw <= 0;
                    state <= BOTTOM;
                end
            BOTTOM:
                if (cnt_draw < FB_WIDTH-1) begin
                    fb_addr_write <= fb_addr_write + 1;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    fb_we <= 0;
                    state <= DONE;
                end
            IDLE:
                if (frame) begin
                    fb_cidx_write <= 4'h0;  // palette index
                    fb_we <= 1;
                    cnt_draw <= 0;
                    state <= TOP;
                end
            default: state <= DONE;  // done forever!
        endcase
    end

    logic paint;  // which area of the framebuffer should we paint?
    always_comb paint = (sy >= 120 && sy < 600 && sx >= 320 && sx < 960);  //4:3

    // calculate framebuffer read address for display output
    // crude scaling adds a cycle of latency
    always_ff @(posedge clk_pix) begin
        /* verilator lint_off WIDTH */
        if (paint) fb_addr_read <= FB_WIDTH * ((sy-120)/4) + ((sx-320)/4);
        /* verilator lint_on WIDTH */
    end

    // add register between BRAM and CLUT (async ROM)
    logic [FB_DATAW-1:0] fb_cidx_read_p1;
    always_ff @(posedge clk_pix) fb_cidx_read_p1 <= fb_cidx_read;

    // colour lookup table (ROM) 16x12-bit entries
    logic [11:0] clut_colr;
    rom_async #(
        .WIDTH(12),
        .DEPTH(16),
        .INIT_F(FB_PALETTE)
    ) clut (
        .addr(fb_cidx_read_p1),
        .data(clut_colr)
    );

    // address calc, BRAM read, and CLUT reg add three cycles of latency
    localparam LAT = 3;  // display latency
    logic [LAT-1:0] paint_sr, hsync_sr, vsync_sr, de_sr;
    always_ff @(posedge clk_pix) begin
        paint_sr <= {paint, paint_sr[LAT-1:1]};
        hsync_sr <= {hsync, hsync_sr[LAT-1:1]};
        vsync_sr <= {vsync, vsync_sr[LAT-1:1]};
        de_sr <= {de, de_sr[LAT-1:1]};
    end

    logic [3:0] red, green, blue;  // map colour index to palette using CLUT
    always_comb {red, green, blue} = paint_sr[0] ? clut_colr : 12'h0;

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync_sr[0];
        dvi_vsync <= vsync_sr[0];
        dvi_de    <= de_sr[0];
        dvi_red   <= {red,red};
        dvi_green <= {green,green};
        dvi_blue  <= {blue,blue};
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
