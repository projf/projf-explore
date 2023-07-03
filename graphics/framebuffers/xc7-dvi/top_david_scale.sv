// Project F: Framebuffers - Scaled David (Nexys Video)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/framebuffers/

`default_nettype none
`timescale 1ns / 1ps

module top_david_scale (
    input  wire logic clk_100m,       // 100 MHz clock
    input  wire logic btn_rst_n,      // reset button
    output      logic hdmi_tx_ch0_p,  // HDMI source channel 0 diff+
    output      logic hdmi_tx_ch0_n,  // HDMI source channel 0 diff-
    output      logic hdmi_tx_ch1_p,  // HDMI source channel 1 diff+
    output      logic hdmi_tx_ch1_n,  // HDMI source channel 1 diff-
    output      logic hdmi_tx_ch2_p,  // HDMI source channel 2 diff+
    output      logic hdmi_tx_ch2_n,  // HDMI source channel 2 diff-
    output      logic hdmi_tx_clk_p,  // HDMI source clock diff+
    output      logic hdmi_tx_clk_n   // HDMI source clock diff-
    );

    // generate system clock
    logic clk_sys;
    logic clk_sys_locked;
    /* verilator lint_off UNUSED */
    logic rst_sys;
    /* verilator lint_on UNUSED */
    clock_sys clock_sys_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_sys,
       .clk_sys_locked
    );
    always_ff @(posedge clk_sys) rst_sys <= !clk_sys_locked;  // wait for clock lock

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_5x;
    logic clk_pix_locked;
    logic rst_pix;
    clock_720p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x,
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_720p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // bitmap images
    localparam BMAP_IMAGE = "david.mem";
    // localparam BMAP_IMAGE = "test_box_160x120.mem";

    // colour palettes
    localparam PAL_FILE = "grey16_4b.mem";
    // localparam PAL_FILE = "greyinvert16_4b.mem";
    // localparam PAL_FILE = "sepia16_4b.mem";
    // localparam PAL_FILE = "sweetie16_4b.mem";

    // colour parameters
    localparam CHANW = 4;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam CIDXW = 4;        // colour index width (bits)
    localparam BG_COLR = 'h137;  // background colour

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;  // framebuffer width in pixels
    localparam FB_HEIGHT = 120;  // framebuffer height in pixels
    localparam FB_SCALE  =   6;  // framebuffer display scale (1-63)
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel

    // pixel read address and colour
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_read;

    // framebuffer memory
    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(BMAP_IMAGE)
    ) bram_inst (
        .clk_write(clk_sys),
        .clk_read(clk_sys),
        /* verilator lint_off PINCONNECTEMPTY */
        .we(),
        .addr_write(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_read(fb_addr_read),
        /* verilator lint_off PINCONNECTEMPTY */
        .data_in(),
        /* verilator lint_on PINCONNECTEMPTY */
        .data_out(fb_colr_read)
    );

    // display flags in system clock domain
    logic frame_sys, line_sys, line0_sys;
    xd xd_frame (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(frame), .flag_dst(frame_sys));
    xd xd_line  (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(line),  .flag_dst(line_sys));
    xd xd_line0 (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(line && sy==0), .flag_dst(line0_sys));

    // count lines for scaling via linebuffer
    logic [$clog2(FB_SCALE):0] cnt_lb_line;
    always_ff @(posedge clk_sys) begin
        if (line0_sys) cnt_lb_line <= 0;
        else if (line_sys) begin
            cnt_lb_line <= (cnt_lb_line == FB_SCALE-1) ? 0 : cnt_lb_line + 1;
        end
    end

    // which screen lines need linebuffer?
    logic lb_line;
    always_ff @(posedge clk_sys) begin
        if (line0_sys) lb_line <= 1;  // enable from sy==0
        if (frame_sys) lb_line <= 0;  // disable at frame start
    end

    // enable linebuffer input
    logic lb_en_in;
    logic [$clog2(FB_WIDTH)-1:0] cnt_lbx;  // horizontal pixel counter
    always_comb lb_en_in = (lb_line && cnt_lb_line == 0 && cnt_lbx < FB_WIDTH);

    // calculate framebuffer read address for linebuffer
    always_ff @(posedge clk_sys) begin
        if (line_sys) begin  // reset horizontal counter at start of line
            cnt_lbx <= 0;
        end else if (lb_en_in) begin  // increment address when LB enabled
            fb_addr_read <= fb_addr_read + 1;
            cnt_lbx <= cnt_lbx + 1;
        end
        if (frame_sys) fb_addr_read <= 0;  // reset address at frame start
    end

    // enable linebuffer output
    logic lb_en_out;
    localparam LAT_LB = 3;  // output latency compensation: lb_en_out+1, LB+1, CLUT+1
    always_ff @(posedge clk_pix) begin
        lb_en_out <= (sy >= 0 && sy < (FB_HEIGHT * FB_SCALE)
            && sx >= -LAT_LB && sx < (FB_WIDTH * FB_SCALE) - LAT_LB);
    end

    // display linebuffer
    logic [FB_DATAW-1:0] lb_colr_out;
    linebuffer_simple #(
        .DATAW(FB_DATAW),
        .LEN(FB_WIDTH)
    ) linebuffer_instance (
        .clk_sys,
        .clk_pix,
        .line,
        .line_sys,
        .en_in(lb_en_in),
        .en_out(lb_en_out),
        .scale(FB_SCALE),
        .data_in(fb_colr_read),
        .data_out(lb_colr_out)
    );

    // colour lookup table (CLUT)
    logic [COLRW-1:0] fb_pix_colr;
    clut_simple #(
        .COLRW(COLRW),
        .CIDXW(CIDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(0),
        .cidx_write(0),
        .cidx_read(lb_colr_out),
        .colr_in(0),
        .colr_out(fb_pix_colr)
    );

    // paint screen
    logic paint_area;  // area of screen to paint
    logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
    always_comb begin
        paint_area = (sy >= 0 && sy < (FB_HEIGHT * FB_SCALE)
            && sx >= 0 && sx < FB_WIDTH * FB_SCALE);
        {paint_r, paint_g, paint_b} = paint_area ? fb_pix_colr : BG_COLR;
    end

    // display colour: paint colour but black in blanking interval
    logic [CHANW-1:0] display_r, display_g, display_b;
    always_comb {display_r, display_g, display_b} = (de) ? {paint_r, paint_g, paint_b} : 0;

    // DVI signals (8 bits per colour channel)
    logic [2*CHANW-1:0] dvi_r, dvi_g, dvi_b;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de    <= de;
        dvi_r <= {2{display_r}};
        dvi_g <= {2{display_g}};
        dvi_b <= {2{display_b}};
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst_pix,
        .de(dvi_de),
        .data_in_ch0(dvi_b),
        .data_in_ch1(dvi_g),
        .data_in_ch2(dvi_r),
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
