// Project F: Simple 3D - Top Icosphere (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_icosphere (
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
    localparam MODEL_FILE = "icosphere.mem";  // 8.5 total BRAMs
    localparam LINE_CNT   = 120;  // icosphere line count

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

    // draw model in framebuffer
    /* verilator lint_off UNUSED */
    logic [ROM_CORDW-1:0] lx0, ly0, lz0, lx1, ly1, lz1;
    /* verilator lint_on UNUSED */
    logic [CORDW-1:0] x0, y0, x1, y1;  // screen line coords
    logic draw_start, drawing, draw_done;  // draw_line signals

    // draw state machine
    enum {IDLE, INIT, RAM_WAIT, LOAD, VIEW, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        draw_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                fb_cidx <= 4'h9;  // orange
                line_id <= 0;
                state <= RAM_WAIT;
            end
            RAM_WAIT: state <= LOAD;  // allow a cycle for ram
            LOAD: begin  // register coordinates and colour
                {lx0,ly0,lz0,lx1,ly1,lz1} <= rom_data;
                state <= VIEW;
            end
            VIEW: begin  // select view - map world coords to screen coords
                draw_start <= 1;
                state <= DRAW;
                x0 <= {8'b0,lx0};
                y0 <= FB_HEIGHT-{8'b0,ly0}; // 3D models draw up the screen
                x1 <= {8'b0,lx1};
                y1 <= FB_HEIGHT-{8'b0,ly1};
            end
            DRAW: if (draw_done) begin
                if (line_id == LINE_CNT-1) begin
                    state <= DONE;
                end else begin
                    line_id <= line_id + 1;
                    state <= RAM_WAIT;
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
