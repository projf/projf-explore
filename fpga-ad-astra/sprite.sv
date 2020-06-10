// Project F: FPGA Ad Astra - Sprite (1-bit per Pixel)
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module sprite #(
        parameter LSB=1,      // first pixel in LSB
        parameter WIDTH=8,    // graphic width in pixels
        parameter HEIGHT=8,   // graphic height in pixels
        parameter SCALE_X=1,  // sprite width scale-factor
        parameter SCALE_Y=1,  // sprite height scale-factor
        parameter ADDRW=9,    // width of graphic address bus
        parameter CORDW=10    // width of screen coordinates
        ) (
        input  wire logic clk,                        // clock
        input  wire logic rst,                        // reset
        input  wire logic start,                      // start control
        input  wire logic dma_avail,                  // memory access control
        input  wire logic [CORDW-1:0] sx,             // horizontal screen position
        input  wire logic [CORDW-1:0] sprx,           // horizontal sprite position
        input  wire logic [WIDTH-1:0] gfx_data,       // sprite graphic data
        input  wire logic [ADDRW-1:0] gfx_addr_base,  // graphic base address
        output      logic [ADDRW-1:0] gfx_addr,       // graphic address (sprite line)
        output      logic pix,                        // pixel to draw
        output      logic done                        // sprite drawing is complete
    );

    // position within sprite
    /* verilator lint_off LITENDIAN */
    logic [$clog2(WIDTH)-1:0]  ox;
    logic [$clog2(HEIGHT)-1:0] oy;

    // scale counters
    logic [$clog2(SCALE_X)-1:0] cnt_x;
    logic [$clog2(SCALE_Y)-1:0] cnt_y;
    /* verilator lint_on LITENDIAN */

    logic [WIDTH-1:0] spr_line; // local copy of sprite line

    enum {
        IDLE,       // awaiting start signal
        START,      // prepare for new sprite drawing
        AWAIT_DMA,  // await DMA access to memory
        READ_MEM,   // read line of sprite from memory
        AWAIT_POS,  // await horizontal position
        DRAW,       // draw pixel
        NEXT_LINE,  // prepare for next line
        DONE        // set done signal, then go idle
    } state, state_next;

    integer i;  // for bit reversal in READ_MEM

    always_ff @(posedge clk) begin
        // advance to next state
        state <= state_next;

        // START
        // clear done signal
        // set vertical position to start
        // set graphic address to base
        if (state == START) begin
            done <= 0;
            oy <= 0;
            cnt_y <= 0;
            gfx_addr <= gfx_addr_base;
        end

        // READ_MEM
        // read sprite line, reversing if MSB is left-most pixel
        // NB. Assumes read takes one clock cycle
        if (state == READ_MEM) begin
            if (LSB) begin
                spr_line <= gfx_data;
            end else begin
                for (i=0; i<WIDTH; i=i+1) spr_line[i] <= gfx_data[(WIDTH-1)-i];
            end
         end

        // AWAIT_POS
        // set horizontal drawing position to start of sprite
        if (state == AWAIT_DMA) begin
            ox <= 0;
            cnt_x <= 0;
        end

        // DRAW
        // count horizontal position, including scaling factor
        if (state == DRAW) begin
            if (SCALE_X <= 1 || cnt_x == SCALE_X-1) begin
                ox <= ox + 1;
                cnt_x <= 0;
            end else begin
                cnt_x <= cnt_x + 1;
            end
        end

        // NEXT_LINE
        // count vertical position, including scaling factor
        // increment memory address for new graphic line
        if (state == NEXT_LINE) begin
            if (SCALE_Y <= 1 || cnt_y == SCALE_Y-1) begin
                oy <= oy + 1;
                cnt_y <= 0;
                gfx_addr <= gfx_addr + 1;
            end else begin
                cnt_y <= cnt_y + 1;
            end
        end

        // DONE
        // set done signal
        if (state == DONE) begin
            done <= 1;
        end

        if (rst) begin
            state <= IDLE;
            ox <= 0;
            oy <= 0;
            cnt_x <= 0;
            cnt_y <= 0;
            spr_line <= 0;
            gfx_addr <= gfx_addr_base;
            done <= 0;
        end
    end

    logic line_complete, line_gfx_complete, draw_complete;
    always_comb begin
        /* verilator lint_off WIDTH */
        line_complete      = (ox == WIDTH-1 && cnt_x == SCALE_X-1);
        line_gfx_complete  = (cnt_y == SCALE_Y-1);
        draw_complete      = (oy == HEIGHT-1 && line_complete && line_gfx_complete);
        /* verilator lint_on WIDTH */

        pix = 0;
        state_next = IDLE;
        case(state)
            IDLE: state_next = (start) ? START : IDLE;
            START: state_next = AWAIT_DMA;
            AWAIT_DMA: state_next = (dma_avail) ? READ_MEM : AWAIT_DMA;
            READ_MEM: state_next = AWAIT_POS;
            AWAIT_POS: state_next = (sx == sprx) ? DRAW : AWAIT_POS;
            DRAW: begin
                pix = spr_line[ox];
                state_next = (draw_complete) ? DONE :
                             (line_complete) ? NEXT_LINE : DRAW;
            end
            NEXT_LINE: state_next = (line_gfx_complete) ? AWAIT_DMA : AWAIT_POS;
            DONE: state_next = IDLE;
        endcase
    end
endmodule
