// Project F: Simple 3D - Top Cube (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_cube (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    input  wire logic btn_inc,      // increase button (BTN0)
    input  wire logic btn_dec,      // decrease button (BTN1)
    input  wire logic btn_axis,     // axis button (BTN2)
    input  wire logic btn_view,     // view button (BTN3)
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

    // debounce buttons
    logic sig_inc, sig_dec, sig_axis, sig_view;
    /* verilator lint_off PINCONNECTEMPTY */
    debounce deb_inc
        (.clk(clk_100m), .in(btn_inc), .out(), .ondn(), .onup(sig_inc));
    debounce deb_dec
        (.clk(clk_100m), .in(btn_dec), .out(), .ondn(), .onup(sig_dec));
    debounce deb_axis
        (.clk(clk_100m), .in(btn_axis), .out(), .ondn(), .onup(sig_axis));
    debounce deb_view
        (.clk(clk_100m), .in(btn_view), .out(), .ondn(), .onup(sig_view));
    /* verilator lint_on PINCONNECTEMPTY */

    // framebuffer (FB)
    localparam FB_WIDTH   = 320;
    localparam FB_HEIGHT  = 240;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 2;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "16_colr_4bit_palette.mem";

    logic fb_we, fb_wready;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    framebuffer_db #(
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
        .bgidx(4'b0),
        .clear(1),  // enable clearing of buffer before drawing
        .wready(fb_wready),
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

    localparam ANGLEW=8;  // angle width in bits
    logic [ANGLEW-1:0] angle;
    logic [1:0] axis;  // consider making enum
    logic [1:0] view;  // consider making enum
    logic [CORDW-1:0] rot_x, rot_y, rot_z;
    logic [CORDW-1:0] rot_xr, rot_yr, rot_zr;
    logic rot_start, rot_done;

    rotate #(.CORDW(CORDW), .ANGLEW(ANGLEW)) rotate_inst (
        .clk(clk_100m),     // clock
        .rst(1'b0),         // reset
        .start(rot_start),  // start rotation
        .axis,              // axis (none=00, x=01, y=10, z=11)
        .angle,             // rotation angle
        .x(rot_x),          // x coord in
        .y(rot_y),          // y coord in
        .z(rot_z),          // z coord in
        .xr(rot_xr),        // rotated x coord
        .yr(rot_yr),        // rotated y coord
        .zr(rot_zr),        // rotated z coord
        .done(rot_done)     // rotation complete (high for one tick)
    );

    // draw model in framebuffer
    logic [ROM_CORDW-1:0] lx0, ly0, lz0, lx1, ly1, lz1;  // line coords
    /* verilator lint_off UNUSED */
    logic [CORDW-1:0] x0, y0, z0, x1, y1, z1;  // rotated line coords
    /* verilator lint_on UNUSED */
    logic [CORDW-1:0] xv0, yv0, xv1, yv1;  // view coords
    logic draw_start, drawing, draw_done;  // draw_line signals

    // set angle and rotation axis using buttons
    always_ff @(posedge clk_100m) begin
        if (sig_axis) axis <= (axis == 2'b10) ? 2'b0 : axis + 1;
        if (sig_view) view <= (view == 2'b10) ? 2'b0 : view + 1;
        if (sig_inc) angle <= angle + 1;
        if (sig_dec) angle <= angle - 1;
    end

    // draw state machine
    enum {IDLE, INIT, RAM_WAIT, LOAD, VIEW, DRAW, DONE,
          ROT_INIT, ROT_0, ROT_1} state;
    always_ff @(posedge clk_100m) begin
        draw_start <= 0;
        rot_start <= 0;
        case (state)
            INIT: begin  // register coordinates and colour
                fb_cidx <= 4'h9;  // orange
                line_id <= 0;
                state <= RAM_WAIT;
            end
            RAM_WAIT: state <= LOAD;  // allow a cycle for ram
            LOAD: begin  // register coordinates and colour
                {lx0,ly0,lz0,lx1,ly1,lz1} <= rom_data;
                state <= ROT_INIT;
            end
            ROT_INIT: begin
                // rotation corrds (x0,y0,z0)
                rot_x <= {lx0,8'b0};
                rot_y <= {ly0,8'b0};
                rot_z <= {lz0,8'b0};
                rot_start <= 1;
                state <= ROT_0;
            end
            ROT_0: if (rot_done) begin
                // save rotated (x0,y0,z0)
                x0 <= rot_xr >>> 8;
                y0 <= rot_yr >>> 8;
                z0 <= rot_zr >>> 8;
                // rotation corrds (x1,y1,z1)
                rot_x <= {lx1,8'b0};
                rot_y <= {ly1,8'b0};
                rot_z <= {lz1,8'b0};
                rot_start <= 1;
                state <= ROT_1;
            end
            ROT_1: if (rot_done) begin
                // save rotated (x1,y1,z1)
                x1 <= rot_xr >>> 8;
                y1 <= rot_yr >>> 8;
                z1 <= rot_zr >>> 8;
                state <= VIEW;
            end
            VIEW: begin
                // select which orientation to view XY YZ ZX
                draw_start <= 1;
                state <= DRAW;
                case (view)
                    2'b00: begin  // XY
                        xv0 <= x0;
                        yv0 <= FB_HEIGHT - y0;  // 3D models draw up the screen
                        xv1 <= x1;
                        yv1 <= FB_HEIGHT - y1;
                    end
                    2'b01: begin  // YZ
                        xv0 <= FB_HEIGHT - y0;
                        yv0 <= z0;
                        xv1 <= FB_HEIGHT - y1;
                        yv1 <= z1;
                    end
                    default: begin  // ZX
                        xv0 <= z0;
                        yv0 <= x0;
                        xv1 <= z1;
                        yv1 <= x1;
                    end
                endcase
            end
            DRAW: if (draw_done) begin
                if (line_id == LINE_CNT-1) begin
                    state <= DONE;
                end else begin
                    line_id <= line_id + 1;
                    state <= RAM_WAIT;
                end
            end
            default: if (frame_sys) begin  // IDLE or DONE
                state <= INIT;
            end
        endcase
    end

    draw_line #(.CORDW(CORDW)) draw_line_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(fb_wready),
        .x0(xv0),
        .y0(yv0),
        .x1(xv1),
        .y1(yv1),
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