// Project F: Lines and Triangles - Top Triangles (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_triangles (
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

    // display timings
    localparam H_RES = 1280;
    localparam V_RES = 720;
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_720p display_timings_inst (
        .clk_pix,
        .rst(!clk_pix_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m), .i(frame), .o(frame_sys));

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 240;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 3;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

    logic fb_we;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    framebuffer #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_100m),
        .clk_pix(clk_pix),
        .de(sy >= 0 && sx >= 160 && sx < 1120),  // 4:3
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw triangles in framebuffer
    localparam SHAPE_CNT=3;  // number of shapes to draw
    logic [1:0] shape_id;  // shape identifier
    logic signed [CORDW-1:0] tx0, ty0, tx1, ty1, tx2, ty2;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk_100m) begin
        draw_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                case (shape_id)
                    2'd0: begin
                        tx0 <=  20; ty0 <=  60;
                        tx1 <=  60; ty1 <= 180;
                        tx2 <= 110; ty2 <=  90;
                        fb_cidx <= 4'h2;  // dark purple
                    end
                    2'd1: begin
                        tx0 <=  70; ty0 <= 200;
                        tx1 <= 240; ty1 <= 100;
                        tx2 <= 170; ty2 <=  10;
                        fb_cidx <= 4'hC;  // blue
                    end
                    2'd2: begin
                        tx0 <=  60; ty0 <=  30;
                        tx1 <= 300; ty1 <=  80;
                        tx2 <= 160; ty2 <= 220;
                        fb_cidx <= 4'h9;  // orange
                    end
                    default: begin  // should never occur
                        tx0 <=   10; ty0 <=   10;
                        tx1 <=   10; ty1 <=   30;
                        tx2 <=   20; ty2 <=   20;
                        fb_cidx <= 4'h7;  // white
                    end
                endcase
            end
            DRAW: if (draw_done) begin
                if (shape_id == SHAPE_CNT-1) begin
                    state <= DONE;
                end else begin
                    shape_id <= shape_id + 1;
                    state <= INIT;
                end
            end
            DONE: state <= DONE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    // control drawing output enable - wait 300 frames, then 1 pixel/frame
    localparam DRAW_WAIT = 300;
    logic [$clog2(DRAW_WAIT)-1:0] cnt_draw_wait;
    logic draw_oe;
    always_ff @(posedge clk_100m) begin
        draw_oe <= 0;
        if (frame_sys) begin
            if (cnt_draw_wait != DRAW_WAIT-1) begin
                cnt_draw_wait <= cnt_draw_wait + 1;
            end else draw_oe <= 1;
        end
    end

    draw_triangle #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(draw_oe),
        .x0(tx0),
        .y0(ty0),
        .x1(tx1),
        .y1(ty1),
        .x2(tx2),
        .y2(ty2),
        .x(fbx),
        .y(fby),
        .drawing,
        .done(draw_done)
    );

    // write to framebuffer when drawing
    always_comb fb_we = drawing;

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync_p1;
        dvi_vsync <= vsync_p1;
        dvi_de    <= de_p1;
        dvi_red   <= {fb_red,fb_red};
        dvi_green <= {fb_green,fb_green};
        dvi_blue  <= {fb_blue,fb_blue};
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
