// Project F: Framebuffers - Mono David (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_david_mono #(parameter CORDW=16) (  // signed coordinate width (bits)
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
    logic de, frame;
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
        /* verilator lint_off PINCONNECTEMPTY */
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;
    localparam FB_HEIGHT = 120;
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW  = $clog2(FB_PIXELS);
    localparam FB_DATAW  = 1;  // colour bits per pixel
    localparam FB_IMAGE  = "../res/david/david_1bit.mem";

    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .we(),
        .addr_write(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_read(fb_addr_read),
        /* verilator lint_off PINCONNECTEMPTY */
        .data_in(),
        /* verilator lint_on PINCONNECTEMPTY */
        .data_out(fb_colr_read)
    );

    logic read_fb;  // reading from BRAM takes one cycle: start reading one cycle early
    always_comb read_fb = (sy >= 0 && sy < FB_HEIGHT && sx >= -1 && sx < FB_WIDTH-1);

    // calculate framebuffer read address for display output
    always_ff @(posedge clk_pix) begin
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (read_fb) begin  // increment address in painting area
            fb_addr_read <= fb_addr_read + 1;
        end
    end

    // paint screen
    logic paint;  
    always_ff @(posedge clk_pix) paint <= read_fb;  // one cycle for memory read
    localparam CHANW = 4;  // colour channel width (bits)
    logic [CHANW-1:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (paint && fb_colr_read) ? 4'hF : 4'h0;
        paint_g = (paint && fb_colr_read) ? 4'hF : 4'h0;
        paint_b = (paint && fb_colr_read) ? 4'hF : 4'h0;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_frame <= frame;
        sdl_r <= {2{paint_r}};  // double signal width (assumes CHANW=4)
        sdl_g <= {2{paint_g}};
        sdl_b <= {2{paint_b}};
    end
endmodule
