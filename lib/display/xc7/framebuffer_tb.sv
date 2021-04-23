// Project F Library - Framebuffer Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module framebuffer_tb();

    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    logic clk_25m;
    logic clk_100m;
    logic rst_sys;  // clk_100m domain
    logic rst_pix;  // clk_25m domain

    // display output signals
    logic disp_hsync;    // horizontal sync
    logic disp_vsync;    // vertical sync
    logic disp_de;       // data enable
    logic [3:0] disp_r;  // 4-bit VGA red
    logic [3:0] disp_g;  // 4-bit VGA green
    logic [3:0] disp_b;  // 4-bit VGA blue

    // display timings
    localparam H_RES = 24;
    localparam V_RES = 18;
    localparam CORDW = 16;
    logic hsync, vsync;
    logic de, frame, line;
    logic signed [CORDW-1:0] sx, sy;
    display_timings_24x18 display_timings_inst (
        .clk_pix(clk_25m),
        .rst(rst_pix),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_25m), .clk_o(clk_100m),
                 .rst_i(rst_pix), .rst_o(rst_sys), .i(frame), .o(frame_sys));

    // framebuffer (FB)
    localparam FB_WIDTH   = 12;
    localparam FB_HEIGHT  = 9;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_IMAGE   = "test_box_12x9.mem";
    localparam FB_PALETTE = "test_palette.mem";
    localparam FB_SCALE   = 2;  // use =1 with fb active = (sy >=0 ....

    logic fb_we;
    logic fb_clip;
    logic signed [CORDW-1:0] fbx, fby;  // framebuffer coordinates
    logic [FB_CIDXW-1:0] fb_cidx;
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display

    // determine when framebuffer is active for display
    logic fb_active;
    always_comb begin
        fb_active = de;
        // fb_active = (sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx < FB_WIDTH);
    end

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
        .clk_pix(clk_25m),
        .rst_sys,
        .rst_pix,
        .de(fb_active),
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        .clip(fb_clip),
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw line across middle of framebuffer
    enum {IDLE, DRAW, DONE} state;
    always @(posedge clk_100m) begin
        case (state)
            DRAW:
                if (fbx < FB_WIDTH-1) begin
                    fbx <= fbx + 1;
                end else begin
                    fb_we <= 0;
                    state <= DONE;
                end
            IDLE:
                if (frame_sys) begin
                    fb_cidx <= 7;
                    fb_we <= 1;
                    fby <= 4;  // draw in the middle(ish)
                    state <= DRAW;
                end
            default: state <= DONE;  // done forever!
        endcase

        if (rst_sys) begin
            fb_we <= 0;
            fbx <= 0;
            fby <= 0;
            state <= IDLE;
        end
    end

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1, de_p1;
    always_ff @(posedge clk_25m) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
        de_p1 <= de;
    end

    // VGA output
    always_ff @(posedge clk_25m) begin
        disp_hsync <= hsync_p1;
        disp_vsync <= vsync_p1;
        disp_de <= de_p1;
        disp_r <= fb_red;
        disp_g <= fb_green;
        disp_b <= fb_blue;
    end

    // generate clocks
    always #(CLK_PERIOD_100M / 2) clk_100m = ~clk_100m;
    always #(CLK_PERIOD_25M / 2) clk_25m = ~clk_25m;

    initial begin
        clk_100m = 1;
        clk_25m = 1;
        rst_sys = 1;
        rst_pix = 1;
        state = IDLE;

        #100
        rst_sys = 0;
        rst_pix = 0;

        #100000 $finish;
    end
endmodule
