// Project F: Lines and Triangles - Top Cube (Arty with Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_cube (
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
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(colr_idx_write),
        .data_out(colr_idx_read)
    );

    // draw cube in framebuffer
    localparam LINE_CNT=9;
    logic [3:0] line_id;  // line identifier
    logic [FB_CORDW-1:0] lx0, ly0, lx1, ly1;  // line coords
    always_ff @(posedge clk_pix) begin
        colr_idx_write <= 4'h8;  // red
        case (line_id)
            4'd0: begin
                lx0 <= 130; ly0 <=  90;
                lx1 <= 230; ly1 <=  90;
            end
            4'd1: begin
                lx0 <= 230; ly0 <=  90;
                lx1 <= 230; ly1 <= 190;
            end
            4'd2: begin
                lx0 <= 230; ly0 <= 190;
                lx1 <= 130; ly1 <= 190;
            end
            4'd3: begin
                lx0 <= 130; ly0 <= 190;
                lx1 <= 130; ly1 <=  90;
            end
            4'd4: begin
                lx0 <= 130; ly0 <= 190;
                lx1 <=  90; ly1 <= 150;
            end
            4'd5: begin
                lx0 <=  90; ly0 <= 150;
                lx1 <=  90; ly1 <=  50;
            end
            4'd6: begin
                lx0 <=  90; ly0 <=  50;
                lx1 <= 130; ly1 <=  90;
            end
            4'd7: begin
                lx0 <=  90; ly0 <=  50;
                lx1 <= 190; ly1 <=  50;
            end
            4'd8: begin
                lx0 <= 190; ly0 <=  50;
                lx1 <= 230; ly1 <=  90;
            end
            default: begin
                lx0 <=  0; ly0 <=  0;
                lx1 <=  0; ly1 <=  0;
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
        end else if (draw_done && line_id != LINE_CNT-1) begin
            line_id <= line_id + 1;
            draw_flag <= 0;
        end
    end

    // control drawing output enable - wait 300 frames, then 1 pixel/frame
    localparam DRAW_WAIT = 300;
    logic [$clog2(DRAW_WAIT)-1:0] cnt_draw_wait;
    logic draw_oe;
    always_ff @(posedge clk_pix) begin
        draw_oe <= 0;
        if (vbi) begin
            if (cnt_draw_wait != DRAW_WAIT-1) begin
                cnt_draw_wait <= cnt_draw_wait + 1;
            end else draw_oe <= 1;
        end
    end

    logic [FB_CORDW-1:0] px, py;
    draw_line #(.CORDW(FB_CORDW)) draw_line_inst (
        .clk(clk_pix),
        .rst(1'b0),
        .start(draw_start),
        .oe(draw_oe),
        .x0(lx0),
        .y0(ly0),
        .x1(lx1),
        .y1(ly1),
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

    // linebuffer (LB)
    localparam LB_SCALE = 2;       // scale (horizontal and vertical)
    localparam LB_LEN = FB_WIDTH;  // line length matches framebuffer
    localparam LB_BPC = 4;         // bits per colour channel

    // LB output to display
    logic lb_en_out;  // When does LB output data? Use 'de' for entire frame.
    always_comb lb_en_out = de;

    // Load data from FB into LB
    logic lb_data_req;  // LB requesting data
    logic [$clog2(LB_LEN+1)-1:0] cnt_h;  // count pixels in line to read
    always_ff @(posedge clk_pix) begin
        if (vbi) fb_addr_read <= 0;   // new frame
        if (lb_data_req && sy != V_RES-1) begin  // load next line of data...
            cnt_h <= 0;                          // ...if not on last line
        end else if (cnt_h < LB_LEN) begin  // advance to start of next line
            cnt_h <= cnt_h + 1;
            fb_addr_read <= fb_addr_read == FB_PIXELS-1 ? 0 : fb_addr_read + 1;
        end
    end

    // FB BRAM and CLUT each add one cycle of latency
    logic lb_en_in_1, lb_en_in;
    always_ff @(posedge clk_pix) begin
        lb_en_in_1 <= (cnt_h < LB_LEN);
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
        vga_r <= lb_en_out ? lb_out_2 : 4'h0;
        vga_g <= lb_en_out ? lb_out_1 : 4'h0;
        vga_b <= lb_en_out ? lb_out_0 : 4'h0;
    end
endmodule
