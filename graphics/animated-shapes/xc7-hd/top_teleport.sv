// Project F: Animated Shapes - Top Teleport (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_teleport (
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
    logic hsync, vsync;
    logic de, frame, line;
    display_720p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_pix_locked),
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        .sy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m),
                 .rst_i(1'b0), .rst_o(1'b0), .i(frame), .o(frame_sys));

    // framebuffer (FB)
    localparam FB_WIDTH   = 640;
    localparam FB_HEIGHT  = 360;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 2;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "teleport_16_colr_4bit_palette.mem";

    logic fb_we, fb_busy, fb_wready;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    framebuffer_bram_db #(
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
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de,
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        .bgidx(4'h0),
        .clear(1'b0),  // teleport doesn't need clearing
        .busy(fb_busy),
        .wready(fb_wready),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // animation steps
    localparam ANIM_CNT=5;    // five different frames in animation
    localparam ANIM_SPEED=4;  // display each animation step four times (15 FPS)
    logic [$clog2(ANIM_CNT)-1:0] cnt_anim;
    logic [$clog2(ANIM_SPEED)-1:0] cnt_anim_speed;
    logic [FB_CIDXW-1:0] colr_offs;  // colour offset
    always_ff @(posedge clk_100m) begin
        if (frame_sys) begin
            /* verilator lint_off WIDTH */
            if (cnt_anim_speed == ANIM_SPEED-1) begin
                if (cnt_anim == ANIM_CNT-1) begin
            /* verilator lint_on WIDTH */
                    cnt_anim <= 0;
                    colr_offs <= colr_offs + 1;
                end else cnt_anim <= cnt_anim + 1;
                cnt_anim_speed <= 0;
            end else cnt_anim_speed <= cnt_anim_speed + 1;
        end
    end

    // draw squares in framebuffer
    localparam SHAPE_CNT=7;  // number of shapes to draw
    logic [3:0] shape_id;    // shape identifier
    logic [CORDW-1:0] dx0, dy0, dx1, dy1;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, CLEAR, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            INIT: begin  // register coordinates and colour
                if (fb_wready) begin
                    draw_start <= 1;
                    state <= DRAW;
                    case (shape_id)
                        4'd0: begin  // 24 pixels per anim step
                            dx0 <=  80 - (cnt_anim * 24);
                            dy0 <=   0 - (cnt_anim * 24);
                            dx1 <= 558 + (cnt_anim * 24);
                            dy1 <= 498 + (cnt_anim * 24);
                            fb_cidx <= colr_offs;
                        end
                        4'd1: begin  // 16 pixels per anim step
                            dx0 <= 160 - (cnt_anim * 16);
                            dy0 <=  20 - (cnt_anim * 16);
                            dx1 <= 478 + (cnt_anim * 16);
                            dy1 <= 338 + (cnt_anim * 16);
                            fb_cidx <= colr_offs + 1;
                        end
                        4'd2: begin  // 10 pixels per anim step
                            dx0 <= 210 - (cnt_anim * 10);
                            dy0 <=  70 - (cnt_anim * 10);
                            dx1 <= 428 + (cnt_anim * 10);
                            dy1 <= 288 + (cnt_anim * 10);
                            fb_cidx <= colr_offs + 2;
                        end
                        4'd3: begin  // 8 pixels per anim step
                            dx0 <= 250 - (cnt_anim * 8);
                            dy0 <= 110 - (cnt_anim * 8);
                            dx1 <= 388 + (cnt_anim * 8);
                            dy1 <= 248 + (cnt_anim * 8);
                            fb_cidx <= colr_offs + 3;
                        end
                        4'd4: begin  // 6 pixels per anim step
                            dx0 <= 280 - (cnt_anim * 6);
                            dy0 <= 140 - (cnt_anim * 6);
                            dx1 <= 358 + (cnt_anim * 6);
                            dy1 <= 218 + (cnt_anim * 6);
                            fb_cidx <= colr_offs + 4;
                        end
                        4'd5: begin  // 4 pixels per anim step
                            dx0 <= 300 - (cnt_anim * 4);
                            dy0 <= 160 - (cnt_anim * 4);
                            dx1 <= 338 + (cnt_anim * 4);
                            dy1 <= 198 + (cnt_anim * 4);
                            fb_cidx <= colr_offs + 5;
                        end
                        4'd6: begin  // 2 pixel per anim step
                            dx0 <= 310 - (cnt_anim * 2);
                            dy0 <= 170 - (cnt_anim * 2);
                            dx1 <= 328 + (cnt_anim * 2);
                            dy1 <= 188 + (cnt_anim * 2);
                            fb_cidx <= colr_offs + 6;
                        end
                        default: begin  // should never occur
                            dx0 <=  20; dy0 <=  20;
                            dx1 <=  40; dy1 <=  40;
                            fb_cidx <= 4'h7;  // white
                        end
                    endcase
                end
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) begin
                    if (shape_id == SHAPE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        shape_id <= shape_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: state <= IDLE;
            default: if (frame_sys) begin  // IDLE
                state <= INIT;
                shape_id <= 0;
            end
        endcase
    end

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!fb_busy),  // draw when framebuffer isn't busy
        .x0(dx0),
        .y0(dy0),
        .x1(dx1),
        .y1(dy1),
        .x(fbx),
        .y(fby),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    // write to framebuffer when drawing
    always_comb fb_we = drawing;

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_pix) begin
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
        dvi_red   <= {2{fb_red}};
        dvi_green <= {2{fb_green}};
        dvi_blue  <= {2{fb_blue}};
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
