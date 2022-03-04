// Project F: Racing the Beam - Colour Cycle (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_colour_cycle (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button
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
    clock_480p clock_pix_inst (
       .clk_12m,
       .rst(btn_rst),
       .clk_pix,
       .clk_pix_locked
    );

    // display sync signals and coordinates
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(!clk_pix_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // screen dimensions (must match display_inst)
    localparam V_RES = 480;

    logic frame;  // high for one clock tick at the start of vertical blanking
    always_comb frame = (sy == V_RES && sx == 0);

    // update the colour level every N frames
    localparam FRAME_NUM = 30;  // frames between colour level change
    logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
    logic [3:0] colr_level;  // level of colour being cycled

    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (cnt_frame == FRAME_NUM-1) begin  // every FRAME_NUM frames
                cnt_frame <= 0;
                colr_level <= colr_level + 1;
            end else cnt_frame <= cnt_frame + 1;
        end
    end

    // determine colour from screen position
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = sx[7:4];  // 16 horizontal pixels of each red level
        paint_g = sy[7:4];  // 16 vertical pixels of each green level
        paint_b = colr_level;  // blue level changes over time
    end

    // DVI Pmod output
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync, vsync, de, paint_r, paint_g, paint_b}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // DVI Pmod clock output: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );
endmodule
