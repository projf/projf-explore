// Project F: Hardware Sprites - Sprite v3
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sprite_v3 #(
    parameter WIDTH=8,            // graphic width in pixels
    parameter HEIGHT=8,           // graphic height in pixels
    parameter SCALE_X=1,          // sprite width scale-factor
    parameter SCALE_Y=1,          // sprite height scale-factor
    parameter SPR_FILE="",        // file to load sprite graphic from
    parameter CORDW=10,           // screen coordinate width in bits
    parameter H_RES_FULL=800,     // horizontal screen resolution inc. blanking
    parameter DEPTH=WIDTH*HEIGHT  // depth of memory array holding graphic
    ) (
    input  wire logic clk,               // clock
    input  wire logic rst,               // reset
    input  wire logic start,             // start control
    input  wire logic [CORDW-1:0] sx,    // horizontal screen position
    input  wire logic [CORDW-1:0] sprx,  // horizontal sprite position
    output      logic pix                // pixel colour to draw
    );

    logic memory [DEPTH];  // 1 bit per pixel

    // load sprite graphic into memory (binary text format)
    initial begin
        if (SPR_FILE != 0) begin
            $display("Creating sprite from file '%s'.", SPR_FILE);
            $readmemb(SPR_FILE, memory);
        end
    end

    // position within memory array
    logic [$clog2(DEPTH)-1:0] pos;

    // position within sprite
    logic [$clog2(WIDTH)-1:0]  ox;
    logic [$clog2(HEIGHT)-1:0] oy;

    // scale counters
    logic [$clog2(SCALE_X)-1:0] cnt_x;
    logic [$clog2(SCALE_Y)-1:0] cnt_y;

    enum {
        IDLE,       // awaiting start signal
        START,      // prepare for new sprite drawing
        AWAIT_POS,  // await horizontal position
        DRAW,       // draw pixel
        NEXT_LINE   // prepare for next sprite line
    } state, state_next;

    always_ff @(posedge clk) begin
        state <= state_next;  // advance to next state

        if (state == START) begin
            oy <= 0;
            cnt_y <= 0;
            pos <= 0;
        end

        if (state == AWAIT_POS) begin
            ox <= 0;
            cnt_x <= 0;
        end

        if (state == DRAW) begin
            if (SCALE_X <= 1 || cnt_x == SCALE_X-1) begin
                ox <= ox + 1;
                cnt_x <= 0;
                pos <= pos + 1;
            end else begin
                cnt_x <= cnt_x + 1;
            end
        end

        if (state == NEXT_LINE) begin
            if (SCALE_Y <= 1 || cnt_y == SCALE_Y-1) begin
                oy <= oy + 1;
                cnt_y <= 0;
            end else begin
                cnt_y <= cnt_y + 1;
                pos <= pos - WIDTH;  // go back to start of line
            end
        end

        if (rst) begin
            state <= IDLE;
            ox <= 0;
            oy <= 0;
            cnt_x <= 0;
            cnt_y <= 0;
            pos <= 0;
        end
    end

    // output current pixel colour when drawing
    always_comb begin
        pix = (state == DRAW) ? memory[pos] : 0;
    end

    // create status signals and correct horizontal position
    logic last_pixel, last_line;
    logic [CORDW-1:0] sprx_cor;
    always_comb begin
        /* verilator lint_off WIDTH */
        last_pixel = (ox == WIDTH-1 && cnt_x == SCALE_X-1);
        last_line  = (oy == HEIGHT-1 && cnt_y == SCALE_Y-1);
        /* verilator lint_on WIDTH */
        sprx_cor = (sprx == 0) ? H_RES_FULL - 1 : sprx - 1;
    end

    // determine next state
    always_comb begin
        case(state)
            IDLE:       state_next = start ? START : IDLE;
            START:      state_next = AWAIT_POS;
            AWAIT_POS:  state_next = (sx == sprx_cor) ? DRAW : AWAIT_POS;
            DRAW:       state_next = !last_pixel ? DRAW : (!last_line ? NEXT_LINE : IDLE);
            NEXT_LINE:  state_next = AWAIT_POS;
            default:    state_next = IDLE;
        endcase
    end
endmodule
