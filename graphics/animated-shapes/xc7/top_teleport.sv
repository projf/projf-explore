// Project F: Animated Shapes - Top Teleport (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_teleport (
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

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_locked),
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
    localparam FB_PALETTE = "teleport_16_colr_4bit_palette.mem";

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
        .clk_pix(clk_pix),
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de(sy >= 60 && sy < 420 && sx >= 0),  // 16:9 letterbox
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        .bgidx(4'h0),
        .clear(1'b0),  // teleport doesn't need clearing
        .busy(fb_busy),
        .wready(fb_wready),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // animation steps
    localparam ANIM_CNT=5;    // five different frames in animation
    localparam ANIM_SPEED=4;  // display each animation step four times (15 FPS)
    logic [$clog2(ANIM_CNT)-1:0] cnt_anim;
    logic [$clog2(ANIM_SPEED)-1:0] cnt_anim_speed;
    logic [FB_CIDXW-1:0] colr_offs;  // colour offset
    always_ff @(posedge clk_100m) begin
        if (frame_sys) begin
            /* verilator lint_off WIDTH */
            if (cnt_anim_speed == ANIM_SPEED-1) begin
                if (cnt_anim == ANIM_CNT-1) begin
            /* verilator lint_on WIDTH */
                    cnt_anim <= 0;
                    colr_offs <= colr_offs + 1;
                end else cnt_anim <= cnt_anim + 1;
                cnt_anim_speed <= 0;
            end else cnt_anim_speed <= cnt_anim_speed + 1;
        end
    end

    // draw squares in framebuffer
    localparam SHAPE_CNT=7;  // number of shapes to draw
    logic [3:0] shape_id;    // shape identifier
    logic [CORDW-1:0] dx0, dy0, dx1, dy1;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, CLEAR, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            INIT: begin  // register coordinates and colour
                if (fb_wready) begin
                    draw_start <= 1;
                    state <= DRAW;
                    case (shape_id)
                        4'd0: begin  // 12 pixels per anim step
                            dx0 <=  40 - (cnt_anim * 12);
                            dy0 <=   0 - (cnt_anim * 12);
                            dx1 <= 279 + (cnt_anim * 12);
                            dy1 <= 249 + (cnt_anim * 12);
                            fb_cidx <= colr_offs;
                        end
                        4'd1: begin  // 8 pixels per anim step
                            dx0 <=  80 - (cnt_anim * 8);
                            dy0 <=  10 - (cnt_anim * 8);
                            dx1 <= 239 + (cnt_anim * 8);
                            dy1 <= 169 + (cnt_anim * 8);
                            fb_cidx <= colr_offs + 1;
                        end
                        4'd2: begin  // 5 pixels per anim step
                            dx0 <= 105 - (cnt_anim * 5);
                            dy0 <=  35 - (cnt_anim * 5);
                            dx1 <= 214 + (cnt_anim * 5);
                            dy1 <= 144 + (cnt_anim * 5);
                            fb_cidx <= colr_offs + 2;
                        end
                        4'd3: begin  // 4 pixels per anim step
                            dx0 <= 125 - (cnt_anim * 4);
                            dy0 <=  55 - (cnt_anim * 4);
                            dx1 <= 194 + (cnt_anim * 4);
                            dy1 <= 124 + (cnt_anim * 4);
                            fb_cidx <= colr_offs + 3;
                        end
                        4'd4: begin  // 3 pixels per anim step
                            dx0 <= 140 - (cnt_anim * 3);
                            dy0 <=  70 - (cnt_anim * 3);
                            dx1 <= 179 + (cnt_anim * 3);
                            dy1 <= 109 + (cnt_anim * 3);
                            fb_cidx <= colr_offs + 4;
                        end
                        4'd5: begin  // 2 pixels per anim step
                            dx0 <= 150 - (cnt_anim * 2);
                            dy0 <=  80 - (cnt_anim * 2);
                            dx1 <= 169 + (cnt_anim * 2);
                            dy1 <=  99 + (cnt_anim * 2);
                            fb_cidx <= colr_offs + 5;
                        end
                        4'd6: begin  // 1 pixel per anim step
                            dx0 <= 155 - (cnt_anim * 1);
                            dy0 <=  85 - (cnt_anim * 1);
                            dx1 <= 164 + (cnt_anim * 1);
                            dy1 <=  94 + (cnt_anim * 1);
                            fb_cidx <= colr_offs + 6;
                        end
                        default: begin  // should never occur
                            dx0 <=  10; dy0 <=  10;
                            dx1 <=  20; dy1 <=  20;
                            fb_cidx <= 4'h7;  // white
                        end
                    endcase
                end
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
            DONE: state <= IDLE;
            default: if (frame_sys) begin  // IDLE
                state <= INIT;
                shape_id <= 0;
            end
        endcase
    end

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!fb_busy),  // draw when framebuffer isn't busy
        .x0(dx0),
        .y0(dy0),
        .x1(dx1),
        .y1(dy1),
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
