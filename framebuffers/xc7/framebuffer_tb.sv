// Project F: Framebuffers - Framebuffer Test Bench (XC7)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module framebuffer_tb();

    parameter CLK_PERIOD_100M = 10;  // 10 ns == 100 MHz
    parameter CLK_PERIOD_25M  = 40;  // 40 ns == 25 MHz

    logic rst;
    logic clk_25m;
    logic clk_100m;

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
    display_timings  #(
        .H_RES(H_RES),  // horizontal resolution (pixels)
        .V_RES(V_RES),  // vertical resolution (lines)
        .H_FP(2),       // horizontal front porch
        .H_SYNC(2),     // horizontal sync
        .H_BP(4),       // horizontal back porch
        .V_FP(1),       // vertical front porch
        .V_SYNC(1),     // vertical sync
        .V_BP(2),       // vertical back porch
        .H_POL(0),      // horizontal sync polarity (0:neg, 1:pos)
        .V_POL(0)       // vertical sync polarity (0:neg, 1:pos)
    ) timings_24x18 (
        .clk_pix(clk_25m),
        .rst,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

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

    // draw a horizontal line at the top of the framebuffer
    always @(posedge clk_100m) begin
        if (!rst) begin
            if (fb_we == 0 && fbx != FB_WIDTH-1) begin
                fb_cidx <= 4'h7;  // palette index
                fby <= 1;  // second line
                fb_we <= 1;
            end else if (fbx != FB_WIDTH-1) begin
                fbx <= fbx + 1;
            end else begin
                fb_we <= 0;
            end
        end else fbx <= -2;  // test clipping
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
        rst = 1;
        clk_100m = 1;
        clk_25m = 1;
        fb_we = 0;
        fbx = 0;
        fby = 0;

        #100 rst = 0;

        #100000 $finish;
    end
endmodule
