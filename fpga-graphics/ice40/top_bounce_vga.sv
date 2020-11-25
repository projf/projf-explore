// Project F: FPGA Graphics - Top Bounce (iCEBreaker with Pmod VGA)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none

module top_bounce_vga (
    input  wire logic clk_12m,      // 12 MHz clock
    input  wire logic btn_rst,      // reset button (active high)
    output      logic vga_hsync,    // VGA horizontal sync
    output      logic vga_vsync,    // VGA vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen clock_640x480 (
       .clk(clk_12m),
       .rst(btn_rst),
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic de;
    display_timings timings_640x480 (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .de
    );

    // size of screen (excluding blanking)
    localparam H_RES = 640;
    localparam V_RES = 480;

    // squares - origin at top-left
    localparam Q1_SIZE = 100;   // square 1 size in pixels
    localparam Q2_SIZE = 150;   // square 2 size in pixels
    localparam Q3_SIZE = 200;   // square 3 size in pixels
    logic [CORDW-1:0] q1x, q1y; // square 1 position
    logic [CORDW-1:0] q2x, q2y; // square 2 position
    logic [CORDW-1:0] q3x, q3y; // square 3 position
    logic q1dx, q1dy;           // square 1 direction: 0 is right/down
    logic q2dx, q2dy;           // square 2 direction: 0 is right/down
    logic q3dx, q3dy;           // square 3 direction: 0 is right/down
    logic [CORDW-1:0] q1s = 3;  // square 1 speed
    logic [CORDW-1:0] q2s = 2;  // square 2 speed
    logic [CORDW-1:0] q3s = 2;  // square 3 speed

    logic animate;  // high for one clock tick at start of blanking
    always_comb animate = (sy == 480 && sx == 0);

    // update square position once per frame
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (q1x >= H_RES - (Q1_SIZE + q1s)) begin  // right edge
                q1dx <= 1;
                q1x <= q1x - q1s;
            end else if (q1x < q1s) begin  // left edge
                q1dx <= 0;
                q1x <= q1x + q1s;
            end else q1x <= (q1dx) ? q1x - q1s : q1x + q1s;

            if (q1y >= V_RES - (Q1_SIZE + q1s)) begin  // bottom edge
                q1dy <= 1;
                q1y <= q1y - q1s;
            end else if (q1y < q1s) begin  // top edge
                q1dy <= 0;
                q1y <= q1y + q1s;
            end else q1y <= (q1dy) ? q1y - q1s : q1y + q1s;

            if (q2x >= H_RES - (Q2_SIZE + q2s)) begin 
                q2dx <= 1;
                q2x <= q2x - q2s;
            end else if (q2x < q2s) begin
                q2dx <= 0;
                q2x <= q2x + q2s;
            end else q2x <= (q2dx) ? q2x - q2s : q2x + q2s;

            if (q2y >= V_RES - (Q2_SIZE + q2s)) begin
                q2dy <= 1;
                q2y <= q2y - q2s;
            end else if (q2y < q2s) begin
                q2dy <= 0;
                q2y <= q2y + q2s;
            end else q2y <= (q2dy) ? q2y - q2s : q2y + q2s;

            if (q3x >= H_RES - (Q3_SIZE + q3s)) begin 
                q3dx <= 1;
                q3x <= q3x - q3s;
            end else if (q3x < q3s) begin
                q3dx <= 0;
                q3x <= q3x + q3s;
            end else q3x <= (q3dx) ? q3x - q3s : q3x + q3s;

            if (q3y >= V_RES - (Q3_SIZE + q3s)) begin
                q3dy <= 1;
                q3y <= q3y - q3s;
            end else if (q3y < q3s) begin
                q3dy <= 0;
                q3y <= q3y + q3s;
            end else q3y <= (q3dy) ? q3y - q3s : q3y + q3s;
        end
    end

    // are any squares at current screen position?
    logic q1_draw, q2_draw, q3_draw;
    always_comb begin
        q1_draw = (sx >= q1x) && (sx < q1x + Q1_SIZE)
              && (sy >= q1y) && (sy < q1y + Q1_SIZE);
        q2_draw = (sx >= q2x) && (sx < q2x + Q2_SIZE)
              && (sy >= q2y) && (sy < q2y + Q2_SIZE);
        q3_draw = (sx >= q3x) && (sx < q3x + Q3_SIZE)
              && (sy >= q3y) && (sy < q3y + Q3_SIZE);
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_r <= (de && q1_draw) ? 4'hF : 4'h0;
        vga_g <= (de && q2_draw) ? 4'hF : 4'h0;
        vga_b <= (de && q3_draw) ? 4'hF : 4'h0;
    end
endmodule
