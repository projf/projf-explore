// Project F: Lines and Triangles - Top Triangles (Arty Pmod VGA)
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
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic frame, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        /* verilator lint_off PINCONNECTEMPTY */
        .de(),
        /* verilator lint_off PINCONNECTEMPTY */
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m),
                 .rst_i(1'b0), .rst_o(1'b0), .i(frame), .o(frame_sys));

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 180;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 2;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

    logic fb_we;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    framebuffer #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_100m),
        .clk_pix,
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de(sy >= 60 && sy < 420 && sx >= 0),  // 16:9 letterbox
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw triangles in framebuffer
    localparam SHAPE_CNT=3;  // number of shapes to draw
    logic [1:0] shape_id;    // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            INIT: begin  // register coordinates and colour
                draw_start <= 1;
                state <= DRAW;
                case (shape_id)
                    2'd0: begin
                        vx0 <=  60; vy0 <=  20;
                        vx1 <= 280; vy1 <=  80;
                        vx2 <= 160; vy2 <= 164;
                        fb_cidx <= 4'h9;  // orange
                    end
                    2'd1: begin
                        vx0 <=  70; vy0 <= 160;
                        vx1 <= 220; vy1 <=  90;
                        vx2 <= 170; vy2 <=  10;
                        fb_cidx <= 4'hC;  // blue
                    end
                    2'd2: begin
                        vx0 <=  22; vy0 <=  35;
                        vx1 <=  62; vy1 <= 150;
                        vx2 <=  98; vy2 <=  96;
                        fb_cidx <= 4'h2;  // dark purple
                    end
                    default: begin  // should never occur
                        vx0 <=   10; vy0 <=   10;
                        vx1 <=   10; vy1 <=   30;
                        vx2 <=   20; vy2 <=   20;
                        fb_cidx <= 4'h7;  // white
                    end
                endcase
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) begin
                    if (shape_id == SHAPE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        shape_id <= shape_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: state <= DONE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    // control drawing speed with output enable
    localparam FRAME_WAIT = 300;  // wait this many frames to start drawing
    logic [$clog2(FRAME_WAIT)-1:0] cnt_frame_wait;
    logic draw_oe;
    always_ff @(posedge clk_100m) begin
        draw_oe <= 0;
        if (frame_sys) begin  // one cycle per frame
            if (cnt_frame_wait != FRAME_WAIT-1) begin
                cnt_frame_wait <= cnt_frame_wait + 1;
            end else draw_oe <= 1;  // enable drawing output
        end
    end

    draw_triangle #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(draw_oe),
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x2(vx2),
        .y2(vy2),
        .x(fbx),
        .y(fby),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .complete(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    // write to framebuffer when drawing
    always_comb fb_we = drawing;

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_p1;
        vga_vsync <= vsync_p1;
        vga_r <= fb_red;
        vga_g <= fb_green;
        vga_b <= fb_blue;
    end
endmodule
