// Project F: 2D Shapes - Top Castle (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_castle (
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
    logic signed [CORDW-1:0] sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_720p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_pix_locked),
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        /* verilator lint_on PINCONNECTEMPTY */
        .sy,
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
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

    logic fb_we;  // write enable
    logic signed [CORDW-1:0] fbx, fby;  // draw coordinates
    logic [FB_CIDXW-1:0] fb_cidx;  // draw colour index
    logic fb_busy;  // when framebuffer is busy it cannot accept writes
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display output

    framebuffer_bram #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_100m),
        .clk_pix,
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de,
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .busy(fb_busy),
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw shapes in framebuffer
    localparam SHAPE_CNT=19;  // number of shapes to draw
    logic [$clog2(SHAPE_CNT)-1:0] shape_id;  // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic signed [CORDW-1:0] vr0;  // circle radius
    logic signed [CORDW-1:0] fbx_tri,    fby_tri;     // triangle framebuffer coords
    logic signed [CORDW-1:0] fbx_rect,   fby_rect;    // rectangle framebuffer coords
    logic signed [CORDW-1:0] fbx_circle, fby_circle;  // circle framebuffer coords
    logic drawing, draw_done;  // combined drawing signals
    logic draw_start_tri, drawing_tri, draw_done_tri;           // drawing triangle
    logic draw_start_rect, drawing_rect, draw_done_rect;        // drawing rectangle
    logic draw_start_circle, drawing_circle, draw_done_circle;  // drawing circle

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            INIT: begin  // register coordinates and colour
                state <= DRAW;
                case (shape_id)
                    5'd0: begin  // main building
                        draw_start_rect <= 1;
                        vx0 <= 120; vy0 <= 140;
                        vx1 <= 380; vy1 <= 240;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd1: begin  // drawbridge
                        draw_start_rect <= 1;
                        vx0 <= 220; vy0 <= 200;
                        vx1 <= 280; vy1 <= 240;
                        fb_cidx <= 4'h4;  // brown
                    end
                    5'd2: begin  // drawbridge arch
                        draw_start_circle <= 1;
                        vx0 <= 250; vy0 <= 200;
                        vr0 <=  30;
                        fb_cidx <= 4'h4;  // brown
                    end
                    5'd3: begin  // left tower
                        draw_start_rect <= 1;
                        vx0 <=  80; vy0 <=  90;
                        vx1 <= 120; vy1 <= 240;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd4: begin  // middle tower
                        draw_start_rect <= 1;
                        vx0 <= 220; vy0 <=  80;
                        vx1 <= 280; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd5: begin  // right tower
                        draw_start_rect <= 1;
                        vx0 <= 380; vy0 <=  90;
                        vx1 <= 420; vy1 <= 240;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd6: begin  // left roof
                        draw_start_tri <= 1;
                        vx0 <= 100; vy0 <=  60;
                        vx1 <= 130; vy1 <=  90;
                        vx2 <=  70; vy2 <=  90;
                        fb_cidx <= 4'h2;  // dark-purple
                    end
                    5'd7: begin  // middle roof
                        draw_start_tri <= 1;
                        vx0 <= 250; vy0 <=  40;
                        vx1 <= 290; vy1 <=  80;
                        vx2 <= 210; vy2 <=  80;
                        fb_cidx <= 4'h2;  // dark-purple
                    end
                    5'd8: begin  // right roof
                        draw_start_tri <= 1;
                        vx0 <= 400; vy0 <=  60;
                        vx1 <= 430; vy1 <=  90;
                        vx2 <= 370; vy2 <=  90;
                        fb_cidx <= 4'h2;  // dark-purple
                    end
                    5'd9: begin  // left window
                        draw_start_rect <= 1;
                        vx0 <=  92; vy0 <= 100;
                        vx1 <= 104; vy1 <= 130;
                        fb_cidx <= 4'h1;  // dark blue
                    end
                    5'd10: begin  // middle window
                        draw_start_rect <= 1;
                        vx0 <= 240; vy0 <=  90;
                        vx1 <= 260; vy1 <= 130;
                        fb_cidx <= 4'h1;  // dark blue
                    end
                    5'd11: begin  // right window
                        draw_start_rect <= 1;
                        vx0 <= 392; vy0 <= 100;
                        vx1 <= 408; vy1 <= 130;
                        fb_cidx <= 4'h1;  // dark blue
                    end
                    5'd12: begin  // battlement 1
                        draw_start_rect <= 1;
                        vx0 <= 126; vy0 <= 124;
                        vx1 <= 144; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd13: begin  // battlement 2
                        draw_start_rect <= 1;
                        vx0 <=  160; vy0 <= 124;
                        vx1 <=  178; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd14: begin  // battlement 3
                        draw_start_rect <= 1;
                        vx0 <= 194; vy0 <= 124;
                        vx1 <= 212; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd15: begin  // battlement 4
                        draw_start_rect <= 1;
                        vx0 <= 288; vy0 <= 124;
                        vx1 <= 306; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd16: begin  // battlement 5
                        draw_start_rect <= 1;
                        vx0 <= 322; vy0 <= 124;
                        vx1 <= 340; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd17: begin  // battlement 6
                        draw_start_rect <= 1;
                        vx0 <= 356; vy0 <= 124;
                        vx1 <= 374; vy1 <= 140;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd18: begin  // Sun
                        draw_start_circle <= 1;
                        vx0 <= 550; vy0 <=  76;
                        vr0 <= 40;
                        fb_cidx <= 4'h9;  // orange
                    end
                    default: begin  // should never occur
                        draw_start_tri <= 1;
                        vx0 <=   20; vy0 <=   20;
                        vx1 <=   20; vy1 <=   60;
                        vx2 <=   40; vy2 <=   40;
                        fb_cidx <= 4'h7;  // white
                    end
                endcase
            end
            DRAW: begin
                draw_start_tri    <= 0;
                draw_start_rect   <= 0;
                draw_start_circle <= 0;
                if (draw_done) begin
                    if (shape_id == SHAPE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        shape_id <= shape_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: state <= DONE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    // drawing and done apply to all drawing types
    always_comb begin
        drawing   = drawing_tri   || drawing_rect   || drawing_circle;
        draw_done = draw_done_tri || draw_done_rect || draw_done_circle;
    end

    // control drawing speed with output enable
    localparam FRAME_WAIT = 300;  // wait this many frames to start drawing
    localparam PIX_FRAME  =  80;  // draw this many pixels per frame
    logic [$clog2(FRAME_WAIT)-1:0] cnt_frame_wait;
    logic [$clog2(PIX_FRAME)-1:0] cnt_pix_frame;
    logic draw_req;
    always_ff @(posedge clk_100m) begin
        draw_req <= 0;
        if (frame_sys) begin
            if (cnt_frame_wait != FRAME_WAIT-1) cnt_frame_wait <= cnt_frame_wait + 1;
            cnt_pix_frame <= 0;  // reset pixel counter every frame
        end
        if (!fb_busy) begin
            if (cnt_frame_wait == FRAME_WAIT-1 && cnt_pix_frame != PIX_FRAME-1) begin
                draw_req <= 1;
                cnt_pix_frame <= cnt_pix_frame + 1;
            end
        end
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start_tri),
        .oe(draw_req && !fb_busy),  // draw if requested when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x2(vx2),
        .y2(vy2),
        .x(fbx_tri),
        .y(fby_tri),
        .drawing(drawing_tri),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_tri)
    );

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start_rect),
        .oe(draw_req && !fb_busy),  // draw if requested when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x(fbx_rect),
        .y(fby_rect),
        .drawing(drawing_rect),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_rect)
    );

    draw_circle_fill #(.CORDW(CORDW)) draw_circle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start_circle),
        .oe(draw_req && !fb_busy),  // draw if requested when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .r0(vr0),
        .x(fbx_circle),
        .y(fby_circle),
        .drawing(drawing_circle),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_circle)
    );

    // write to framebuffer when drawing
    always_ff @(posedge clk_100m) begin
        fb_we <= drawing;
        fbx <= drawing_tri ? fbx_tri : (drawing_rect ? fbx_rect : fbx_circle);
        fby <= drawing_tri ? fby_tri : (drawing_rect ? fby_rect : fby_circle);
    end

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

    // background colour (720p coordinates)
    logic [11:0] bg_colr;
    always_ff @(posedge clk_pix) begin
        if (line) begin
            if (sy ==  0) bg_colr <= 12'h239;
            else if (sy == 140) bg_colr <= 12'h24A;
            else if (sy == 230) bg_colr <= 12'h25B;
            else if (sy == 300) bg_colr <= 12'h26C;
            else if (sy == 360) bg_colr <= 12'h27D;
            else if (sy == 410) bg_colr <= 12'h29E;
            else if (sy == 450) bg_colr <= 12'h2BF;
            else if (sy == 482) bg_colr <= 12'h260;  // below castle (2x pix)
        end
    end

    logic show_bg;
    always_comb show_bg = (de && {fb_red,fb_green,fb_blue} == 0);

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync_p1;
        dvi_vsync <= vsync_p1;
        dvi_de    <= de_p1;
        dvi_red   <= show_bg ? {2{bg_colr[11:8]}} : {2{fb_red}};
        dvi_green <= show_bg ? {2{bg_colr[7:4]}}  : {2{fb_green}};
        dvi_blue  <= show_bg ? {2{bg_colr[3:0]}}  : {2{fb_blue}};
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
