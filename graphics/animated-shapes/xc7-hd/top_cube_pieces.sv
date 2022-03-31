// Project F: Animated Shapes - Top Cube Pieces (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_cube_pieces (
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
        .rst_pix(!clk_pix_locked),
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
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

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
        .bgidx(4'h0),
        .clear(1'b1),  // enable clearing of buffer before drawing
        .busy(fb_busy),
        .wready(fb_wready),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // animate triangle coordinates
    localparam MAX_OFFS   = 32;  // maximum pixels to move
    localparam ANIM_SPEED =  1;  // pixel to move per frame
    localparam FRAME_WAIT = 60;  // frames to pause between change of direction
    logic [CORDW-1:0] offs;      // animation offset
    logic [$clog2(FRAME_WAIT)-1:0] cnt_frame_wait;
    logic dir;  // direction: 1 is increasing offset
    enum {START, MOVE, WAIT} anim_state;
    always_ff @(posedge clk_100m) begin
        if (frame_sys) begin
            case (anim_state)
                MOVE: begin
                    offs <= (dir == 1) ? offs + ANIM_SPEED : offs - ANIM_SPEED;
                    if ((dir == 1 && offs >= MAX_OFFS-ANIM_SPEED) ||
                        (dir == 0 && offs <= ANIM_SPEED)) begin
                        cnt_frame_wait <= 0;
                        anim_state <= WAIT;
                    end
                end
                WAIT: begin
                    if (cnt_frame_wait == FRAME_WAIT-1) begin
                        anim_state <= MOVE;
                        dir <= ~dir;  // change direction
                    end else cnt_frame_wait <= cnt_frame_wait + 1;
                end
                default: anim_state <= WAIT;  // START
            endcase
        end
    end

    // draw triangles in framebuffer
    localparam SHAPE_CNT=6;  // number of shapes to draw
    logic [2:0] shape_id;    // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            INIT: begin  // register coordinates and colour
                if (fb_wready) begin
                    draw_start <= 1;
                    state <= DRAW;
                    case (shape_id)
                        3'd0: begin  // moves in from right
                            vx0 <= 260 + offs; vy0 <= 120;
                            vx1 <= 460 + offs; vy1 <= 120;
                            vx2 <= 460 + offs; vy2 <= 320;
                            fb_cidx <= (offs == 0) ? 4'h9 : 4'hA;  // orange or yellow
                        end
                        3'd1: begin  // moves in from bottom-right
                            vx0 <= 260 + offs; vy0 <= 120 + offs;
                            vx1 <= 460 + offs; vy1 <= 320 + offs;
                            vx2 <= 260 + offs; vy2 <= 320 + offs;
                            fb_cidx <= (offs == 0) ? 4'h9 : 4'hA;  // orange or yellow
                        end
                        3'd2: begin  // moves in from bottom-left
                            vx0 <= 260 - offs; vy0 <= 120 + offs;
                            vx1 <= 180 - offs; vy1 <= 240 + offs;
                            vx2 <= 260 - offs; vy2 <= 320 + offs;
                            fb_cidx <= (offs == 0) ? 4'h2 : 4'hD;  // dark purple or indigo
                        end
                        3'd3: begin  // moves in from left
                            vx0 <= 180 - offs; vy0 <=  40;
                            vx1 <= 260 - offs; vy1 <= 120;
                            vx2 <= 180 - offs; vy2 <= 240;
                            fb_cidx <= (offs == 0) ? 4'h2 : 4'hD;  // dark purple or indigo
                        end
                        3'd4: begin  // moves in from top
                            vx0 <= 180; vy0 <=  40 - offs;
                            vx1 <= 380; vy1 <=  40 - offs;
                            vx2 <= 260; vy2 <= 120 - offs;
                            fb_cidx <= (offs == 0) ? 4'h1 : 4'hC;  // dark blue or blue
                        end
                        3'd5: begin  // moves in from top-right
                            vx0 <= 380 + offs; vy0 <=  40 - offs;
                            vx1 <= 260 + offs; vy1 <= 120 - offs;
                            vx2 <= 460 + offs; vy2 <= 120 - offs;
                            fb_cidx <= (offs == 0) ? 4'h1 : 4'hC;  // dark blue or blue
                        end
                        default: begin  // should never occur
                            vx0 <=   20; vy0 <=   20;
                            vx1 <=   20; vy1 <=   60;
                            vx2 <=   40; vy2 <=   40;
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
            DONE: state <= IDLE;  // idle ready for the next frame
            default: if (frame_sys) begin  // IDLE
                shape_id <= 0;
                state <= INIT;
            end
        endcase
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!fb_busy),  // draw when framebuffer isn't busy
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x2(vx2),
        .y2(vy2),
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
        .rst_pix(!clk_pix_locked),
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
