// Project F: 2D Shapes - Top Circles (iCEBreaker 12-bit DVI Pmod)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_circles (
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

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix(!clk_locked),
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

    // draw circles in framebuffer
    localparam SHAPE_CNT=8;  // number of shapes to draw
    logic [$clog2(SHAPE_CNT):0] shape_id;  // shape identifier
    logic signed [CORDW-1:0] vx0, vy0, vr0;  // shape coords
    logic draw_start, drawing, draw_done;  // drawing signals

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
                draw_start <= 1;
                state <= DRAW;
                vx0 <= 160;
                vy0 <=  90;
                vr0 <=  80 - 4 * shape_id;
                fb_cidx <= 4'hC;  // blue
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
            default: if (frame) state <= CLEAR;  // IDLE
        endcase
        if (!clk_locked) state <= IDLE;
    end

    // control drawing speed with output enable
    localparam FRAME_WAIT = 300;  // wait this many frames to start drawing
    localparam PIX_FRAME  =  30;  // draw this many pixels per frame
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

    logic signed [CORDW-1:0] fbx_draw, fby_draw;  // framebuffer drawing coordinates
    draw_circle #(.CORDW(CORDW)) draw_circle_inst (
        .clk(clk_pix),
        .rst(!clk_locked),  // must be reset for draw with Yosys
        .start(draw_start),
        .oe(draw_req && !fb_busy),  // draw if requested when framebuffer is available
        .x0(vx0),
        .y0(vy0),
        .r0(vr0),
        .x(fbx_draw),
        .y(fby_draw),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    // write to framebuffer when drawing or clearing
    always_ff @(posedge clk_pix) begin
        fb_we <= drawing || clearing;
        fbx <= clearing ? fbx_clear : fbx_draw;
        fby <= clearing ? fby_clear : fby_draw;
    end

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

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
        .D_OUT_0({hsync_p1, vsync_p1, de_p1, fb_red, fb_green, fb_blue}),
        /* verilator lint_off PINCONNECTEMPTY */
        .D_OUT_1()
        /* verilator lint_on PINCONNECTEMPTY */
    );
endmodule
