// Project F: Hardware Sprites - Tiny F with Motion (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_tinyf_move #(parameter CORDW=16) (  // signed coordinate width (bits)
    input  wire logic clk_pix,      // pixel clock
    input  wire logic rst_pix,      // sim reset
    output      logic signed [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic signed [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,       // data enable (low in blanking interval)
    output      logic sdl_frame,    // high at start of frame
    output      logic [7:0] sdl_r,  // 8-bit red
    output      logic [7:0] sdl_g,  // 8-bit green
    output      logic [7:0] sdl_b   // 8-bit blue
    );

    // display sync signals and coordinates
    logic signed [CORDW-1:0] sx, sy;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de,
        .frame,
        .line
    );

    // screen dimensions (must match display_inst)
    localparam H_RES = 640;
    localparam V_RES = 480;

    // sprite parameters
    localparam SPR_WIDTH  = 8;  // bitmap width in pixels
    localparam SPR_HEIGHT = 8;  // bitmap height in pixels
    localparam SPR_SCALE  = 3;  // 2^3 = 8x scale
    localparam SPR_DATAW  = 1;  // bits per pixel
    localparam SPR_DRAWW  = SPR_WIDTH  * 2**SPR_SCALE;  // draw width
    localparam SPR_DRAWH  = SPR_HEIGHT * 2**SPR_SCALE;  // draw height
    localparam SPR_SPX    = 4;  // horizontal speed (pixels/frame)
    localparam SPR_FILE   = "../res/sprites/letter_f.mem";  // bitmap file

    logic signed [CORDW-1:0] sprx, spry;  // draw sprite at position (sprx,spry)
    logic dx;  // direction: 0 is right/down

    // update sprite position once per frame
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (dx == 0) begin  // moving right
                if (sprx + SPR_DRAWW >= H_RES + 2*SPR_DRAWW) dx <= 1;  // move left
                else sprx <= sprx + SPR_SPX;  // continue right
            end else begin  // moving left
                if (sprx <= -2*SPR_DRAWW) dx <= 0;  // move right
                else sprx <= sprx - SPR_SPX;  // continue left
            end
        end
        if (rst_pix) begin  // centre sprite and set direction right
            sprx <= H_RES/2 - SPR_DRAWW/2;
            spry <= V_RES/2 - SPR_DRAWH/2;
            dx <= 0;
        end
    end

    // sprite
    logic drawing;  // drawing at (sx,sy)
    logic [SPR_DATAW-1:0] pix;  // pixel colour index
    sprite #(
        .CORDW(CORDW),
        .H_RES(H_RES),
        .SPR_FILE(SPR_FILE),
        .SPR_WIDTH(SPR_WIDTH),
        .SPR_HEIGHT(SPR_HEIGHT),
        .SPR_SCALE(SPR_SCALE),
        .SPR_DATAW(SPR_DATAW)
        ) sprite_f (
        .clk(clk_pix),
        .rst(rst_pix),
        .line,
        .sx,
        .sy,
        .sprx,
        .spry,
        .pix,
        .drawing
    );

    // paint colours: yellow sprite, blue background
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (drawing && pix) ? 4'hF : 4'h1;
        paint_g = (drawing && pix) ? 4'hC : 4'h3;
        paint_b = (drawing && pix) ? 4'h0 : 4'h7;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_frame <= frame;
        sdl_r <= {2{paint_r}};  // double signal width from 4 to 8 bits
        sdl_g <= {2{paint_g}};
        sdl_b <= {2{paint_b}};
    end
endmodule
