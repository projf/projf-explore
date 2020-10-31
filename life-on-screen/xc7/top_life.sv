// Project F: Life on Screen - Top Life Simulation (Arty with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_life (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    parameter GEN_FRAMES = 15;  // each generation lasts this many frames
    parameter SEED_FILE = "simple_life.mem";  // seed to initiate universe with

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

    logic frame_end;   // high for one clycle at the end of a frame
    always_comb begin
        frame_end = (sy == V_RES_FULL-1 && sx == H_RES_FULL-1);
    end

    // framebuffer
    localparam FB_COUNT  = 2;  // double buffered
    localparam FB_WIDTH  = 80;
    localparam FB_HEIGHT = 60;
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;
    localparam FB_DEPTH  = FB_COUNT * FB_PIXELS;
    localparam FB_ADDRW  = $clog2(FB_DEPTH);
    localparam FB_DATAW  = 1;  // colour bits per pixel

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_read, fb_addr_write;
    logic [FB_DATAW-1:0] pix_in, pix_out;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_DEPTH),
        .INIT_F(SEED_FILE)
    ) framebuffer (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(pix_in),
        .data_out(pix_out)
    );

    // update frame counter and choose front buffer
    logic life_start;    // trigger next calculation
    logic front_buffer;  // which buffer to draw the display from
    logic [$clog2(GEN_FRAMES)-1:0] cnt_frames;
    always_ff @(posedge clk_pix) begin
        if (frame_end) cnt_frames <= cnt_frames + 1;
        if (cnt_frames == GEN_FRAMES - 1) begin
            front_buffer <= ~front_buffer;
            cnt_frames <= 0;
            life_start <= 1;
        end else life_start <= 0;
    end

    logic life_run;
    logic [FB_ADDRW-1:0] cell_id;
    life #(
        .WORLD_WIDTH(FB_WIDTH),
        .WORLD_HEIGHT(FB_HEIGHT),
        .ADDRW(FB_ADDRW)
    ) life_sim (
        .clk(clk_pix),
        .start(life_start),
        .run(life_run),
        .id(cell_id),
        .r_status(pix_out),
        .w_status(pix_in),
        .we(fb_we),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // linebuffer
    localparam LB_SCALE_V = 8;                // factor to scale vertical drawing
    localparam LB_SCALE_H = 8;                // factor to scale horizontal drawing
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

    // linebuffer addresses for accessing framebuffer
    logic [FB_ADDRW-1:0] lb_fb_addr_read;

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
            lb_fb_addr_read <= 0;
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
            lb_fb_addr_read <= lb_fb_addr_read + 1;
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

    // sim can run when linebuffer is not using framebuffer
    always_comb life_run = (state == IDLE);

    // read into line buffer
    always_comb begin
        fb_addr_read = (life_run) ? cell_id : lb_fb_addr_read;
        if (front_buffer == 1) fb_addr_read = fb_addr_read + FB_PIXELS;
        fb_addr_write = (front_buffer == 1) ? cell_id : cell_id + FB_PIXELS;
        {lb2_in, lb1_in, lb0_in} = pix_out ? 12'hFFF : 12'h009;
    end

    // VGA output
    always_comb begin
        vga_r = de ? lb2_out : 4'h0;
        vga_g = de ? lb1_out : 4'h0;
        vga_b = de ? lb0_out : 4'h0;
    end
endmodule
