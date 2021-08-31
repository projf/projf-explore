// Project F: Animated Shapes - Rotate XY
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module rotate_xy #(
    parameter CORDW=16,  // signed coordinate width
    parameter ANGLEW=8   // angle width
    ) (
    input  wire logic clk,         // clock
    input  wire logic rst,         // reset
    input  wire logic start,       // start rotation
    input  wire logic [ANGLEW-1:0] angle,     // rotation angle
    input  wire logic signed [CORDW-1:0] xi,  // x coord in
    input  wire logic signed [CORDW-1:0] yi,  // y coord in
    output      logic signed [CORDW-1:0] x,   // rotated x coord
    output      logic signed [CORDW-1:0] y,   // rotated y coord
    output      logic done  // rotation complete (high for one tick)
    );

    // sine table
    localparam SIN_DEPTH=64;  // entires in sine ROM 0°-90°
    localparam SIN_WIDTH=8;   // width of sine ROM data
    localparam SIN_ADDRW=$clog2(4*SIN_DEPTH);   // full table -180° to +180°
    localparam SIN_FILE="sine_table_64x8.mem";  // file to populate ROM

    logic [SIN_ADDRW-1:0] sin_id;
    logic signed [CORDW-1:0] sin_data;  // sign extend data to match coords
    sine_table #(
        .ROM_DEPTH(SIN_DEPTH),
        .ROM_WIDTH(SIN_WIDTH),
        .ROM_FILE(SIN_FILE)
    ) sine_table_inst (
        .id(sin_id),
        .data(sin_data)
    );

    // sine and cosine of angle
    logic signed [CORDW-1:0] sin_angle, cos_angle;

    // rotation intermediates (wide and regular)
    logic signed [CORDW+CORDW+ANGLEW-1:0] sin_xw, sin_yw;
    logic signed [CORDW+CORDW+ANGLEW-1:0] cos_xw, cos_yw;

    // fixed-point coordinates for multiplcation with angle
    logic signed [CORDW+ANGLEW-1:0] x_fp, y_fp;
    /* verilator lint_off UNUSED */
    logic signed [CORDW+CORDW+ANGLEW-1:0] x_wide, y_wide;
    /* verilator lint_on UNUSED */

    // rotate state machine
    enum {IDLE, INIT, SIN, COS, R1, R2, R3} state;
    always_ff @(posedge clk) begin
        done <= 0;
        case (state)
            INIT: begin
                sin_id <= angle;
                state <= SIN;
                x_fp <= {xi,{ANGLEW{1'b0}}};  // widen for fixed-point multiply
                y_fp <= {yi,{ANGLEW{1'b0}}};
            end
            SIN: begin
                sin_angle <= sin_data;
                sin_id <= SIN_DEPTH - angle;
                state <= COS;
            end
            COS: begin
                cos_angle <= sin_data;
                state <= R1;
            end
            R1: begin
                sin_xw <= x_fp * sin_angle;
                sin_yw <= y_fp * sin_angle;
                cos_xw <= x_fp * cos_angle;
                cos_yw <= y_fp * cos_angle;
                state <= R2;
            end
            R2: begin
                x_wide <= cos_xw - sin_yw;
                y_wide <= sin_xw + cos_yw;
                state <= R3;
            end
            R3: begin  // truncate to integer
                x <= x_wide[2*CORDW-1:CORDW];
                y <= y_wide[2*CORDW-1:CORDW];
                done <= 1;
                state <= IDLE;
            end
            default: if (start) state <= INIT;  // IDLE
        endcase
        if (rst) begin
            done <= 0;           
            state <= IDLE;
        end
    end
endmodule
