// Project F: Sine Scroller (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/sinescroll/

`default_nettype none
`timescale 1ns / 1ps

module top_sinescroll (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate system clock
    logic clk_sys;
    logic clk_sys_locked;
    logic rst_sys;
    clock_sys clock_sys_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_sys,
       .clk_sys_locked
    );
    always_ff @(posedge clk_sys) rst_sys <= !clk_sys_locked;  // wait for clock lock

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       /* verilator lint_off PINCONNECTEMPTY */
       .clk_pix_5x(),  // not used for VGA output
       /* verilator lint_on PINCONNECTEMPTY */
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // colour parameters
    localparam CHANW = 4;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam CIDXW = 4;        // colour index width (bits)
    localparam PAL_FILE = "sweetie16_4b.mem";  // palette file

    // framebuffer (FB)
    localparam FB_WIDTH  = 320;  // framebuffer width in pixels
    localparam FB_HEIGHT = 180;  // framebuffer height in pixels
    localparam FB_SCALE  =   2;  // framebuffer display scale (1-63)
    localparam FB_OFFX   =   0;  // horizontal offset
    localparam FB_OFFY   =  60;  // vertical offset
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel

    // pixel read and write addresses and colours
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_clear, fb_addr_render;
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_write, fb_colr_clear, fb_colr_render;
    logic [FB_DATAW-1:0] fb_colr_read, fb_colr_read_0, fb_colr_read_1;
    logic fb_we;  // framebuffer write enable

    // buffer selection
    logic fb_front;

    // framebuffer memories
    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F("")
    ) bram_inst_0 (
        .clk_write(clk_sys),
        .clk_read(clk_sys),
        .we(fb_we && fb_front),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_colr_write),
        .data_out(fb_colr_read_0)
    );

    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F("")
    ) bram_inst_1 (
        .clk_write(clk_sys),
        .clk_read(clk_sys),
        .we(fb_we && !fb_front),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_colr_write),
        .data_out(fb_colr_read_1)
    );

    // display flags in system clock domain
    logic frame_sys, line_sys, line0_sys;
    xd xd_frame (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(frame), .flag_dst(frame_sys));
    xd xd_line  (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(line),  .flag_dst(line_sys));
    xd xd_line0 (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(line && sy==FB_OFFY), .flag_dst(line0_sys));

    //
    // draw in framebuffer
    //

    logic render_start;
    logic render_done;

    // framebuffer state machine
    enum {IDLE, INIT, CLEAR, DRAW, DONE} state;
    always_ff @(posedge clk_sys) begin
        case (state)
            INIT: begin
                state <= CLEAR;
                fb_front <= ~fb_front; // swap buffers
                fb_addr_clear <= 0;
                fb_colr_clear <= 'h0;
            end
            CLEAR: begin
                fb_addr_clear <= fb_addr_clear + 1;
                if (fb_addr_clear == FB_PIXELS-1) begin
                    state <= DRAW;
                    render_start <= 1;
                end
            end
            DRAW: begin
                state <= render_done ? DONE : DRAW;
                render_start <= 0;
            end
            DONE: state <= IDLE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
        if (rst_sys) state <= IDLE;
    end

    always_ff @(posedge clk_sys) begin
        fb_addr_write <= (state == CLEAR) ? fb_addr_clear : fb_addr_render;
        fb_colr_write <= (state == CLEAR) ? fb_colr_clear : fb_colr_render;
    end

    // render message
    localparam GREET_FILE = "greet.mem";;
    localparam FONT_FILE  = "outline-font-32x32.mem";
    localparam SIN_FILE   = "sine_table_64x8.mem";
    logic char_pix;
    logic drawing;  // actively drawing
    logic clip;  // location is clipped
    logic signed [CORDW-1:0] drx, dry;  // draw coordinates
    render_sinescroll #( 
        .CORDW(CORDW),
        .GREET_FILE(GREET_FILE),
        .FONT_FILE(FONT_FILE),
        .SIN_FILE(SIN_FILE),
        .SIN_SHIFT(2)
    ) render_instance (
        .clk(clk_sys),
        .rst(rst_sys),
        .oe(1'b1),
        .start(render_start),
        .x(drx),
        .y(dry),
        .pix(char_pix),
        .drawing,
        .done(render_done)
    );

    // calculate pixel address in framebuffer (three-cycle latency)
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
        .addr(fb_addr_render),
        .clip
    );

    // delay write enable to match address calculation
    localparam LAT_ADDR = 3;  // latency (cycles)
    logic [LAT_ADDR-1:0] fb_we_sr;
    always_ff @(posedge clk_sys) begin
        fb_we_sr <= {drawing, fb_we_sr[LAT_ADDR-1:1]};
        if (rst_sys) fb_we_sr <= 0;
        fb_we <= (state == CLEAR) || (fb_we_sr[0] && !clip);  // check for clipping
    end

    // delay pixel colour to match address calculation
    logic [LAT_ADDR-1:0] char_pix_sr;
    always_ff @(posedge clk_sys) begin
        char_pix_sr <= {char_pix, char_pix_sr[LAT_ADDR-1:1]};
        if (rst_sys) char_pix_sr <= 0;
        fb_colr_render <= char_pix_sr[0] ? 'h3: 'h0;
    end

    //
    // read framebuffer for display output via linebuffer
    //

    // select buffer to read
    always_ff @(posedge clk_sys) fb_colr_read <= fb_front ? fb_colr_read_1 : fb_colr_read_0;

    // count lines for scaling via linebuffer
    logic [$clog2(FB_SCALE):0] cnt_lb_line;
    always_ff @(posedge clk_sys) begin
        if (line0_sys) cnt_lb_line <= 0;
        else if (line_sys) begin
            cnt_lb_line <= (cnt_lb_line == FB_SCALE-1) ? 0 : cnt_lb_line + 1;
        end
    end

    // which screen lines need linebuffer?
    logic lb_line;
    always_ff @(posedge clk_sys) begin
        if (line0_sys) lb_line <= 1;  // enable from sy==0
        if (frame_sys) lb_line <= 0;  // disable at frame start
    end

    // enable linebuffer input
    logic lb_en_in;
    logic [$clog2(FB_WIDTH)-1:0] cnt_lbx;  // horizontal pixel counter
    always_comb lb_en_in = (lb_line && cnt_lb_line == 0 && cnt_lbx < FB_WIDTH);

    // calculate framebuffer read address for linebuffer
    always_ff @(posedge clk_sys) begin
        if (line_sys) begin  // reset horizontal counter at start of line
            cnt_lbx <= 0;
        end else if (lb_en_in) begin  // increment address when LB enabled
            fb_addr_read <= fb_addr_read + 1;
            cnt_lbx <= cnt_lbx + 1;
        end
        if (frame_sys) fb_addr_read <= 0;  // reset address at frame start
    end

    // enable linebuffer output
    logic lb_en_out;
    localparam LAT_LB = 4;  // latency compensation: lb_en_out+1, DB+1, LB+1, CLUT+1
    always_ff @(posedge clk_pix) begin
        lb_en_out <= (sy >= FB_OFFY && sy < (FB_HEIGHT * FB_SCALE) + FB_OFFY
            && sx >= FB_OFFX - LAT_LB && sx < (FB_WIDTH * FB_SCALE) + FB_OFFX - LAT_LB);
    end

    // display linebuffer
    logic [FB_DATAW-1:0] lb_colr_out;
    linebuffer_simple #(
        .DATAW(FB_DATAW),
        .LEN(FB_WIDTH)
    ) linebuffer_instance (
        .clk_sys,
        .clk_pix,
        .line,
        .line_sys,
        .en_in(lb_en_in),
        .en_out(lb_en_out),
        .scale(FB_SCALE),
        .data_in(fb_colr_read),
        .data_out(lb_colr_out)
    );

    // colour lookup table (CLUT)
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
        paint_area = (sy >= FB_OFFY && sy < (FB_HEIGHT * FB_SCALE) + FB_OFFY
            && sx >= FB_OFFX && sx < FB_WIDTH * FB_SCALE + FB_OFFX);
        {paint_r, paint_g, paint_b} = (de && paint_area) ? fb_pix_colr: 12'h000;
    end

    // VGA Pmod output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        if (de) begin
            vga_r <= paint_r;
            vga_g <= paint_g;
            vga_b <= paint_b;
        end else begin  // VGA colour should be black in blanking interval
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
    end
endmodule
