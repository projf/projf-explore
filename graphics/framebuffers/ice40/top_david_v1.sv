// Project F: Framebuffers - Top David v1 (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_david_v1 (
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
    logic hsync, vsync;
    logic de, frame;
    logic signed [CORDW-1:0] sx, sy;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
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

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_write, fb_colr_read;

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
        .data_in(fb_colr_write),
        .data_out(fb_colr_read)
    );

    // draw box around framebuffer
    logic [$clog2(FB_WIDTH)-1:0] cnt_draw;
    enum {IDLE, TOP, RIGHT, BOTTOM, LEFT, DONE} state;
    always_ff @(posedge clk_pix) begin
        case (state)
            TOP:
                if (cnt_draw < FB_WIDTH-1) begin
                    fb_addr_write <= fb_addr_write + 1;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    cnt_draw <= 0;
                    state <= RIGHT;
                end
            RIGHT:
                if (cnt_draw < FB_HEIGHT-1) begin
                    fb_addr_write <= fb_addr_write + FB_WIDTH;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    fb_addr_write <= 0;
                    cnt_draw <= 0;
                    state <= LEFT;
                end
            LEFT:
                if (cnt_draw < FB_HEIGHT-1) begin
                    fb_addr_write <= fb_addr_write + FB_WIDTH;
                    cnt_draw <= cnt_draw + 1;
                end else begin
                    cnt_draw <= 0;
                    state <= BOTTOM;
                end
            BOTTOM:
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
                    cnt_draw <= 0;
                    state <= TOP;
                end
            default: state <= DONE;  // done forever!
        endcase
        if (!clk_locked) state <= IDLE;
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

    // reading from BRAM takes one cycle: delay display signals to match
    logic paint_p1, hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_pix) begin
        paint_p1 <= paint;
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

    logic [3:0] red, green, blue;  // output colour
    always_comb begin
        red   = (paint_p1 && fb_colr_read) ? 4'hF : 4'h0;
        green = (paint_p1 && fb_colr_read) ? 4'hF : 4'h0;
        blue  = (paint_p1 && fb_colr_read) ? 4'hF : 4'h0;
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
        .D_OUT_0({hsync_p1, vsync_p1, de_p1, red, green, blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
