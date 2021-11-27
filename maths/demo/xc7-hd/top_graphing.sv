// Project F: Maths Demo - Graphing (Nexys Video)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_graphing (
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
    localparam CORDW = 12;
    logic hsync, vsync;
    logic [CORDW-1:0] sx, sy;
    logic de;
    display_720p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_pix_locked),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        /* verilator lint_off PINCONNECTEMPTY */
        .frame(),
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // signal when to draw mathematical function and axis
    logic draw, axes;

    // DVI signals
    logic [7:0] dvi_red, dvi_green, dvi_blue;
    logic dvi_hsync, dvi_vsync, dvi_de;
    always_ff @(posedge clk_pix) begin
        dvi_hsync <= hsync;
        dvi_vsync <= vsync;
        dvi_de    <= de;
        dvi_red   <= !de ? 8'h0 : (axes ? 8'hCC : (draw ? 8'h33 : 8'h22));
        dvi_green <= !de ? 8'h0 : (axes ? 8'hCC : (draw ? 8'hBB : 8'h22));
        dvi_blue  <= !de ? 8'h0 : (axes ? 8'hCC : (draw ? 8'hCC : 8'h22));
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


    //
    // Graphing Logic
    //

    // function coordinates
    logic signed [CORDW-1:0] x, y;

    // adjust screen coordinates so (0,0) is at centre of screen
    localparam X_OFFS = 640;
    localparam Y_OFFS = 359;
    always_ff @(posedge clk_pix) begin
        x <= sx - X_OFFS + 4;  // latency for function (+n) and offset calculation (+1)
        y <= Y_OFFS - sy;
    end

    // draw X and Y axes
    logic x_axis, y_axis;
    always_comb begin
        x_axis = (sy == Y_OFFS);
        y_axis = (sx == X_OFFS);
        axes = x_axis || y_axis;
    end

    // function to graph
    func_squared #(.CORDW(CORDW)) func_inst (
        .clk(clk_pix),
        .x,
        .y,
        .r(draw)
    );
endmodule
