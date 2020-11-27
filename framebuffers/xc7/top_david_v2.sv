// Project F: Framebuffers - Top David v2 (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_david_v2 (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        /* verilator lint_off PINCONNECTEMPTY */
        .de()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    // framebuffer
    localparam FB_WIDTH   = 160;
    localparam FB_HEIGHT  = 120;
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "david.mem";
    localparam FB_PALETTE = "david_palette.mem";

    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] colr_idx;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) framebuffer (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(0),
        /* verilator lint_off PINCONNECTEMPTY */
        .addr_write(),
        .addr_read(fb_addr_read),
        .data_in(),
        /* verilator lint_on PINCONNECTEMPTY */
        .data_out(colr_idx)
    );

    // flag when framebuffer is active
    logic fb_active;
    always_comb fb_active = (sy < FB_HEIGHT && sx < FB_WIDTH);

    always_ff @(posedge clk_pix) begin
        if (sy == V_RES_FULL-1 && sx == H_RES_FULL-1) begin
            fb_addr_read <= 0;  // reset address at end of frame
        end else if (fb_active) begin
            fb_addr_read <= fb_addr_read + 1;
        end
    end

    // Colour Lookup Table
    logic [11:0] clut [16];  // 16 x 12-bit colour palette entries
    initial begin
        $display("Loading palette '%s' into CLUT.", FB_PALETTE);
        $readmemh(FB_PALETTE, clut);  // load palette into CLUT
    end

    // map colour index to palette using CLUT
    logic [3:0] red, green, blue;   // pixel colour components
    always_comb begin
        {red, green, blue} = clut[colr_idx];
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_r <= fb_active ? red   : 4'h0;
        vga_g <= fb_active ? green : 4'h0;
        vga_b <= fb_active ? blue  : 4'h0;
    end
endmodule
