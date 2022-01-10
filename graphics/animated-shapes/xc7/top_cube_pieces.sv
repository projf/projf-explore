// Project F: Animated Shapes - Top Cube Pieces (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_cube_pieces (
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
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

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
        .bgidx(4'h0),
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

    // animate triangle coordinates
    localparam MAX_OFFS   = 32;  // maximum pixels to move
    localparam ANIM_SPEED =  1;  // pixel to move per frame
    localparam FRAME_WAIT = 60;  // frames to pause between change of direction
    logic [CORDW-1:0] offs;      // animation offset
    logic [$clog2(FRAME_WAIT)-1:0] cnt_frame_wait;
    logic dir;  // direction: 1 is increasing offset
    enum {START, MOVE, WAIT} anim_state;
    always_ff @(posedge clk_100m) begin
        if (frame_sys) begin
            case (anim_state)
                MOVE: begin
                    offs <= (dir == 1) ? offs + ANIM_SPEED : offs - ANIM_SPEED;
                    if ((dir == 1 && offs >= MAX_OFFS-ANIM_SPEED) ||
                        (dir == 0 && offs <= ANIM_SPEED)) begin
                        cnt_frame_wait <= 0;
                        anim_state <= WAIT;
                    end
                end
                WAIT: begin
                    if (cnt_frame_wait == FRAME_WAIT-1) begin
                        anim_state <= MOVE;
                        dir <= ~dir;  // change direction
                    end else cnt_frame_wait <= cnt_frame_wait + 1;
                end
                default: anim_state <= WAIT;  // START
            endcase
        end
    end

    // draw triangles in framebuffer
    localparam SHAPE_CNT=6;  // number of shapes to draw
    logic [2:0] shape_id;    // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, INIT, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            INIT: begin  // register coordinates and colour
                if (fb_wready) begin
                    draw_start <= 1;
                    state <= DRAW;
                    case (shape_id)
                        3'd0: begin  // moves in from right
                            vx0 <= 130 + offs; vy0 <=  60;
                            vx1 <= 230 + offs; vy1 <=  60;
                            vx2 <= 230 + offs; vy2 <= 160;
                            fb_cidx <= (offs == 0) ? 4'h9 : 4'hA;  // orange or yellow
                        end
                        3'd1: begin  // moves in from bottom-right
                            vx0 <= 130 + offs; vy0 <=  60 + offs;
                            vx1 <= 230 + offs; vy1 <= 160 + offs;
                            vx2 <= 130 + offs; vy2 <= 160 + offs;
                            fb_cidx <= (offs == 0) ? 4'h9 : 4'hA;  // orange or yellow
                        end
                        3'd2: begin  // moves in from bottom-left
                            vx0 <= 130 - offs; vy0 <=  60 + offs;
                            vx1 <=  90 - offs; vy1 <= 120 + offs;
                            vx2 <= 130 - offs; vy2 <= 160 + offs;
                            fb_cidx <= (offs == 0) ? 4'h2 : 4'hD;  // dark purple or indigo
                        end
                        3'd3: begin  // moves in from left
                            vx0 <=  90 - offs; vy0 <=  20;
                            vx1 <= 130 - offs; vy1 <=  60;
                            vx2 <=  90 - offs; vy2 <= 120;
                            fb_cidx <= (offs == 0) ? 4'h2 : 4'hD;  // dark purple or indigo
                        end
                        3'd4: begin  // moves in from top
                            vx0 <=  90; vy0 <=  20 - offs;
                            vx1 <= 190; vy1 <=  20 - offs;
                            vx2 <= 130; vy2 <=  60 - offs;
                            fb_cidx <= (offs == 0) ? 4'h1 : 4'hC;  // dark blue or blue
                        end
                        3'd5: begin  // moves in from top-right
                            vx0 <= 190 + offs; vy0 <=  20 - offs;
                            vx1 <= 130 + offs; vy1 <=  60 - offs;
                            vx2 <= 230 + offs; vy2 <=  60 - offs;
                            fb_cidx <= (offs == 0) ? 4'h1 : 4'hC;  // dark blue or blue
                        end
                        default: begin  // should never occur
                            vx0 <=   10; vy0 <=   10;
                            vx1 <=   10; vy1 <=   30;
                            vx2 <=   20; vy2 <=   20;
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
            DONE: state <= IDLE;  // idle ready for the next frame
            default: if (frame_sys) begin  // IDLE
                shape_id <= 0;
                state <= INIT;
            end
        endcase
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!fb_busy),  // draw when framebuffer isn't busy
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
