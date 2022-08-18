// Project F: Ad Astra - Sprite for Fonts
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-ad-astra/

`default_nettype none
`timescale 1ns / 1ps

module sprite #(
    parameter WIDTH=8,         // graphic width in pixels
    parameter HEIGHT=8,        // graphic height in pixels
    parameter SCALE_X=1,       // sprite width scale-factor
    parameter SCALE_Y=1,       // sprite height scale-factor
    parameter LSB=1,           // first pixel in LSB
    parameter CORDW=16,        // screen coordinate width in bits
    parameter ADDRW=9          // width of graphic memory address bus
    ) (
    input  wire logic clk,                  // clock
    input  wire logic rst,                  // reset
    input  wire logic start,                // start control
    input  wire logic dma_avail,            // memory access control
    input  wire logic signed [CORDW-1:0] sx,    // horizontal screen position
    input  wire logic signed [CORDW-1:0] sprx,  // horizontal sprite position
    input  wire logic [WIDTH-1:0] data_in,  // data from external memory
    output      logic [ADDRW-1:0] pos,      // sprite line position
    output      logic pix,                  // pixel colour to draw (0 or 1)
    output      logic drawing,              // sprite is drawing
    output      logic done                  // sprite drawing is complete
    );

    logic [WIDTH-1:0] spr_line;  // local copy of sprite line

    // position within sprite
    logic [$clog2(WIDTH)-1:0]  ox;
    logic [$clog2(HEIGHT)-1:0] oy;

    // scale counters
    logic [$clog2(SCALE_X)-1:0] cnt_x;
    logic [$clog2(SCALE_Y)-1:0] cnt_y;

    enum {
        IDLE,       // awaiting start signal
        START,      // prepare for new sprite drawing
        AWAIT_DMA,  // await access to memory
        READ_MEM,   // read line of sprite from memory
        AWAIT_POS,  // await horizontal position
        DRAW,       // draw pixel
        NEXT_LINE,  // prepare for next sprite line
        DONE        // set done signal
    } state, state_next;

    integer i;  // for bit reversal in READ_MEM

    always_ff @(posedge clk) begin
        state <= state_next;  // advance to next state

        case (state)
            START: begin
                done <= 0;
                oy <= 0;
                cnt_y <= 0;
                pos <= 0;
            end
            READ_MEM: begin
                if (LSB) begin
                    spr_line <= data_in;  // assume read takes one clock cycle
                end else begin  // reverse if MSB is left-most pixel
                    for (i=0; i<WIDTH; i=i+1)
                        spr_line[i] <= data_in[(WIDTH-1)-i];
                end
            end
            AWAIT_POS: begin
                ox <= 0;
                cnt_x <= 0;
            end
            DRAW: begin
                /* verilator lint_off WIDTH */
                if (SCALE_X <= 1 || cnt_x == SCALE_X-1) begin
                /* verilator lint_on WIDTH */
                    ox <= ox + 1;
                    cnt_x <= 0;
                end else begin
                    cnt_x <= cnt_x + 1;
                end
            end
            NEXT_LINE: begin
                /* verilator lint_off WIDTH */
                if (SCALE_Y <= 1 || cnt_y == SCALE_Y-1) begin
                /* verilator lint_on WIDTH */
                    oy <= oy + 1;
                    cnt_y <= 0;
                    pos <= pos + 1;
                end else begin
                    cnt_y <= cnt_y + 1;
                end
            end
            DONE: done <= 1;
        endcase

        if (rst) begin
            state <= IDLE;
            ox <= 0;
            oy <= 0;
            cnt_x <= 0;
            cnt_y <= 0;
            spr_line <= 0;
            pos <= 0;
            done <= 0;
        end
    end

    // output current pixel colour when drawing
    always_comb begin
        pix = (state == DRAW) ? spr_line[ox] : 0;
    end

    // create status signals
    logic last_pixel, load_line, last_line;
    always_comb begin
        /* verilator lint_off WIDTH */
        last_pixel = (ox == WIDTH-1 && cnt_x == SCALE_X-1);
        load_line  = (cnt_y == SCALE_Y-1);
        last_line  = (oy == HEIGHT-1 && cnt_y == SCALE_Y-1);
        /* verilator lint_on WIDTH */
        drawing = (state == DRAW);
    end

    // determine next state
    always_comb begin
        case (state)
            IDLE:       state_next = start ? START : IDLE;
            START:      state_next = AWAIT_DMA;
            AWAIT_DMA:  state_next = dma_avail ? READ_MEM : AWAIT_DMA;
            READ_MEM:   state_next = AWAIT_POS;
            AWAIT_POS:  state_next = (sx == sprx-2) ? DRAW : AWAIT_POS;
            DRAW:       state_next = !last_pixel ? DRAW :
                                    (!last_line ? NEXT_LINE : DONE);
            NEXT_LINE:  state_next = load_line ? AWAIT_DMA : AWAIT_POS;
            DONE:       state_next = IDLE;
            default:    state_next = IDLE;
        endcase
    end
endmodule
