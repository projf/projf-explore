// Project F: Hardware Sprites - Tiny F from ROM (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_tinyf_rom #(parameter CORDW=16) (  // coordinate width
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

    // sprite parameters
    localparam SPRX = 32;  // horizontal position
    localparam SPRY = 16;  // vertical position
    localparam SPR_FILE = "../res/sprites/letter_f.mem";

    // sprite
    logic pix, drawing;
    sprite_rom #(
        .CORDW(CORDW),
        .H_RES(H_RES),
        .SPR_FILE(SPR_FILE)
        ) sprite_f (
        .clk(clk_pix),
        .rst(rst_pix),
        .line,
        .sx,
        .sy,
        .sprx(SPRX),
        .spry(SPRY),
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
