// Project F: Racing the Beam - Bounce (Nexys Video)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_bounce (
    input  wire logic clk_100m,         // 100 MHz clock
    input  wire logic btn_rst_n,        // reset button
    output      logic hdmi_tx_ch0_p,    // HDMI source channel 0 diff+
    output      logic hdmi_tx_ch0_n,    // HDMI source channel 0 diff-
    output      logic hdmi_tx_ch1_p,    // HDMI source channel 1 diff+
    output      logic hdmi_tx_ch1_n,    // HDMI source channel 1 diff-
    output      logic hdmi_tx_ch2_p,    // HDMI source channel 2 diff+
    output      logic hdmi_tx_ch2_n,    // HDMI source channel 2 diff-
    output      logic hdmi_tx_clk_p,    // HDMI source clock diff+
    output      logic hdmi_tx_clk_n     // HDMI source clock diff-
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_5x;
    logic clk_pix_locked;
    clock_720p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x,
       .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 12;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_720p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // screen dimensions (must match display_inst)
    localparam H_RES = 1280;  // horizontal screen resolution
    localparam V_RES =  720;  // vertical screen resolution

    logic frame;  // high for one clock tick at the start of vertical blanking
    always_comb frame = (sy == V_RES && sx == 0);

    // frame counter lets us to slow down the action
    localparam FRAME_NUM = 1;  // slow-mo: animate every N frames
    logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
    always_ff @(posedge clk_pix) begin
        if (frame) cnt_frame <= (cnt_frame == FRAME_NUM-1) ? 0 : cnt_frame + 1;
    end

    // square parameters
    localparam Q_SIZE = 200;   // size in pixels
    logic [CORDW-1:0] qx, qy;  // position (origin at top left)
    logic qdx, qdy;            // direction: 0 is right/down
    logic [CORDW-1:0] qs = 2;  // speed in pixels/frame

    // update square position once per frame
    always_ff @(posedge clk_pix) begin
        if (frame && cnt_frame == 0) begin
            // horizontal position
            if (qdx == 0) begin  // moving right
                if (qx + Q_SIZE + qs >= H_RES-1) begin  // hitting right of screen?
                    qx <= H_RES - Q_SIZE - 1;  // move right as far as we can
                    qdx <= 1;  // move left next frame
                end else qx <= qx + qs;  // continue moving right
            end else begin  // moving left
                if (qx < qs) begin  // hitting left of screen?
                    qx <= 0;  // move left as far as we can
                    qdx <= 0;  // move right next frame
                end else qx <= qx - qs;  // continue moving left
            end

            // vertical position
            if (qdy == 0) begin  // moving down
                if (qy + Q_SIZE + qs >= V_RES-1) begin  // hitting bottom of screen?
                    qy <= V_RES - Q_SIZE - 1;  // move down as far as we can
                    qdy <= 1;  // move up next frame
                end else qy <= qy + qs;  // continue moving down
            end else begin  // moving up
                if (qy < qs) begin  // hitting top of screen?
                    qy <= 0;  // move up as far as we can
                    qdy <= 0;  // move down next frame
                end else qy <= qy - qs;  // continue moving up
            end
        end
    end

    // define a square with screen coordinates
    logic square;
    always_comb begin
        square = (sx >= qx) && (sx < qx + Q_SIZE) && (sy >= qy) && (sy < qy + Q_SIZE);
    end

    // paint colour: white inside square, blue outside
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (square) ? 4'hF : 4'h1;
        paint_g = (square) ? 4'hF : 4'h3;
        paint_b = (square) ? 4'hF : 4'h7;
    end

    // display colour: paint screen but black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // DVI signals (8 bits per colour channel)
    logic [7:0] dvi_r, dvi_g, dvi_b;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de <= de;
        dvi_r <= {2{display_r}};
        dvi_g <= {2{display_g}};
        dvi_b <= {2{display_b}};
    end

    // TMDS encoding and serialization
    logic tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_clk_serial;
    dvi_generator dvi_out (
        .clk_pix,
        .clk_pix_5x,
        .rst_pix(!clk_pix_locked),
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
