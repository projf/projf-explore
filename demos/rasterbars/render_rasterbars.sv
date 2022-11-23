// Project F: Rasterbars Render
// (C)2022 Will Green & Ben Blundell, open source hardware released under the MIT License
// From "All You Need" by Chapterhouse released at Revision 2022 (with minor emendations)
// Learn more at https://projectf.io/posts/rasterbars/

`default_nettype none
`timescale 1ns / 1ps

module render_rasterbars #(
    parameter CORDW=16,      // signed coordinate width
    parameter VCENTER=180,   // vertical centre of raster render
    parameter COLR_LINES=3,  // lines of each colour
    parameter SIN_FILE="",   // sine table ROM .mem file
    parameter SIN_SHIFT=0    // right-shift sine values
    ) (
    input  wire logic clk,                    // clock
    input  wire logic start,                  // start control
    input  wire logic line,                   // line signal
    input  wire logic signed [CORDW-1:0] sy,  // vertical position
    output      logic [11:0] bar_colr,        // colour to draw
    output      logic bar_up                  // bar is drawing up
    );

    // sine table
    localparam SIN_DEPTH=64;  // entires in sine ROM 0°-90°
    localparam SIN_WIDTH=8;   // width of sine ROM data
    localparam SIN_ADDRW=$clog2(4*SIN_DEPTH);   // full table -180° to +180°
    logic [SIN_ADDRW-1:0] sin_id, sin_offs;
    logic signed [CORDW-1:0] sin_data;  // sign extend data to match coords
    sine_table #(
        .ROM_DEPTH(SIN_DEPTH),
        .ROM_WIDTH(SIN_WIDTH),
        .ROM_FILE(SIN_FILE)
    ) sine_table_inst (
        .id(sin_id + sin_offs),
        .data(sin_data)
    );

    // raster A
    localparam BASE_COLR_A  = 12'h126;  // bar start colour (blue)
    localparam STEPS_A      = 10;  // colours steps in each bar
    logic [11:0] bar_colr_a;
    logic bar_drawing_a;
    logic signed [CORDW-1:0] bar_y_a;       // screen line to draw at
    logic signed [CORDW-1:0] bar_y_a_prev;  // previous line for direction detection
    logic bar_up_a;  // bar is moving up the screen?

    rasterbar raster_a (
        .clk,
        .start(sy == bar_y_a),
        .line,
        .base_colr(BASE_COLR_A),
        .colr_steps(STEPS_A),
        .colr_lines(COLR_LINES),
        .bar_colr(bar_colr_a),
        .drawing(bar_drawing_a),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // raster B
    localparam BASE_COLR_B  = 12'h640;  // bar start colour (gold)
    localparam STEPS_B      =  10;      // colours steps in each bar
    logic [11:0] bar_colr_b;
    logic bar_drawing_b;
    logic signed [CORDW-1:0] bar_y_b;       // screen line to draw at
    logic signed [CORDW-1:0] bar_y_b_prev;  // previous line for direction detection
    logic bar_up_b;  // bar is moving up the screen?

    rasterbar raster_b (
        .clk,
        .start(sy == bar_y_b),
        .line,
        .base_colr(BASE_COLR_B),
        .colr_steps(STEPS_B),
        .colr_lines(COLR_LINES),
        .bar_colr(bar_colr_b),
        .drawing(bar_drawing_b),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // raster C
    localparam BASE_COLR_C  = 12'h610;  // bar start colour (red)
    localparam STEPS_C      =  10;      // colours steps in each bar
    logic [11:0] bar_colr_c;
    logic bar_drawing_c;
    logic signed [CORDW-1:0] bar_y_c;       // screen line to draw at
    logic signed [CORDW-1:0] bar_y_c_prev;  // previous line for direction detection
    logic bar_up_c;  // bar is moving up the screen?

    rasterbar raster_c (
        .clk,
        .start(sy == bar_y_c),
        .line,
        .base_colr(BASE_COLR_C),
        .colr_steps(STEPS_C),
        .colr_lines(COLR_LINES),
        .bar_colr(bar_colr_c),
        .drawing(bar_drawing_c),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // raster D
    localparam BASE_COLR_D  = 12'h145;  // bar start colour (greenish)
    localparam STEPS_D      =  10;      // colours steps in each bar
    logic [11:0] bar_colr_d;
    logic bar_drawing_d;
    logic signed [CORDW-1:0] bar_y_d;       // screen line to draw at
    logic signed [CORDW-1:0] bar_y_d_prev;  // previous line for direction detection
    logic bar_up_d;  // bar is moving up the screen?

    rasterbar raster_d (
        .clk,
        .start(sy == bar_y_d),
        .line,
        .base_colr(BASE_COLR_D),
        .colr_steps(STEPS_D),
        .colr_lines(COLR_LINES),
        .bar_colr(bar_colr_d),
        .drawing(bar_drawing_d),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // update bar positions with sine table
    enum {INIT, BAR_A, BAR_B, BAR_C, BAR_D, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin
                state <= BAR_A;
                sin_id <= sin_id + 1;
                sin_offs <= 0;
            end
            BAR_A: begin
                state <= BAR_B;
                bar_y_a <= VCENTER + (sin_data >>> SIN_SHIFT);
                bar_y_a_prev <= bar_y_a;
                sin_offs <= 64;  // offset for bar B: 64/256
            end
            BAR_B: begin
                state <= BAR_C;
                bar_y_b <= VCENTER + (sin_data >>> SIN_SHIFT);
                bar_y_b_prev <= bar_y_b;
                sin_offs <= 128;  // offset for bar C: 128/256
            end
            BAR_C: begin
                state <= BAR_D;
                bar_y_c <= VCENTER + (sin_data >>> SIN_SHIFT);
                bar_y_c_prev <= bar_y_c;
                sin_offs <= 192;  // offset for bar D: 192/256
            end
            BAR_D: begin
                state <= DONE;
                bar_y_d <= VCENTER + (sin_data >>> SIN_SHIFT);
                bar_y_d_prev <= bar_y_d;
            end
            default: if (start) state <= INIT;
        endcase
    end

    // bar rising or falling?
    always_comb begin
        bar_up_a = (bar_y_a < bar_y_a_prev);
        bar_up_b = (bar_y_b < bar_y_b_prev);
        bar_up_c = (bar_y_c < bar_y_c_prev);
        bar_up_d = (bar_y_d < bar_y_d_prev);
    end

    always_ff @(posedge clk) begin
        if (bar_drawing_a && bar_up_a) bar_colr <= bar_colr_a;
        else if (bar_drawing_b && bar_up_b) bar_colr <= bar_colr_b;
        else if (bar_drawing_c && bar_up_c) bar_colr <= bar_colr_c;
        else if (bar_drawing_d && bar_up_d) bar_colr <= bar_colr_d;
        else if (bar_drawing_a) bar_colr <= bar_colr_a;
        else if (bar_drawing_b) bar_colr <= bar_colr_b;
        else if (bar_drawing_c) bar_colr <= bar_colr_c;
        else if (bar_drawing_d) bar_colr <= bar_colr_d;
        else bar_colr <= 12'h000;
    end

    always_ff @(posedge clk) begin
        if ((bar_drawing_a && bar_up_a) || (bar_drawing_b && bar_up_b) ||
            (bar_drawing_c && bar_up_c) || (bar_drawing_d && bar_up_d))
            bar_up <= 1;
        else bar_up <= 0;
    end
endmodule
