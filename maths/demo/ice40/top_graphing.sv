// Project F: Maths Demo - Graphing (iCEBreaker 12-bit DVI Pmod)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_graphing (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_12m,
       .rst(btn_rst),
       .clk_pix,
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 12;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
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

    logic [3:0] red, green, blue;
    always_comb begin
        red   = !de ? 4'h0 : (axes ? 4'hC : (draw ? 4'h3 : 4'h2));
        green = !de ? 4'h0 : (axes ? 4'hC : (draw ? 4'hB : 4'h2));
        blue  = !de ? 4'h0 : (axes ? 4'hC : (draw ? 4'hC : 4'h2));
    end

    // Output DVI clock: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // Output DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, red, green, blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );


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
