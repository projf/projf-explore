// Project F: Simple 3D - Top Cube (Arty Pmod VGA)
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
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        .sy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m),
                 .rst_i(1'b0), .rst_o(1'b0), .i(frame), .o(frame_sys));

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 240;
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
        .de,
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

    // model file
    localparam MODEL_FILE = "cube.mem";  // 7.5 total BRAMs
    localparam LINE_CNT   = 12;  // cube line count

    // model ROM
    localparam ROM_WIDTH = 48;
    localparam ROM_CORDW = 8;
    logic [$clog2(LINE_CNT)-1:0] line_id;  // line identifier
    logic [ROM_WIDTH-1:0] rom_data;
    rom_sync #(
        .WIDTH(ROM_WIDTH),
        .DEPTH(LINE_CNT),
        .INIT_F(MODEL_FILE)
    ) model_rom (
        .clk(clk_100m),
        .addr(line_id),
        .data(rom_data)
    );

    // // sine table ROM
    // localparam SIN_FILE  = "sine_table_16x8.mem";
    // localparam SIN_CNT   = 16;  // number of entries in table
    // localparam SIN_WIDTH = 8;   // width of sine entries in bits
    // logic [$clog2(SIN_CNT)-1:0] sin_id;  // table entry identifier
    // logic [SIN_WIDTH-1:0] sin_data;
    // rom_sync #(
    //     .WIDTH(SIN_WIDTH),
    //     .DEPTH(SIN_CNT),
    //     .INIT_F(SIN_FILE)
    // ) sine_rom (
    //     .clk(clk_100m),
    //     .addr(sin_id),
    //     .data(sin_data)
    // );

    // sine table
    localparam SIN_DEPTH=64;  // entires in sine ROM 0°-90°
    localparam SIN_WIDTH=8;   // width of sine ROM data
    localparam SIN_ADDRW=$clog2(4*SIN_DEPTH);   // full table -180° to +180°
    localparam SIN_FILE="sine_table_64x8.mem";  // file to populate ROM

    logic sin_start, sin_done;
    logic [SIN_ADDRW-1:0] sin_id;
    logic signed [CORDW-1:0] sin_data;
    sine_table #(
        .CORDW(CORDW),
        .ROM_DEPTH(SIN_DEPTH),
        .ROM_WIDTH(SIN_WIDTH),
        .ROM_FILE(SIN_FILE)
    ) sine_table_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(sin_start),
        .id(sin_id),
        .data(sin_data),
        .done(sin_done)
    );

    // draw model in framebuffer
    /* verilator lint_off UNUSED */
    logic [ROM_CORDW-1:0] lx0, ly0, lz0, lx1, ly1, lz1;
    /* verilator lint_on UNUSED */
    logic [CORDW-1:0] x0, y0, x1, y1;  // screen line coords
    logic draw_start, drawing, draw_done;  // draw_line signals

    // rotation intermediates: 16-bit (Q8.8)
    logic [CORDW-1:0] sin_a, cos_a;
    logic signed [2*CORDW-1:0] sin_x0_w, sin_y0_w, cos_x0_w, cos_y0_w;
    logic signed [2*CORDW-1:0] sin_x1_w, sin_y1_w, cos_x1_w, cos_y1_w;
    logic signed [CORDW-1:0] sin_x0, sin_y0, cos_x0, cos_y0;
    logic signed [CORDW-1:0] sin_x1, sin_y1, cos_x1, cos_y1;

    // draw state machine
    enum {IDLE, CLEAR, INIT, SIN, COS, ROT1, ROT2, VIEW, DRAW, DONE} state;
    initial state = IDLE;  // needed for Yosys
    always_ff @(posedge clk_100m) begin
        draw_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                fb_cidx <= 4'h9;  // orange
                {lx0,ly0,lz0,lx1,ly1,lz1} <= rom_data;
                // request sine
                sin_id <= 149;
                sin_start <= 1;
                state <= SIN;
            end
            SIN: begin
                sin_start <= 0;
                if (sin_done) begin
                    sin_a <= sin_data;
                    sin_id <= SIN_DEPTH - sin_id;  // cos(x) = sin(90° - x)
                    sin_start <= 1;
                    state <= COS;
                end
            end
            COS: begin
                sin_start <= 0;
                if (sin_done) begin
                    cos_a <= sin_data;
                    state <= ROT1;
                end
            end
            ROT1: begin
                state <= ROT2;
                sin_x0_w <= lx0 * sin_a;
                sin_y0_w <= ly0 * sin_a;
                cos_x0_w <= lx0 * cos_a;
                cos_y0_w <= ly0 * cos_a;
                sin_x1_w <= lx1 * sin_a;
                sin_y1_w <= ly1 * sin_a;
                cos_x1_w <= lx1 * cos_a;
                cos_y1_w <= ly1 * cos_a;
            end
            ROT2: begin
                state <= VIEW;
                sin_x0 <= sin_x0_w[23:8];
                sin_y0 <= sin_y0_w[23:8];
                cos_x0 <= cos_x0_w[23:8];
                cos_y0 <= cos_y0_w[23:8];
                sin_x1 <= sin_x1_w[23:8];
                sin_y1 <= sin_y1_w[23:8];
                cos_x1 <= cos_x1_w[23:8];
                cos_y1 <= cos_y1_w[23:8];
            end
            VIEW: begin
                draw_start <= 1;
                state <= DRAW;
                x0 <= cos_x0 - sin_y0;
                y0 <= FB_HEIGHT - (cos_y0 + sin_x0);  // 3D models draw up the screen
                x1 <= cos_x1 - sin_y1;
                y1 <= FB_HEIGHT - (cos_y1 + sin_x1);
            end
            DRAW: if (draw_done) begin
                if (line_id == LINE_CNT-1) begin
                    state <= DONE;
                end else begin
                    line_id <= line_id + 1;
                    state <= INIT;
                end
            end
            DONE: state <= DONE;
            default: if (frame_sys) state <= INIT;  // IDLE
        endcase
    end

    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(1'b1),
        .x0,
        .y0,
        .x1,
        .y1,
        .x(fbx),
        .y(fby),
        .drawing,
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
