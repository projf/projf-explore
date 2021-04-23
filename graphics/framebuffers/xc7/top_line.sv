// Project F: Framebuffers - Top Line (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_line (
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
    localparam FB_WIDTH  = 160;
    localparam FB_HEIGHT = 120;
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW  = $clog2(FB_PIXELS);
    localparam FB_DATAW  = 1;  // colour bits per pixel

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_write, fb_colr_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_colr_write),
        .data_out(fb_colr_read)
    );

    // draw line across middle of framebuffer
    logic [$clog2(FB_WIDTH)-1:0] cnt_draw;
    enum {IDLE, DRAW, DONE} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk_pix) begin
        case (state)
            DRAW:
                if (cnt_draw < FB_WIDTH-1) begin
                    fb_addr_write <= fb_addr_write + 1;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    fb_we <= 0;
                    state <= DONE;
                end
            IDLE:
                if (frame) begin
                    fb_colr_write <= 1;
                    fb_we <= 1;
                    fb_addr_write <= (FB_HEIGHT>>1) * FB_WIDTH;
                    cnt_draw <= 0;
                    state <= DRAW;
                end
            default: state <= DONE;  // done forever!
        endcase

        if (!clk_locked) state <= IDLE;
    end

    logic paint;  // which area of the framebuffer should we paint?
    always_comb paint = (sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx < FB_WIDTH);

    // calculate framebuffer read address for display output
    // we start at address zero, so calculation doesn't add latency
    always_ff @(posedge clk_pix) begin
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (paint) begin  // increment address in painting area
            fb_addr_read <= fb_addr_read + 1;
        end
    end

    // reading from BRAM takes one cycle: delay display signals to match
    logic paint_p1, hsync_p1, vsync_p1;
    always @(posedge clk_pix) begin
        paint_p1 <= paint;
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_p1;
        vga_vsync <= vsync_p1;
        vga_r <= (paint_p1 && fb_colr_read) ? 4'hF : 4'h0;
        vga_g <= (paint_p1 && fb_colr_read) ? 4'hF : 4'h0;
        vga_b <= (paint_p1 && fb_colr_read) ? 4'hF : 4'h0;
    end
endmodule
