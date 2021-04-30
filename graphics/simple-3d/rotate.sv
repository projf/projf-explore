// Project F: Simple 3D - Rotate
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module rotate #(
    parameter CORDW=16,  // signed coordinate width
    parameter ANGLEW=8    // angle width
    ) (
    input  wire logic clk,         // clock
    input  wire logic rst,         // reset
    input  wire logic start,       // start rotation
    input  wire logic [1:0] axis,  // axis (none=00, x=01, y=10, z=11)
    input  wire logic [ANGLEW-1:0] angle,     // rotation angle
    // input  wire logic signed [CORDW-1:0] xo,  // x origin
    // input  wire logic signed [CORDW-1:0] yo,  // y origin
    // input  wire logic signed [CORDW-1:0] zo,  // z origin
    input  wire logic signed [CORDW-1:0] x,   // x coord in
    input  wire logic signed [CORDW-1:0] y,   // y coord in
    input  wire logic signed [CORDW-1:0] z,   // z coord in
    output      logic signed [CORDW-1:0] xr,  // rotated x coord
    output      logic signed [CORDW-1:0] yr,  // rotated y coord
    output      logic signed [CORDW-1:0] zr,  // rotated z coord
    output      logic done  // rotation complete (high for one tick)
    );

    // sine table
    localparam SIN_DEPTH=64;  // entires in sine ROM 0°-90°
    localparam SIN_WIDTH=8;   // width of sine ROM data
    localparam SIN_ADDRW=$clog2(4*SIN_DEPTH);   // full table -180° to +180°
    localparam SIN_FILE="sine_table_64x8.mem";  // file to populate ROM

    logic [SIN_ADDRW-1:0] sin_id;
    logic signed [CORDW-1:0] sin_data;
    sine_table #(
        .CORDW(CORDW),
        .ROM_DEPTH(SIN_DEPTH),
        .ROM_WIDTH(SIN_WIDTH),
        .ROM_FILE(SIN_FILE)
    ) sine_table_inst (
        .id(sin_id),
        .data(sin_data)
    );

    // sine and cosine of angle
    logic [CORDW-1:0] sin_angle, cos_angle;

    // rotation intermediates (wide and regular)
    logic signed [2*CORDW-1:0] sin_xw, sin_yw, sin_zw;
    logic signed [2*CORDW-1:0] cos_xw, cos_yw, cos_zw;
    logic signed [CORDW-1:0] sin_x, sin_y, sin_z;
    logic signed [CORDW-1:0] cos_x, cos_y, cos_z;

    // rotate state machine
    enum {IDLE, INIT, SIN, COS, R1, R2, R3} state;
    initial state = IDLE;  // needed for Yosys
    always_ff @(posedge clk) begin
        done <= 0;
        case (state)
            INIT: begin
                sin_id <= angle;
                state <= SIN;
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
            // add translate stage here to handle offset origin
            R1: begin
                sin_xw <= x * sin_angle;
                sin_yw <= y * sin_angle;
                sin_zw <= z * sin_angle;
                cos_xw <= x * cos_angle;
                cos_yw <= y * cos_angle;
                cos_zw <= z * cos_angle;
                state <= R2;
            end
            R2: begin
                sin_x <= sin_xw[23:8];  // need to parameterize
                sin_y <= sin_yw[23:8];
                sin_z <= sin_zw[23:8];
                cos_x <= cos_xw[23:8];
                cos_y <= cos_yw[23:8];
                cos_z <= cos_zw[23:8];
                state <= R3;
            end
            R3: begin
                case (axis)
                    2'b00: begin  // no rotation
                        xr <= x; 
                        yr <= y;
                        zr <= z; 
                    end
                    2'b01: begin  // x-axis
                        xr <= x; 
                        yr <= cos_y - sin_z;
                        zr <= sin_y + cos_z; 
                    end
                    2'b10: begin  // y-axis
                        xr <= cos_x + sin_z; 
                        yr <= y;
                        zr <= cos_z - sin_x; 
                    end
                    2'b11: begin  // z-axis
                        xr <= cos_x - sin_y;
                        yr <= sin_x + cos_y;
                        zr <= z;
                    end
                endcase
                done <= 1;
                state <= IDLE;
            end
            // add translate stage here to undo origin offset 
            default: if (start) state <= INIT;  // IDLE
        endcase
    end
endmodule
