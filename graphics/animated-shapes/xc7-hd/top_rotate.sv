// Project F: Animated Shapes - Top Rotate Demo (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_rotate (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst,          // reset button (active low)
    input  wire logic btn_inc,          // increase button (BTNR)
    input  wire logic btn_dec,          // decrease button (BTNL)
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

    // debounce buttons
    logic sig_inc, sig_dec;
    /* verilator lint_off PINCONNECTEMPTY */
    debounce deb_inc
        (.clk(clk_100m), .in(btn_inc), .out(), .ondn(), .onup(sig_inc));
    debounce deb_dec
        (.clk(clk_100m), .in(btn_dec), .out(), .ondn(), .onup(sig_dec));
    /* verilator lint_on PINCONNECTEMPTY */

    // framebuffer (FB)
    localparam FB_WIDTH   = 640;
    localparam FB_HEIGHT  = 360;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 2;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";
    localparam FB_BGIDX   = 4'h1;  // background colour index

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
        .bgidx(FB_BGIDX),
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

    // shape rotation
    localparam ANGLEW=8;  // angle width in bits
    logic [ANGLEW-1:0] angle;
    logic [CORDW-1:0] rot_xi, rot_yi;
    logic [CORDW-1:0] rot_x, rot_y;
    logic rot_start, rot_done;

    // set angle using buttons
    always_ff @(posedge clk_100m) begin
        if (sig_inc) angle <= angle + 2;
        if (sig_dec) angle <= angle - 2;
    end

    rotate_xy #(.CORDW(CORDW), .ANGLEW(ANGLEW)) rotate_xy_inst (
        .clk(clk_100m),     // clock
        .rst(1'b0),         // reset
        .start(rot_start),  // start rotation
        .angle,             // rotation angle
        .xi(rot_xi),        // x coord in
        .yi(rot_yi),        // y coord in
        .x(rot_x),          // rotated x coord
        .y(rot_y),          // rotated y coord
        .done(rot_done)     // rotation complete (high for one tick)
    );

    // draw triangles in framebuffer
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic signed [CORDW-1:0] offs_x, offs_y;  // offset (translate position)
    logic signed [CORDW-1:0] fbx_fill, fby_fill;  // fill coordinates
    logic signed [CORDW-1:0] fbx_outline, fby_outline;  // outline coordinates
    logic drawing;  // common drawing signal
    logic draw_start_fill, drawing_fill, draw_done_fill;  // drawing filled shape
    logic draw_start_outline, drawing_outline, draw_done_outline;  // drawing outline

    // draw state machine
    enum {IDLE, INIT, ROT_INIT, ROT_0, ROT_1, ROT_2, FILL, OUTLINE, DONE} state;
    always_ff @(posedge clk_100m) begin
        rot_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                if (fb_wready) begin
                    state <= ROT_INIT;
                    vx0 <=   0; vy0 <= -80;
                    vx1 <= -60; vy1 <=  40;
                    vx2 <=  90; vy2 <= 140;
                    offs_x <= 320; offs_y <= 180;
                    fb_cidx <= 4'h9;  // orange
                end
            end
            ROT_INIT: begin
                // rotation coords (tx0,ty0)
                rot_xi <= vx0;
                rot_yi <= vy0;
                rot_start <= 1;
                state <= ROT_0;
            end
            ROT_0: if (rot_done) begin
                // save rotated (tx0,ty0) with translate
                vx0 <= rot_x + offs_x;
                vy0 <= rot_y + offs_y;
                // rotation coords (tx1,ty1)
                rot_xi <= vx1;
                rot_yi <= vy1;
                rot_start <= 1;
                state <= ROT_1;
            end
            ROT_1: if (rot_done) begin
                // save rotated (tx1,ty1) with translate
                vx1 <= rot_x + offs_x;
                vy1 <= rot_y + offs_y;
                // rotation coords (tx2,ty2)
                rot_xi <= vx2;
                rot_yi <= vy2;
                rot_start <= 1;
                state <= ROT_2;
            end
            ROT_2: if (rot_done) begin
                // save rotated (tx2,ty2) with translate
                vx2 <= rot_x + offs_x;
                vy2 <= rot_y + offs_y;
                draw_start_fill <= 1;
                state <= FILL;
            end
            FILL: begin
                draw_start_fill <= 0;
                if (draw_done_fill) begin
                    state <= OUTLINE;
                    draw_start_outline <= 1;
                    fb_cidx <= 4'h8;  // red
                end
            end
            OUTLINE: begin
                draw_start_outline <= 0;
                if (draw_done_outline) state <= DONE;
            end
            DONE: state <= IDLE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    // drawing applies to all drawing types
    always_comb drawing = drawing_fill || drawing_outline;

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_fill_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start_fill),
        .oe(!fb_busy),  // draw when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x2(vx2),
        .y2(vy2),
        .x(fbx_fill),
        .y(fby_fill),
        .drawing(drawing_fill),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_fill)
    );

    draw_triangle#(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start_outline),
        .oe(!fb_busy),  // draw when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x2(vx2),
        .y2(vy2),
        .x(fbx_outline),
        .y(fby_outline),
        .drawing(drawing_outline),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_outline)
    );

    // write to framebuffer when drawing
    always_ff @(posedge clk_100m) begin
        fb_we <= drawing;
        fbx <= drawing_fill ? fbx_fill : fbx_outline;
        fby <= drawing_fill ? fby_fill : fby_outline;
    end

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
