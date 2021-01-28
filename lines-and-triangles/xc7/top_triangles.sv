// Project F: Lines and Triangles - Top Triangles (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_triangles (
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

    logic animate;  // high for one clock tick at start of vertical blanking
    always_comb animate = (sy == V_RES && sx == 0);

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 240;
    localparam FB_CORDW   = $clog2(FB_WIDTH);  // assumes WIDTH>=HEIGHT
    localparam FB_PIXELS  = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW   = $clog2(FB_PIXELS);
    localparam FB_DATAW   = 4;  // colour bits per pixel
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] colr_idx_write, colr_idx_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) fb_inst (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(colr_idx_write),
        .data_out(colr_idx_read)
    );

    // draw shapes in framebuffer
    localparam SHAPE_CNT=3;
    logic [2:0] shape_id;  // shape identifier
    logic [FB_CORDW-1:0] tx0, ty0, tx1, ty1, tx2, ty2;  // triangle coords
    always_ff @(posedge clk_pix) begin
        case (shape_id)
            3'd0: begin
                tx0 <=  20; ty0 <=  60;
                tx1 <=  60; ty1 <= 180;
                tx2 <= 110; ty2 <=  90;
                colr_idx_write <= 4'h2;  // dark purple
            end
            3'd1: begin
                tx0 <=  70; ty0 <= 200;
                tx1 <= 240; ty1 <= 100;
                tx2 <= 170; ty2 <=  10;
                colr_idx_write <= 4'hC;  // blue
            end
            3'd2: begin
                tx0 <=  60; ty0 <=  30;
                tx1 <= 300; ty1 <=  80;
                tx2 <= 160; ty2 <= 220;
                colr_idx_write <= 4'h9;  // orange
            end
            default: begin  // we shouldn't see this
                tx0 <=   10; ty0 <=   10;
                tx1 <=   10; ty1 <=   30;
                tx2 <=   20; ty2 <=   20;
                colr_idx_write <= 4'h7;  // white
            end
        endcase
    end

    // control start of drawing
    logic draw_flag, draw_start, drawing, draw_done;
    always @(posedge clk_pix) begin
        draw_start <= 0;
        if (draw_flag == 0) begin
            draw_start <= 1;
            draw_flag <= 1;
        end else if (draw_done && shape_id != SHAPE_CNT-1) begin
            shape_id <= shape_id + 1;
            draw_flag <= 0;
        end
    end

    // control drawing output enable - wait 300 frames, then 1 pixel/frame
    localparam DRAW_WAIT = 300;
    logic [$clog2(DRAW_WAIT)-1:0] cnt_draw_wait;
    logic draw_oe;
    always_ff @(posedge clk_pix) begin
        draw_oe <= 0;
        if (animate) begin
            if (cnt_draw_wait != DRAW_WAIT-1) begin
                cnt_draw_wait <= cnt_draw_wait + 1;
            end else draw_oe <= 1;
        end
    end

    logic [FB_CORDW-1:0] px, py;
    draw_triangle #(.CORDW(FB_CORDW)) draw_triangle_inst (
        .clk(clk_pix),
        .rst(1'b0),
        .start(draw_start),
        .oe(draw_oe),
        .x0(tx0),
        .y0(ty0),
        .x1(tx1),
        .y1(ty1),
        .x2(tx2),
        .y2(ty2),
        .x(px),
        .y(py),
        .drawing,
        .done(draw_done)
    );

    // pixel coordinate to memory address calculation takes one cycle
    always_ff @(posedge clk_pix) fb_we <= drawing;

    pix_addr #(
        .CORDW(FB_CORDW),
        .ADDRW(FB_ADDRW)
    ) pix_addr_inst (
        .clk(clk_pix),
        .hres(FB_WIDTH),
        .px,
        .py,
        .pix_addr(fb_addr_write)
    );

    // linebuffer (LB) - more logic will be moved into module in later version
    localparam LB_SCALE_V = 2;               // scale vertical drawing
    localparam LB_SCALE_H = 2;               // scale horizontal drawing
    localparam LB_LEN = H_RES / LB_SCALE_H;  // line length
    localparam LB_WIDTH = 4;                 // bits per colour channel

    // LB data in from FB
    logic lb_en_in, lb_en_in_1;  // allow for BRAM latency correction
    logic [LB_WIDTH-1:0] lb_in_0, lb_in_1, lb_in_2;

    // correct vertical scale: if scale is 0, set to 1
    logic [$clog2(LB_SCALE_V+1):0] scale_v_cor;
    always_comb scale_v_cor = (LB_SCALE_V == 0) ? 1 : LB_SCALE_V;

    // count screen lines for vertical scaling - read when cnt_scale_v==0
    logic [$clog2(LB_SCALE_V):0] cnt_scale_v;
    always_ff @(posedge clk_pix) begin
        /* verilator lint_off WIDTH */
        if (sx == 0)
            cnt_scale_v <= (cnt_scale_v == scale_v_cor-1) ? 0 : cnt_scale_v + 1;
        /* verilator lint_on WIDTH */
        if (sy == V_RES_FULL-1) cnt_scale_v <= 0;
    end

    logic [$clog2(FB_WIDTH)-1:0] fb_h_cnt;  // counter for FB pixels on line
    always_ff @(posedge clk_pix) begin
        if (sy == V_RES_FULL-1 && sx == H_RES-1) fb_addr_read <= 0;

        // reset horizontal counter at the start of blanking on reading lines
        if (cnt_scale_v == 0 && sx == H_RES) begin
            if (fb_addr_read < FB_PIXELS-1) fb_h_cnt <= 0;  // read all pixels?
        end

        // read each pixel on FB line and write to LB
        if (fb_h_cnt < FB_WIDTH) begin
            lb_en_in <= 1;
            fb_h_cnt <= fb_h_cnt + 1;
            fb_addr_read <= fb_addr_read + 1;
        end else begin
            lb_en_in <= 0;
        end

        // enable LB data in with latency correction
        lb_en_in_1 <= lb_en_in;
    end

    // LB data out to display
    logic [LB_WIDTH-1:0] lb_out_0, lb_out_1, lb_out_2;

    linebuffer #(
        .WIDTH(LB_WIDTH),
        .LEN(LB_LEN)
        ) lb_inst (
        .clk_in(clk_pix),
        .clk_out(clk_pix),
        .en_in(lb_en_in_1),  // correct for BRAM latency
        .en_out(sy < V_RES && sx < H_RES),
        .rst_in(sx == H_RES),  // reset at start of horizontal blanking
        .rst_out(sx == H_RES),
        .scale(LB_SCALE_H),
        .data_in_0(lb_in_0),
        .data_in_1(lb_in_1),
        .data_in_2(lb_in_2),
        .data_out_0(lb_out_0),
        .data_out_1(lb_out_1),
        .data_out_2(lb_out_2)
    );

    // colour lookup table (ROM) 16x12-bit entries
    logic [11:0] clut_colr;
    rom_async #(
        .WIDTH(12),
        .DEPTH(16),
        .INIT_F(FB_PALETTE)
    ) clut (
        .addr(colr_idx_read),
        .data(clut_colr)
    );

    // map colour index to palette using CLUT and read into LB
    always_ff @(posedge clk_pix) begin
        {lb_in_2, lb_in_1, lb_in_0} <= clut_colr;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= de ? lb_out_2 : 4'h0;
        vga_g <= de ? lb_out_1 : 4'h0;
        vga_b <= de ? lb_out_0 : 4'h0;
    end
endmodule
