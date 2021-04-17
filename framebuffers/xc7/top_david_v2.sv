// Project F: Framebuffers - Top David v2 (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
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
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic hsync, vsync;
    logic frame;
    logic signed [CORDW-1:0] sx, sy;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        /* verilator lint_off PINCONNECTEMPTY */
        .de(),
        .frame,
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // framebuffer (FB)
    localparam FB_WIDTH   = 160;
    localparam FB_HEIGHT  = 120;
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "david.mem";
    localparam FB_PALETTE = "david_palette.mem";

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_cidx_write, fb_cidx_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb_cidx_read)
    );

    // fizzlefade!
    logic lfsr_en;
    logic [14:0] lfsr;
    lfsr #(  // 15-bit LFSR (160x120 < 2^15)
        .LEN(15),
        .TAPS(15'b110000000000000)
    ) lsfr_fz (
        .clk(clk_pix),
        .rst(!clk_locked),
        .en(lfsr_en),
        .sreg(lfsr)
    );

    localparam FADE_WAIT = 600;   // wait for 600 frames before fading
    localparam FADE_RATE = 3200;  // every 3200 pixel clocks update LFSR
    logic [$clog2(FADE_WAIT)-1:0] cnt_wait;
    logic [$clog2(FADE_RATE)-1:0] cnt_rate;
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            cnt_wait <= (cnt_wait != FADE_WAIT-1) ? cnt_wait + 1 : cnt_wait;
        end
        if (cnt_wait == FADE_WAIT-1) begin
            if (cnt_rate == FADE_RATE-1) begin
                lfsr_en <= 1;
                fb_we <= 1;
                fb_addr_write <= lfsr;
                cnt_rate <= 0;
            end else begin
                cnt_rate <= cnt_rate + 1;
                lfsr_en <= 0;
                fb_we <= 0;
            end
        end
        fb_cidx_write <= 4'hF;  // palette index
    end

    logic paint;  // which area of the framebuffer should we paint?
    always_comb paint = (sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx < FB_WIDTH);

    // calculate framebuffer read address for display output
    always_ff @(posedge clk_pix) begin
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (paint) begin  // increment address in painting area
            fb_addr_read <= fb_addr_read + 1;
        end
    end

    // add register between BRAM and CLUT (async ROM)
    logic [FB_DATAW-1:0] fb_cidx_read_p1;
    always @(posedge clk_pix) fb_cidx_read_p1 <= fb_cidx_read;

    // colour lookup table (ROM) 16x12-bit entries
    logic [11:0] clut_colr;
    rom_async #(
        .WIDTH(12),
        .DEPTH(16),
        .INIT_F(FB_PALETTE)
    ) clut (
        .addr(fb_cidx_read_p1),
        .data(clut_colr)
    );

    // BRAM read and CLUT reg add two cycles of latency
    localparam LAT = 2;  // display latency
    logic [LAT-1:0] paint_sr, hsync_sr, vsync_sr;
    always @(posedge clk_pix) begin
        paint_sr <= {paint, paint_sr[LAT-1:1]};
        hsync_sr <= {hsync, hsync_sr[LAT-1:1]};
        vsync_sr <= {vsync, vsync_sr[LAT-1:1]};
    end

    logic [3:0] red, green, blue;  // map colour index to palette using CLUT
    always_comb {red, green, blue} = paint_sr[0] ? clut_colr : 12'h0;

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_sr[0];
        vga_vsync <= vsync_sr[0];
        vga_r <= red;
        vga_g <= green;
        vga_b <= blue;
    end
endmodule
