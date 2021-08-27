// Project F: 2D Shapes - Top Castle (iCEBreaker 12-bit DVI Pmod)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_castle (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    output      logic dvi_clk,      // DVI pixel clock
    output      logic dvi_hsync,    // DVI horizontal sync
    output      logic dvi_vsync,    // DVI vertical sync
    output      logic dvi_de,       // DVI data enable
    output      logic [3:0] dvi_r,  // 4-bit DVI red
    output      logic [3:0] dvi_g,  // 4-bit DVI green
    output      logic [3:0] dvi_b   // 4-bit DVI blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 180;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 2;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "../res/palette/16_colr_4bit_palette.mem";

    logic fb_we;  // write enable
    logic signed [CORDW-1:0] fbx, fby;  // draw coordinates
    logic [FB_CIDXW-1:0] fb_cidx;  // draw colour index
    logic fb_busy;  // when framebuffer is busy it cannot accept writes
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display output

    framebuffer_spram #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_pix),
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
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .busy(fb_busy),
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw shapes in framebuffer
    localparam SHAPE_CNT=19;  // number of shapes to draw
    logic [$clog2(SHAPE_CNT)-1:0] shape_id;  // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic signed [CORDW-1:0] fbx_tri, fby_tri;    // tri framebuffer coordinates
    logic signed [CORDW-1:0] fbx_rect, fby_rect;  // rect framebuffer coordinates
    logic drawing, draw_done;  // combined drawing signals
    logic draw_start_tri, drawing_tri, draw_done_tri;  // drawing tri
    logic draw_start_rect, drawing_rect, draw_done_rect;  // drawing rect

    // clear FB before use (contents are not initialized)
    logic signed [CORDW-1:0] fbx_clear, fby_clear;  // framebuffer clearing coordinates
    logic clearing;  // high when we're clearing

    // draw state machine
    enum {IDLE, CLEAR, INIT, DRAW, DONE} state;
    always_ff @(posedge clk_pix) begin
        case (state)
            CLEAR: begin  // we need to initialize SPRAM values to zero
                fb_cidx <= 4'h0;  // black
                if (!fb_busy) begin
                    if (fby_clear == FB_HEIGHT-1 && fbx_clear == FB_WIDTH-1) begin
                        clearing <= 0;
                        state <= INIT;
                    end else begin  // iterate over all pixels
                        if (clearing == 1) begin
                            if (fbx_clear == FB_WIDTH-1) begin
                                fbx_clear <= 0;
                                fby_clear <= fby_clear + 1;
                            end else begin
                                fbx_clear <= fbx_clear + 1;
                            end
                        end else clearing <= 1;
                    end
                end
            end
            INIT: begin  // register coordinates and colour
                state <= DRAW;
                case (shape_id)
                    5'd0: begin  // main building
                        draw_start_rect <= 1;
                        vx0 <=  60; vy0 <=  70;
                        vx1 <= 190; vy1 <= 120;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd1: begin  // drawbridge
                        draw_start_rect <= 1;
                        vx0 <= 110; vy0 <=  90;
                        vx1 <= 140; vy1 <= 120;
                        fb_cidx <= 4'h4;  // brown
                    end
                    5'd2: begin  // arch left
                        draw_start_tri <= 1;
                        vx0 <= 110; vy0 <=  90;
                        vx1 <= 120; vy1 <=  90;
                        vx2 <= 110; vy2 <= 100;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd3: begin  // arch right
                        draw_start_tri <= 1;
                        vx0 <= 130; vy0 <=  90;
                        vx1 <= 140; vy1 <=  90;
                        vx2 <= 140; vy2 <= 100;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd4: begin  // left tower
                        draw_start_rect <= 1;
                        vx0 <=  40; vy0 <=  45;
                        vx1 <=  60; vy1 <= 120;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd5: begin  // middle tower
                        draw_start_rect <= 1;
                        vx0 <= 110; vy0 <=  40;
                        vx1 <= 140; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd6: begin  // right tower
                        draw_start_rect <= 1;
                        vx0 <= 190; vy0 <=  45;
                        vx1 <= 210; vy1 <= 120;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd7: begin  // left roof
                        draw_start_tri <= 1;
                        vx0 <=  50; vy0 <=  30;
                        vx1 <=  65; vy1 <=  45;
                        vx2 <=  35; vy2 <=  45;
                        fb_cidx <= 4'h2;  // dark-purple
                    end
                    5'd8: begin  // middle roof
                        draw_start_tri <= 1;
                        vx0 <= 125; vy0 <=  20;
                        vx1 <= 145; vy1 <=  40;
                        vx2 <= 105; vy2 <=  40;
                        fb_cidx <= 4'h2;  // dark-purple
                    end
                    5'd9: begin  // right roof
                        draw_start_tri <= 1;
                        vx0 <= 200; vy0 <=  30;
                        vx1 <= 215; vy1 <=  45;
                        vx2 <= 185; vy2 <=  45;
                        fb_cidx <= 4'h2;  // dark-purple
                    end
                    5'd10: begin  // left window
                        draw_start_rect <= 1;
                        vx0 <=  46; vy0 <=  50;
                        vx1 <=  54; vy1 <=  65;
                        fb_cidx <= 4'h1;  // dark blue
                    end
                    5'd11: begin  // middle window
                        draw_start_rect <= 1;
                        vx0 <= 120; vy0 <=  45;
                        vx1 <= 130; vy1 <=  65;
                        fb_cidx <= 4'h1;  // dark blue
                    end
                    5'd12: begin  // right window
                        draw_start_rect <= 1;
                        vx0 <= 196; vy0 <=  50;
                        vx1 <= 204; vy1 <=  65;
                        fb_cidx <= 4'h1;  // dark blue
                    end
                    5'd13: begin  // battlement 1
                        draw_start_rect <= 1;
                        vx0 <=  63; vy0 <=  62;
                        vx1 <=  72; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd14: begin  // battlement 2
                        draw_start_rect <= 1;
                        vx0 <=   80; vy0 <=  62;
                        vx1 <=   89; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd15: begin  // battlement 3
                        draw_start_rect <= 1;
                        vx0 <=  97; vy0 <=  62;
                        vx1 <= 106; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd16: begin  // battlement 4
                        draw_start_rect <= 1;
                        vx0 <= 144; vy0 <=  62;
                        vx1 <= 153; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd17: begin  // battlement 5
                        draw_start_rect <= 1;
                        vx0 <= 161; vy0 <=  62;
                        vx1 <= 170; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    5'd18: begin  // battlement 6
                        draw_start_rect <= 1;
                        vx0 <= 178; vy0 <=  62;
                        vx1 <= 187; vy1 <=  70;
                        fb_cidx <= 4'h5;  // dark grey
                    end
                    default: begin  // should never occur
                        draw_start_tri <= 1;
                        vx0 <=   10; vy0 <=   10;
                        vx1 <=   10; vy1 <=   30;
                        vx2 <=   20; vy2 <=   20;
                        fb_cidx <= 4'h7;  // white
                    end
                endcase
            end
            DRAW: begin
                draw_start_rect <= 0;
                draw_start_tri <= 0;
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
            default: if (frame) state <= CLEAR;  // IDLE
        endcase
        if (!clk_locked) state <= IDLE;
    end

    // drawing and done apply to either shape
    always_comb begin
        drawing = drawing_tri || drawing_rect;
        draw_done = draw_done_tri || draw_done_rect;
    end

    // control drawing speed with output enable
    localparam FRAME_WAIT = 300;  // wait this many frames to start drawing
    localparam PIX_FRAME  =  20;  // draw this many pixels per frame
    logic [$clog2(FRAME_WAIT)-1:0] cnt_frame_wait;
    logic [$clog2(PIX_FRAME)-1:0] cnt_pix_frame;
    logic draw_req;
    always_ff @(posedge clk_pix) begin
        draw_req <= 0;
        if (frame) begin
            if (cnt_frame_wait != FRAME_WAIT-1) cnt_frame_wait <= cnt_frame_wait + 1;
            cnt_pix_frame <= 0;  // reset pixel counter every frame
        end
        if (!fb_busy) begin
            if (cnt_frame_wait == FRAME_WAIT-1 && cnt_pix_frame != PIX_FRAME-1) begin
                draw_req <= 1;
                cnt_pix_frame <= cnt_pix_frame + 1;
            end
        end
    end

    draw_triangle_fill #(.CORDW(CORDW)) draw_triangle_inst (
        .clk(clk_pix),
        .rst(!clk_locked),  // must be reset for draw with Yosys
        .start(draw_start_tri),
        .oe(draw_req && !fb_busy),  // draw if requested when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x2(vx2),
        .y2(vy2),
        .x(fbx_tri),
        .y(fby_tri),
        .drawing(drawing_tri),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_tri)
    );

    draw_rectangle_fill #(.CORDW(CORDW)) draw_rectangle_inst (
        .clk(clk_pix),
        .rst(!clk_locked),  // must be reset for draw with Yosys
        .start(draw_start_rect),
        .oe(draw_req && !fb_busy),  // draw if requested when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .x1(vx1),
        .y1(vy1),
        .x(fbx_rect),
        .y(fby_rect),
        .drawing(drawing_rect),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done_rect)
    );

    // write to framebuffer when drawing
    always_ff @(posedge clk_pix) begin
        fb_we <= drawing || clearing;
        fbx <= clearing ? fbx_clear : drawing_tri ? fbx_tri : fbx_rect;
        fby <= clearing ? fby_clear : drawing_tri ? fby_tri : fby_rect;
    end

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

    // background colour (sy ignores 16:9 letterbox)
    logic [11:0] bg_colr;
    always_ff @(posedge clk_pix) begin
        if (line) begin
            if      (sy ==   0) bg_colr <= 12'h000;
            else if (sy ==  60) bg_colr <= 12'h239;
            else if (sy == 130) bg_colr <= 12'h24A;
            else if (sy == 175) bg_colr <= 12'h25B;
            else if (sy == 210) bg_colr <= 12'h26C;
            else if (sy == 240) bg_colr <= 12'h27D;
            else if (sy == 265) bg_colr <= 12'h29E;
            else if (sy == 285) bg_colr <= 12'h2BF;
            else if (sy == 302) bg_colr <= 12'h260;  // below castle (2x pix)
            else if (sy == 420) bg_colr <= 12'h000;
        end
    end

    logic show_bg;
    always_comb show_bg = (de && {fb_red,fb_green,fb_blue} == 0);

    // Output DVI clock: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );

    // Output DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync, dvi_vsync, dvi_de, dvi_r, dvi_g, dvi_b}),
        .OUTPUT_CLK(clk_pix),
        .D_OUT_0({hsync_p1, vsync_p1, de_p1, 
            show_bg ? bg_colr[11:8] : fb_red, 
            show_bg ? bg_colr[7:4]  : fb_green,
            show_bg ? bg_colr[3:0]  : fb_blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
