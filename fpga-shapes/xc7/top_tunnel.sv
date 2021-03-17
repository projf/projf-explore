// Project F: FPGA Shapes - Top Tunnel (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_tunnel (
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
    logic hsync, vsync, de;
    display_timings_480p timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    // vertical blanking interval (will move to display_timings soon)
    logic vbi;
    always_comb vbi = (sy == V_RES && sx == 0);

    // framebuffers (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 240;
    localparam FB_CORDW   = $clog2(FB_WIDTH);  // assumes WIDTH>=HEIGHT
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "tunnel_16_colr_4bit_palette.mem";

    // framebuffer multiplexing signals: drawing
    logic fb_we, fb_we_draw, fb_we_clr;
    /* verilator lint_off UNDRIVEN */
    /* verilator lint_off UNUSED */
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_draw, fb_addr_clr;
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_cidx_write, fb_cidx_draw;
    logic [FB_DATAW-1:0] fb_cidx_read;
    /* verilator lint_off UNUSED */
    /* verilator lint_on UNDRIVEN */
    // framebuffer multiplexing signals: display
    logic [FB_ADDRW-1:0] fb_addr_disp;
    logic [FB_DATAW-1:0] fb_cidx_disp;

    // draw shapes in framebuffer
    localparam SHAPE_CNT=7;
    logic [3:0] shape_id;  // shape identifier
    logic [FB_CORDW-1:0] dx0, dy0, dx1, dy1;  // draw coords
    logic [FB_CORDW-1:0] px, py;  // shape pixel drawing coordinates
    logic draw_start, drawing, draw_done;  // draw_line signals

    // animation steps
    localparam ANIM_CNT=5;    // five frames in animation
    localparam ANIM_SPEED=6;  // six display frames per animation step 10fps
    logic [$clog2(ANIM_CNT)-1:0] cnt_anim;
    logic [$clog2(ANIM_SPEED)-1:0] cnt_anim_speed;
    logic [FB_DATAW-1:0] colr_offs;  // colour offset
    always @(posedge clk_pix) begin
        if (vbi) begin
            if (cnt_anim_speed == ANIM_SPEED-1) begin
                if (cnt_anim == ANIM_CNT-1) begin
                    cnt_anim <= 0;
                    colr_offs <= colr_offs + 1;
                end else cnt_anim <= cnt_anim + 1;
                cnt_anim_speed <= 0;
            end else cnt_anim_speed <= cnt_anim_speed + 1;
        end
    end

    // draw state machine
    enum {IDLE, INIT, CLEAR, DRAW, DONE} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk_pix) begin
        draw_start <= 0;
        case (state)
            CLEAR: begin
                if (fb_addr_clr != FB_PIXELS-1) begin
                    fb_addr_clr <= fb_addr_clr + 1;
                end else begin
                    state <= INIT;
                    fb_we_clr <= 0;
                end
            end
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                case (shape_id)
                    4'd0: begin
                        dx0 <=  40; dy0 <=   0;
                        dx1 <= 279; dy1 <= 239;
                        fb_cidx_draw <= colr_offs;
                    end
                    4'd1: begin  // 8 pixels per anim step
                        dx0 <=  80 - cnt_anim * 8; 
                        dy0 <=  40 - cnt_anim * 8;
                        dx1 <= 239 + cnt_anim * 8; 
                        dy1 <= 199 + cnt_anim * 8;
                        fb_cidx_draw <= colr_offs + 1;
                    end
                    4'd2: begin  // 5 pixels per anim step
                        dx0 <= 105 - cnt_anim * 5;
                        dy0 <=  65 - cnt_anim * 5;
                        dx1 <= 214 + cnt_anim * 5; 
                        dy1 <= 174 + cnt_anim * 5;
                        fb_cidx_draw <= colr_offs + 2;
                    end
                    4'd3: begin  // 4 pixels per anim step
                        dx0 <= 125 - cnt_anim * 4; 
                        dy0 <=  85 - cnt_anim * 4;
                        dx1 <= 194 + cnt_anim * 4; 
                        dy1 <= 154 + cnt_anim * 4;
                        fb_cidx_draw <= colr_offs + 3;
                    end
                    4'd4: begin  // 3 pixels per anim step
                        dx0 <= 140 - cnt_anim * 3; 
                        dy0 <= 100 - cnt_anim * 3;
                        dx1 <= 179 + cnt_anim * 3; 
                        dy1 <= 139 + cnt_anim * 3;
                        fb_cidx_draw <= colr_offs + 4;
                    end
                    4'd5: begin  // 2 pixels per anim step
                        dx0 <= 150 - cnt_anim * 2; 
                        dy0 <= 110 - cnt_anim * 2;
                        dx1 <= 169 + cnt_anim * 2; 
                        dy1 <= 129 + cnt_anim * 2;
                        fb_cidx_draw <= colr_offs + 5;
                    end
                    4'd6: begin  // 1 pixel per anim step
                        dx0 <= 155 - cnt_anim * 1; 
                        dy0 <= 115 - cnt_anim * 1;
                        dx1 <= 164 + cnt_anim * 1; 
                        dy1 <= 124 + cnt_anim * 1;
                        fb_cidx_draw <= colr_offs + 6;
                    end
                    default: begin  // should never occur
                        dx0 <=  10; dy0 <=  10;
                        dx1 <=  20; dy1 <=  20;
                        fb_cidx_draw <= 4'h7;  // white
                    end
                endcase
            end
            DRAW: if (draw_done) begin
                if (shape_id == SHAPE_CNT-1) begin
                    state <= DONE;
                end else begin
                    shape_id <= shape_id + 1;
                    state <= INIT;
                end
            end            
            DONE: state <= IDLE;
            default: if (vbi) begin  // IDLE
                state <= CLEAR;
                shape_id <= 0;
                fb_we_clr <= 1;
                fb_addr_clr <= 0;
            end
        endcase
    end

    // framebuffer 0
    logic fb0_we;
    logic [FB_ADDRW-1:0] fb0_addr_read;
    logic [FB_DATAW-1:0] fb0_cidx_read, fb0_cidx_read_1;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) fb0_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb0_we),
        .addr_write(fb_addr_write),
        .addr_read(fb0_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb0_cidx_read_1)
    );

    // framebuffer 1
    logic fb1_we;
    logic [FB_ADDRW-1:0] fb1_addr_read;
    logic [FB_DATAW-1:0] fb1_cidx_read, fb1_cidx_read_1;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) fb1_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb1_we),
        .addr_write(fb_addr_write),
        .addr_read(fb1_addr_read),
        .data_in(fb_cidx_write),
        .data_out(fb1_cidx_read_1)
    );

    logic fb_draw;  // which buffer to draw in; swap every frame
    always @(posedge clk_pix) if (vbi) fb_draw <= ~fb_draw;

    // switch between clearing and drawing screen
    // clear colour is currently hard-coded to the offet colour
    always_comb begin
        fb_we = (state == CLEAR) ? fb_we_clr : fb_we_draw;
        fb_addr_write = (state == CLEAR) ? fb_addr_clr : fb_addr_draw;
        fb_cidx_write = (state == CLEAR) ? colr_offs : fb_cidx_draw;
    end

    // switch between framebuffers
    always_comb begin
        // write enable
        fb0_we = fb_draw ? 0 : fb_we;
        fb1_we = fb_draw ? fb_we : 0;
        // read address
        fb0_addr_read  = fb_draw ? fb_addr_disp : fb_addr_read;
        fb1_addr_read  = fb_draw ? fb_addr_read : fb_addr_disp;
        // pixel colour
        fb_cidx_read = fb_draw ? fb1_cidx_read : fb0_cidx_read;
        fb_cidx_disp = fb_draw ? fb0_cidx_read : fb1_cidx_read;
    end

    draw_rectangle_fill #(.CORDW(FB_CORDW)) draw_rectangle_inst (
        .clk(clk_pix),
        .rst(!clk_locked),
        .start(draw_start),
        .oe(1'b1),
        .x0(dx0),
        .y0(dy0),
        .x1(dx1),
        .y1(dy1),
        .x(px),
        .y(py),
        .drawing,
        .done(draw_done)
    );

    // pixel coordinate to memory address calculation takes one cycle
    always_ff @(posedge clk_pix) fb_we_draw <= drawing;

    pix_addr #(
        .CORDW(FB_CORDW),
        .ADDRW(FB_ADDRW)
    ) pix_addr_inst (
        .clk(clk_pix),
        .hres(FB_WIDTH),
        .px,
        .py,
        .pix_addr(fb_addr_draw)
    );

    // linebuffer (LB)
    localparam LB_SCALE = 2;       // scale (horizontal and vertical)
    localparam LB_LEN = FB_WIDTH;  // line length matches framebuffer
    localparam LB_BPC = 4;         // bits per colour channel

    // LB output to display
    logic lb_en_out;
    always_comb lb_en_out = de;  // Use 'de' for entire frame

    // Load data from FB into LB
    logic lb_data_req;  // LB requesting data
    logic [$clog2(LB_LEN+1)-1:0] cnt_h;  // count pixels in line to read
    always_ff @(posedge clk_pix) begin
        if (vbi) fb_addr_disp <= 0;   // new frame
        if (lb_data_req && sy != V_RES-1) begin  // load next line of data...
            cnt_h <= 0;                          // ...if not on last line
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            fb_addr_disp <= fb_addr_disp == FB_PIXELS-1 ? 0 : fb_addr_disp + 1;
        end
    end

    // FB BRAM and CLUT pipeline adds three cycles of latency
    logic lb_en_in_2, lb_en_in_1, lb_en_in;
    always_ff @(posedge clk_pix) begin
        lb_en_in_2 <= (cnt_h < LB_LEN);
        lb_en_in_1 <= lb_en_in_2;
        lb_en_in <= lb_en_in_1;
    end

    // LB colour channels
    logic [LB_BPC-1:0] lb_in_0, lb_in_1, lb_in_2;
    logic [LB_BPC-1:0] lb_out_0, lb_out_1, lb_out_2;

    linebuffer #(
        .WIDTH(LB_BPC),     // data width of each channel
        .LEN(LB_LEN),       // length of line
        .SCALE(LB_SCALE)    // scaling factor (>=1)
        ) lb_inst (
        .clk_in(clk_pix),       // input clock
        .clk_out(clk_pix),      // output clock
        .data_req(lb_data_req), // request input data (clk_in)
        .en_in(lb_en_in),       // enable input (clk_in)
        .en_out(lb_en_out),     // enable output (clk_out)
        .vbi,                   // start of vertical blanking interval (clk_out)
        .din_0(lb_in_0),        // data in (clk_in)
        .din_1(lb_in_1),
        .din_2(lb_in_2),
        .dout_0(lb_out_0),      // data out (clk_out)
        .dout_1(lb_out_1),
        .dout_2(lb_out_2)
    );

    // improve timing with register between BRAM and async ROM
    always @(posedge clk_pix) begin
        fb0_cidx_read <= fb0_cidx_read_1;
        fb1_cidx_read <= fb1_cidx_read_1;
    end

    // colour lookup table (ROM) 16x12-bit entries
    logic [11:0] clut_colr;
    rom_async #(
        .WIDTH(12),
        .DEPTH(16),
        .INIT_F(FB_PALETTE)
    ) clut (
        .addr(fb_cidx_disp),
        .data(clut_colr)
    );

    // map colour index to palette using CLUT and read into LB
    always_ff @(posedge clk_pix) begin
        {lb_in_2, lb_in_1, lb_in_0} <= clut_colr;
    end

    // LB output adds one cycle of latency - need to correct display signals
    logic hsync_1, vsync_1, lb_en_out_1;
    always_ff @(posedge clk_pix) begin
        hsync_1 <= hsync;
        vsync_1 <= vsync;
        lb_en_out_1 <= lb_en_out;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_1;
        vga_vsync <= vsync_1;
        vga_r <= lb_en_out_1 ? lb_out_2 : 4'h0;
        vga_g <= lb_en_out_1 ? lb_out_1 : 4'h0;
        vga_b <= lb_en_out_1 ? lb_out_0 : 4'h0;
    end
endmodule
