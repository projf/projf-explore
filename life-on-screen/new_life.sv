// Project F: Life on Screen - Conway's Game of Life Sim
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module new_life #(
    parameter CORDW=16,   // signed coordinate width
    parameter WIDTH=6,    // world width in cells
    parameter HEIGHT=6,   // world height in cells
    parameter F_INIT=""   // initial world state
    ) (
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start sim generation
    output      logic ready,           // cell state ready to be read
    output      logic alive,           // is the cell alive? (when ready)
    output      logic changed,         // cell's state changed (when ready)
    output      logic signed [CORDW-1:0] x,  // horizontal cell position
    output      logic signed [CORDW-1:0] y,  // vertical cell position
    output      logic running,         // sim is running
    output      logic done             // sim complete (high for one tick)
    );

    // buffer selection
    logic next_gen;  // where to write the next generation
    always @(posedge clk) begin
        if (start) next_gen <= ~next_gen;  // swap every generation
        if (rst) next_gen <= 0;
    end

    // world in BRAM
    localparam DATAW = 1;  // cells are either dead or alive
    localparam WORLD_WIDTH  = WIDTH  + 2;  // wider to handle boundary
    localparam WORLD_HEIGHT = HEIGHT + 2;  // taller to handle boundary
    localparam WORLD_CELLS = WORLD_WIDTH * WORLD_HEIGHT;
    localparam DEPTH = 2 * WORLD_CELLS;
    localparam ADDRW = $clog2(DEPTH);

    logic we;
    logic [ADDRW-1:0] cell_id, addr_read;  // cell_id is basis of write address
    logic [DATAW-1:0] data_in, data_out;

    // add offset to read and write addresses to match buffer used
    logic [ADDRW-1:0] addr_read_offs, addr_write_offs;
    always_comb begin
        addr_read_offs  = addr_read  + ((next_gen) ? 0 : WORLD_CELLS);
        addr_write_offs = cell_id + ((next_gen) ? WORLD_CELLS : 0);
    end

    bram_sdp #(
        .WIDTH(DATAW),
        .DEPTH(DEPTH),
        .INIT_F(F_INIT)
    ) bram_inst (
        .clk_write(clk),
        .clk_read(clk),
        .we,
        .addr_write(addr_write_offs),
        .addr_read(addr_read_offs),
        .data_in,
        .data_out
    );

    // cell coordinates
    localparam GRID = 3;    // examine 3x3 grid to determine neighbours
    localparam STEPS = 12;  // 9 reads, 2 cycle latency, 1 neighbour count
    logic [$clog2(WORLD_WIDTH)-1:0]  cell_x;  // active cell (horizontal)
    logic [$clog2(WORLD_HEIGHT)-1:0] cell_y;  // active cell (vertical)
    logic [$clog2(STEPS)-1:0] read_step;      // reading step
    logic inc_read;                           // perform incremental read
    logic [GRID-1:0] top_sr, mid_sr, bot_sr;  // shift reg for neighbours
    logic [$clog2(GRID*GRID)-1:0] neigh_cnt;  // count of neighbours

    // life sim state
    enum {IDLE, INIT, READ, UPDATE, NEW_CELL, NEW_LINE, PAD_LR, PAD_TB} state;
    initial state = IDLE;  // needed for Yosys
    always @(posedge clk) begin
        ready <= 0;  // not ready for external reading by default
        we <= 0;     // no writing to world by default

        case(state)
            INIT: begin
                // first cell after padding
                cell_x <= 1;
                cell_y <= 1;
                cell_id <= WORLD_WIDTH + 1;
                read_step <= 0;
                inc_read <= 0;
                top_sr <= 0;
                mid_sr <= 0;
                bot_sr <= 0;
                neigh_cnt <= 0;

                state <= READ;
                running <= 1;
                done <= 0;
            end
            READ: begin  // 1 cycle to set address and 1 cycle BRAM read latency
                case (read_step)
                    4'd0: begin
                        addr_read <= cell_id - WORLD_WIDTH - 1;  // A
                    end
                    4'd1: begin
                        addr_read <= cell_id - 1;  // B
                    end
                    4'd2: begin
                        addr_read <= cell_id + WORLD_WIDTH - 1;  // C
                        if (!inc_read) top_sr <= {top_sr[1:0], data_out};  // A
                    end
                    4'd3: begin
                        addr_read <= cell_id - WORLD_WIDTH;  // D
                        if (!inc_read) mid_sr <= {mid_sr[1:0], data_out};  // B
                    end
                    4'd4: begin
                        addr_read <= cell_id;  // E
                        if (!inc_read) bot_sr <= {bot_sr[1:0], data_out};  // C
                    end
                    4'd5: begin
                        addr_read <= cell_id + WORLD_WIDTH;  // F
                        if (!inc_read) top_sr <= {top_sr[1:0], data_out};  // D
                    end
                    4'd6: begin
                        addr_read <= cell_id - WORLD_WIDTH + 1;  // G
                        if (!inc_read) mid_sr <= {mid_sr[1:0], data_out};  // E
                    end
                    4'd7: begin
                        addr_read <= cell_id + 1;  // H
                        if (!inc_read) bot_sr <= {bot_sr[1:0], data_out};  // F
                    end
                    4'd8: begin
                        addr_read <= cell_id + WORLD_WIDTH + 1;  // I
                        top_sr <= {top_sr[1:0], data_out};  // G
                    end
                    4'd9: begin
                        mid_sr <= {mid_sr[1:0], data_out};  // H
                    end
                    4'd10: begin
                        bot_sr <= {bot_sr[1:0], data_out};  // I
                    end
                    4'd11: begin  // should be another state machine step
                        /* verilator lint_off WIDTH */
                        neigh_cnt <= top_sr[0] + top_sr[1] + top_sr[2] +
                                     mid_sr[0]             + mid_sr[2] +
                                     bot_sr[0] + bot_sr[1] + bot_sr[2];
                        /* verilator lint_on WIDTH */
                    end                    
                    default: addr_read <= 0;
                endcase

                if (read_step == STEPS-1) state <= UPDATE;
                else read_step <= read_step + 1;
            end
            UPDATE: begin
                // update cell state
                we <= 1;  // write new state next cycle
                ready <= 1;  // ready for output read next cycle
                /* verilator lint_off WIDTH */
                x <= cell_x - 1;  // correct for padding
                y <= cell_y - 1;  // correct for padding
                /* verilator lint_on WIDTH */

                if (mid_sr[1]) begin // cell is alive this generation
                    if (neigh_cnt == 2 || neigh_cnt == 3) begin  // still alive
                        data_in <= 1;
                        alive <= 1;
                        changed <= 0;
                    end else begin  // now dead
                        data_in <= 0;
                        alive <= 0;
                        changed <= 1;                    
                    end
                end else begin  // was is dead this generation
                    if (neigh_cnt == 3) begin  // now alive
                        data_in <= 1;
                        alive <= 1;
                        changed <= 1;
                    end else begin  // still dead
                        data_in <= 0;
                        alive <= 0;
                        changed <= 0;                    
                    end                
                end

                // what next?
                if (cell_x == WORLD_WIDTH-2) begin  // final cell on line
                    if (cell_y == WORLD_HEIGHT-2) begin  // final line of cells
                        state <= PAD_LR;
                    end else state <= NEW_LINE;
                end else state <= NEW_CELL;
            end
            NEW_CELL: begin
                cell_x <= cell_x + 1;
                cell_id <= cell_id + 1;
                inc_read  <= 1;  // incremental read
                read_step <= 6;  // read new column of 3 cells (skip A-F)
                state <= READ;
            end
            NEW_LINE: begin
                cell_y <= cell_y + 1;
                cell_x <= 1;
                cell_id <= cell_id + 3;  // skip 2 cells of padding
                read_step <= 0;  // read all nine cells at start of line
                state <= READ;
            end
            PAD_LR: begin
                // not yet implemented
                state <= PAD_TB;
            end 
            PAD_TB: begin
                // not yet implemented
                state <= IDLE;
                running <= 0;
                done <= 1;
            end
            default: state <= (start) ? INIT : IDLE;  // IDLE
        endcase
        if (rst) begin
            x <= 0;
            y <= 0;
            ready <= 0;
            alive <= 0;
            changed <= 0;
            running <= 0;
            done <= 0;
        end
    end

endmodule
