// Project F: Animated Shapes - Top Rotate (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_rotate (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    input  wire logic btn_inc,      // increase button (BTN0)
    input  wire logic btn_dec,      // decrease button (BTN1)
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

    // debounce buttons
    logic sig_inc, sig_dec;
    /* verilator lint_off PINCONNECTEMPTY */
    debounce deb_inc
        (.clk(clk_100m), .in(btn_inc), .out(), .ondn(), .onup(sig_inc));
    debounce deb_dec
        (.clk(clk_100m), .in(btn_dec), .out(), .ondn(), .onup(sig_dec));
    /* verilator lint_on PINCONNECTEMPTY */

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 180;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 2;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";
    localparam FB_BGIDX   = 4'h1;  // background colour index

    logic fb_we, fb_busy, fb_wready;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    framebuffer_bram_db #(
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
        .bgidx(FB_BGIDX),
        .clear(1'b1),  // enable clearing of buffer before drawing
        .busy(fb_busy),
        .wready(fb_wready),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // shape rotation
    localparam ANGLEW=8;  // angle width in bits
    logic [ANGLEW-1:0] angle;
    logic [CORDW-1:0] rot_xi, rot_yi;
    logic [CORDW-1:0] rot_x, rot_y;
    logic rot_start, rot_done;

    // set angle using buttons
    always_ff @(posedge clk_100m) begin
        if (sig_inc) angle <= angle + 1;
        if (sig_dec) angle <= angle - 1;
    end

    rotate_xy #(.CORDW(CORDW), .ANGLEW(ANGLEW)) rotate_xy_inst (
        .clk(clk_100m),     // clock
        .rst(1'b0),         // reset
        .start(rot_start),  // start rotation
        .angle,             // rotation angle
        .xi(rot_xi),        // x coord in
        .yi(rot_yi),        // y coord in
        .x(rot_x),          // rotated x coord
        .y(rot_y),          // rotated y coord
        .done(rot_done)     // rotation complete (high for one tick)
    );

    // draw triangles in framebuffer
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic signed [CORDW-1:0] offs_x, offs_y;  // offset

    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, ROT_INIT, ROT_0, ROT_1, ROT_2, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        rot_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                if (fb_wready) begin
                    state <= ROT_INIT;
                    vx0 <=   0; vy0 <= -60;
                    vx1 <= -40; vy1 <=  20;
                    vx2 <= 100; vy2 <=  80;
                    offs_x <= 140; offs_y <= 80;
                    fb_cidx <= 4'h9;  // orange
                end
            end
            ROT_INIT: begin
                // rotation coords (tx0,ty0)
                rot_xi <= vx0;
                rot_yi <= vy0;
                rot_start <= 1;
                state <= ROT_0;
            end
            ROT_0: if (rot_done) begin
                // save rotated (tx0,ty0) with translate
                vx0 <= rot_x + offs_x;
                vy0 <= rot_y + offs_y;
                // rotation coords (tx1,ty1)
                rot_xi <= vx1;
                rot_yi <= vy1;
                rot_start <= 1;
                state <= ROT_1;
            end
            ROT_1: if (rot_done) begin
                // save rotated (tx1,ty1) with translate
                vx1 <= rot_x + offs_x;
                vy1 <= rot_y + offs_y;
                // rotation coords (tx2,ty2)
                rot_xi <= vx2;
                rot_yi <= vy2;
                rot_start <= 1;
                state <= ROT_2;
            end
            ROT_2: if (rot_done) begin
                // save rotated (tx2,ty2) with translate
                vx2 <= rot_x + offs_x;
                vy2 <= rot_y + offs_y;
                draw_start <= 1;
                state <= DRAW;
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) state <= DONE;
            end
            DONE: state <= IDLE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!fb_busy),  // draw when framebuffer is available
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
        .busy(),
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
