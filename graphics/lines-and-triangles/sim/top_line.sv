// Project F: Lines and Triangles - Line (Verilator SDL)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module top_line #(parameter CORDW=16) (  // signed coordinate width (bits)
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

    // system clock is the same as pixel clock in simulation
    logic clk_sys, rst_sys;
    always_comb begin
        clk_sys = clk_pix;
        rst_sys = rst_pix;
    end

    // display sync signals and coordinates
    logic signed [CORDW-1:0] sx, sy;
    logic de, frame, line;
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
        .line
    );

    // display settings
    // localparam FB_SCALE = 1;  // framebuffer scaling via linebuffer (min 1x)
    // localparam OSX = 160;     // horizontal offset (1x scale)
    // localparam OSY = 150;     // vertical offset (1x scale)
    localparam FB_SCALE = 2;  // framebuffer scaling via linebuffer (min 1x)
    localparam OSX =  0;      // horizontal offset (2x scale)
    localparam OSY = 60;      // vertical offset (2x scale)

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_sys),
                 .rst_i(rst_pix), .rst_o(rst_sys), .i(frame), .o(frame_sys));

    // colour parameters
    localparam CHANW = 4;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam CIDXW = 4;        // colour index width (bits)
    localparam PAL_FILE = "../../../lib/res/palettes/sweetie16_4b.mem";  // palette file

    // framebuffer (FB)
    localparam FB_WIDTH  = 320;
    localparam FB_HEIGHT = 180;
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel
    localparam FB_IMAGE  = "";  // bitmap file

    logic fb_we;
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_write, fb_colr_read;

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_sys),
        .clk_read(clk_sys),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_colr_write),
        .data_out(fb_colr_read)
    );

    // draw line in framebuffer
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1;  // line coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk_sys) begin
        case (state)
            INIT: begin  // register coordinates and colour
                vx0 <=  70; vy0 <=   0;
                vx1 <= 249; vy1 <= 179;
                fb_colr_write <= 4'h3;  // orange
                draw_start <= 1;
                state <= DRAW;
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) state <= DONE;
            end
            DONE: state <= DONE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    logic signed [CORDW-1:0] drx, dry;  // draw coordinates
    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk(clk_sys),
        .rst(rst_sys),
        .start(draw_start),
        .oe(1'b1),
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x(drx),
        .y(dry),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    // calculate pixel address in framebuffer (two cycle latency)
    bitmap_addr #(
        .CORDW(CORDW),
        .ADDRW(FB_ADDRW)
    ) bitmap_addr_instance (
        .clk(clk_sys),
        .bmpw(FB_WIDTH),
        .bmph(FB_HEIGHT),
        .x(drx),
        .y(dry),
        .offx(0),
        .offy(0),
        .addr(fb_addr_write),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // delay write enable to match address calculation latency
    always_ff @(posedge clk_sys) fb_we <= drawing;

    // linebuffer (LB)
    logic [$clog2(FB_SCALE):0] cnt_lb_line;  // count lines for scaling
    always_ff @(posedge clk_pix) begin
        if (line) begin
            if (sy == 0) cnt_lb_line <= 0;
            else cnt_lb_line <= (cnt_lb_line == FB_SCALE-1) ? 0 : cnt_lb_line + 1;
        end
    end

    // enable linebuffer input
    logic lb_en_in;
    always_comb lb_en_in = (sy >= OSY && sy < (FB_HEIGHT * FB_SCALE) + OSY && cnt_lb_line == 0 && cnt_lbx < FB_WIDTH);

    // enable linebuffer output
    logic lb_en_out;
    localparam LB_LAT = 3;  // output latency compensation: lb_en_out+1, LB+1, CLUT+1
    always_ff @(posedge clk_pix) begin
        lb_en_out <= (sy >= OSY && sy < (FB_HEIGHT * FB_SCALE) + OSY
            && sx >= OSX - LB_LAT && sx < (FB_WIDTH * FB_SCALE) + OSX - LB_LAT);
    end

    // calculate framebuffer read address for linebuffer
    logic [$clog2(FB_WIDTH)-1:0] cnt_lbx;
    always_ff @(posedge clk_sys) begin
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (line) begin  // reset horizontal counter at start of line
            cnt_lbx <= 0;
        end else if (lb_en_in) begin
            fb_addr_read <= fb_addr_read + 1;
            cnt_lbx <= cnt_lbx + 1;
        end
    end

    logic [FB_DATAW-1:0] lb_colr_out;
    linebuffer_simple #(
        .DATAW(CIDXW),
        .LEN(FB_WIDTH),
        .SCALE(FB_SCALE)
    ) linebuffer_instance (
        .clk_in(clk_sys),
        .clk_out(clk_pix),
        .rst_in(line),  // should be in system clock domain
        .rst_out(line),
        .en_in(lb_en_in),  // should be in system clock domain
        .en_out(lb_en_out),
        .data_in(fb_colr_read),
        .data_out(lb_colr_out)
    );

    // colour lookup table
    logic [COLRW-1:0] fb_pix_colr;
    clut_simple #(
        .COLRW(COLRW),
        .CIDXW(CIDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(0),
        .cidx_write(0),
        .cidx_read(lb_colr_out),
        .colr_in(0),
        .colr_out(fb_pix_colr)
    );

    // paint screen
    logic paint_area;  // area of screen to paint
    logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
    always_comb begin
        paint_area = (sy >= OSY && sy < (FB_HEIGHT * FB_SCALE) + OSY
            && sx >= OSX && sx < FB_WIDTH * FB_SCALE + OSX);
        {paint_r, paint_g, paint_b} = (de && paint_area) ? fb_pix_colr: 12'h000;
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
