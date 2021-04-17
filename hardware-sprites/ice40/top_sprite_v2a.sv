// Project F: Hardware Sprites - Top Sprite v2a (iCEBreaker with 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_sprite_v2a (
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
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // sprite
    localparam SPR_WIDTH   = 8;   // width in pixels
    localparam SPR_HEIGHT  = 8;   // number of lines
    localparam SPR_SCALE_X = 6;   // width scale-factor
    localparam SPR_SCALE_Y = 6;   // height scale-factor
    localparam SPR_FILE = "../res/simple/saucer.mem";
    logic spr_start;
    logic spr_pix;

    // draw sprite at position
    localparam H_RES = 640;
    localparam SPR_SPEED_X = 4;
    logic signed [CORDW-1:0] sprx, spry;
    logic dx;  // direction: 0 is right/down

    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (sprx >= H_RES - (SPR_SPEED_X + SPR_WIDTH * SPR_SCALE_X)) begin  // right edge
                dx <= 1;
                sprx <= sprx - SPR_SPEED_X;
            end else if (sprx < SPR_SPEED_X) begin  // left edge
                dx <= 0;
                sprx <= sprx + SPR_SPEED_X;
            end else sprx <= (dx) ? sprx - SPR_SPEED_X : sprx + SPR_SPEED_X;
        end
        if (!clk_locked) begin
            sprx <= 296;
            spry <= 216;
            dx <= 0;
        end
    end

    // signal to start sprite drawing
    always_comb spr_start = (line && sy == spry);

    sprite_v2 #(
        .WIDTH(SPR_WIDTH),
        .HEIGHT(SPR_HEIGHT),
        .SCALE_X(SPR_SCALE_X),
        .SCALE_Y(SPR_SCALE_Y),
        .SPR_FILE(SPR_FILE)
        ) spr_instance (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(spr_start),
        .sx,
        .sprx,
        .pix(spr_pix)
    );

    // colours
    logic [3:0] red, green, blue;
    always_comb begin
        red   = (de && spr_pix) ? 4'hF: 4'h0;
        green = (de && spr_pix) ? 4'hC: 4'h0;
        blue  = (de && spr_pix) ? 4'h0: 4'h0;
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
endmodule
