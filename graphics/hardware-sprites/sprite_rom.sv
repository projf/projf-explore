// Project F: Hardware Sprites - Sprite from ROM
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/hardware-sprites/

`default_nettype none
`timescale 1ns / 1ps

module sprite_rom #(
    parameter CORDW=16,      // signed coordinate width (bits)
    parameter H_RES=640,     // horizontal screen resolution (pixels)
    parameter SX_OFFS=2,     // horizontal screen offset (pixels)
    parameter SPR_FILE="",   // sprite bitmap file ($readmemh format)
    parameter SPR_WIDTH=8,   // sprite bitmap width in pixels
    parameter SPR_HEIGHT=8,  // sprite bitmap height in pixels
    parameter SPR_DATAW=1    // data width: bits per pixel
    ) (
    input  wire logic clk,                            // clock
    input  wire logic rst,                            // reset
    input  wire logic line,                           // start of active screen line
    input  wire logic signed [CORDW-1:0] sx, sy,      // screen position
    input  wire logic signed [CORDW-1:0] sprx, spry,  // sprite position
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing                         // drawing at position (sx,sy)
    );

    // sprite bitmap ROM
    localparam SPR_ROM_DEPTH = SPR_WIDTH * SPR_HEIGHT;
    logic [$clog2(SPR_ROM_DEPTH)-1:0] spr_rom_addr;  // pixel position
    logic spr_rom_data;  // pixel colour
    rom_async #(
        .WIDTH(SPR_DATAW),
        .DEPTH(SPR_ROM_DEPTH),
        .INIT_F(SPR_FILE)
    ) spr_rom (
        .addr(spr_rom_addr),
        .data(spr_rom_data)
    );

    // horizontal coordinate within sprite bitmap
    logic [$clog2(SPR_WIDTH)-1:0] bmap_x;

    // for registering sprite position
    logic signed [CORDW-1:0] sprx_r, spry_r;

    // status flags: used to change state
    logic spr_active;  // sprite active on this line
    logic spr_begin;   // begin sprite drawing
    logic spr_end;     // end of sprite on this line
    logic line_end;    // end of screen line, corrected for sx offset
    always_comb begin
        spr_active = (sy - spry_r >= 0) && (sy - spry_r < SPR_HEIGHT);
        spr_begin  = (sx >= sprx_r - SX_OFFS);
        /* verilator lint_off WIDTH */
        spr_end    = (bmap_x == SPR_WIDTH-1);
        /* verilator lint_on WIDTH */
        line_end   = (sx == H_RES - SX_OFFS);
    end

    // sprite state machine
    enum {
        IDLE,      // awaiting line signal
        REG_POS,   // register sprite position
        ACTIVE,    // check if sprite is active on this line
        WAIT_POS,  // wait for horizontal sprite position
        SPR_LINE,  // iterate over sprite pixels
        WAIT_DATA  // account for data latency
    } state;

    always_ff @(posedge clk) begin
        if (line) begin  // prepare for new line
            state <= REG_POS;
            pix <= 0;
            drawing <= 0;
        end else begin
            case (state)
                REG_POS: begin
                    state <= ACTIVE;
                    sprx_r <= sprx;
                    spry_r <= spry;
                end
                ACTIVE: state <= spr_active ? WAIT_POS : IDLE;
                WAIT_POS: begin
                    if (spr_begin) begin
                        state <= SPR_LINE;
                        /* verilator lint_off WIDTH */
                        spr_rom_addr <= (sy - spry_r) * SPR_WIDTH + (sx - sprx_r) + SX_OFFS;
                        /* verilator lint_on WIDTH */
                        bmap_x <= 0;
                    end
                end
                SPR_LINE: begin
                    if (spr_end || line_end) state <= WAIT_DATA;
                    spr_rom_addr <= spr_rom_addr + 1;
                    bmap_x <= bmap_x + 1;
                    pix <= spr_rom_data;
                    drawing <= 1;
                end
                WAIT_DATA: begin
                    state <= IDLE;  // 1 cycle between address set and data receipt
                    pix <= 0;  // default colour
                    drawing <= 0;
                end
                default: state <= IDLE;
            endcase
        end

        if (rst) begin
            state <= IDLE;
            spr_rom_addr <= 0;
            bmap_x <= 0;
            pix <= 0;
            drawing <= 0;
        end
    end
endmodule
