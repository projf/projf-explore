// Project F: Framebuffers - Top David Fizzle (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_david_fizzle (
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
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .de
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

    // fizzlebuffer
    logic [FB_ADDRW-1:0] fz_addr_write;
    logic fz_en_in, fz_en_out;
    logic fz_we;

    bram_sdp #(
        .WIDTH(1),
        .DEPTH(FB_PIXELS),
        .INIT_F("")
    ) fizzelbuffer (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(fz_we),
        .addr_write(fz_addr_write),
        .addr_read(fb_addr_read),  // share read address with framebuffer
        .data_in(fz_en_in),
        .data_out(fz_en_out)
    );

    // 15-bit LFSR (160x120 < 2^15)
    logic lfsr_en;
    logic [14:0] lfsr;
    lfsr #(
        .LEN(15),
        .TAPS(15'b110000000000000)
    ) lsfr_fz (
        .clk(clk_pix),
        .rst(!clk_locked),
        .en(lfsr_en),
        .sreg(lfsr)
    );

    localparam FADE_WAIT = 240;   // wait for 240 frames before fading
    localparam FADE_RATE = 3000;  // every 3000th pixel clock update LFSR
    logic [$clog2(FADE_WAIT)-1:0] cnt_fade_wait;
    logic [$clog2(FADE_RATE)-1:0] cnt_fade_rate;
    always_ff @(posedge clk_pix) begin
        if (sy == V_RES && sx == H_RES) begin  // start of blanking
            cnt_fade_wait <= (cnt_fade_wait != FADE_WAIT-1) ? cnt_fade_wait + 1 : cnt_fade_wait;
        end
        if (cnt_fade_wait == FADE_WAIT-1) begin
            cnt_fade_rate <= (cnt_fade_rate == FADE_RATE) ? 0 : cnt_fade_rate + 1;
        end
    end

    always_comb begin
        fz_addr_write = lfsr;
        if (cnt_fade_rate == FADE_RATE) begin
            lfsr_en = 1;
            fz_we = 1;
            fz_en_in = 1;
        end else begin
            lfsr_en = 0;
            fz_we = 0;
            fz_en_in = 0;
        end
    end

    // linebuffer
    localparam LB_SCALE_V = 4;                // factor to scale vertical drawing
    localparam LB_SCALE_H = 4;                // factor to scale horizontal drawing
    localparam LB_LINE  = 640 / LB_SCALE_H;   // line length
    localparam LB_ADDRW = $clog2(LB_LINE);    // line address width
    localparam LB_WIDTH = 4;                  // bits per colour channel

    // linebuffer read port
    logic [LB_ADDRW-1:0] lb_addr_read;
    logic [LB_WIDTH-1:0] lb0_out, lb1_out, lb2_out;

    // linebuffer write port (latency corrected for reading from FB)
    logic lb_we, lb_we_l1;
    logic [LB_ADDRW-1:0] lb_addr_write, lb_addr_write_l1;
    logic [LB_WIDTH-1:0] lb0_in, lb1_in, lb2_in;

    // latency correction for reading framebuffer BRAM (1 cycle)
    always_ff @(posedge clk_pix) begin
        lb_we_l1 <= lb_we;
        lb_addr_write_l1 <= lb_addr_write;
    end

    linebuffer #(
        .WIDTH(LB_WIDTH),
        .DEPTH(LB_LINE)
        ) lb (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(lb_we_l1),                  // corrects for BRAM latency
        .addr_write(lb_addr_write_l1),  // corrects for BRAM latency
        .addr_read(lb_addr_read),
        .data_in_0(lb0_in),
        .data_in_1(lb1_in),
        .data_in_2(lb2_in),
        .data_out_0(lb0_out),
        .data_out_1(lb1_out),
        .data_out_2(lb2_out)
    );

    // linebuffer state machine for reading framebuffer
    logic [$clog2(FB_HEIGHT)-1:0]  fb_line_cnt;  // count of framebuffer lines
    logic [$clog2(LB_SCALE_V)-1:0] lb_line_rpt;  // repeat line based on scale

    enum {
        IDLE,       // awaiting start signal
        START,      // prepare for new frame
        AWAIT_POS,  // await horizontal position
        START_LINE, // begin a new line
        READ_FB,    // read fb into lb
        IDLE_LINE,  // do nothing on this line
        LINE_DONE   // line read complete
    } state, state_next;

    logic hblank_start;    // start of horizontal blanking
    logic fb_last_line;    // last line of framebuffer
    logic fb_last_pixel;   // last pixel of framebuffer line
    logic start_fb_to_lb;  // start copying data from fb to lb
    logic fb_read_line;    // do we need to read fb on current line?
    always_comb begin
        hblank_start    = (sx == H_RES);
        fb_last_line    = (fb_line_cnt == FB_HEIGHT-1);
        fb_last_pixel   = (lb_addr_write == FB_WIDTH-1);
        start_fb_to_lb  = (sy == V_RES_FULL-1);
        fb_read_line    = (lb_line_rpt == 0);
    end

    // determine next state
    always_comb begin
        case(state)
            IDLE:       state_next = (start_fb_to_lb) ? START : IDLE;
            START:      state_next = AWAIT_POS;
            AWAIT_POS:  state_next = hblank_start ? START_LINE : AWAIT_POS;
            START_LINE: state_next = fb_read_line ? READ_FB : AWAIT_POS;
            READ_FB:    state_next = !fb_last_pixel ? READ_FB : LINE_DONE;
            LINE_DONE:  state_next = !fb_last_line ? AWAIT_POS : IDLE;
            default:    state_next = IDLE;
        endcase
    end

    always_ff @(posedge clk_pix) begin
        state <= state_next;  // advance to next state

        // reset framebuffer position at start of frame
        if (state == START) begin
            fb_addr_read <= 0;
            fb_line_cnt <= 0;
            lb_line_rpt <= 0;
        end

        // reset pixel count and linebuffer write address
        if (state == AWAIT_POS) begin
            lb_addr_write <= 0;
        end

        if (state == START_LINE) begin
            /* verilator lint_off WIDTH */
            if (lb_line_rpt == LB_SCALE_V-1) begin
            /* verilator lint_on WIDTH */
                fb_line_cnt <= fb_line_cnt + 1;
                lb_line_rpt <= 0;
            end else begin
                lb_line_rpt <= lb_line_rpt + 1;
            end
        end

        if (state == READ_FB) begin
            lb_we <= 1;
            lb_addr_write <= lb_addr_write + 1;
            fb_addr_read <= fb_addr_read + 1;
        end

        if (state == LINE_DONE) begin
            lb_we <= 0;
        end
    end

    // linebuffer read address (display reads from)
    logic [$clog2(LB_SCALE_H)-1:0] lb_pix_rpt;  // repeat pixel based on scale
    always_ff @(posedge clk_pix) begin
        if (sx == H_RES_FULL-2) begin  // address 0 when H_RES_FULL-1, so we need -2 (latency=1)
            lb_addr_read <= 0;
            lb_pix_rpt <= 0;
        /* verilator lint_off WIDTH */
        end else if (lb_addr_read < LB_LINE-1) begin
            lb_pix_rpt <= (lb_pix_rpt < LB_SCALE_H-1) ? lb_pix_rpt + 1 : 0;
            if (lb_pix_rpt == LB_SCALE_H-1) lb_addr_read <= lb_addr_read + 1;
        end
        /* verilator lint_on WIDTH */
    end

    // Colour Lookup Table
    logic [11:0] clut [16];  // 16 x 12-bit colour palette entries
    initial begin
        $display("Loading palette '%s' into CLUT.", FB_PALETTE);
        $readmemh(FB_PALETTE, clut);  // load palette into CLUT
    end

    // map colour index to palette using CLUT and read into linebuffer
    always_ff @(posedge clk_pix) begin
        {lb2_in, lb1_in, lb0_in} <= fz_en_out ? clut[colr_idx] : 12'h0;
    end

    // VGA output
    always_comb begin
        vga_r = de ? lb2_out : 4'h0;
        vga_g = de ? lb1_out : 4'h0;
        vga_b = de ? lb0_out : 4'h0;
    end
endmodule
