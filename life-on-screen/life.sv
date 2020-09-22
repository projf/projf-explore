// Project F: Life on Screen - Life Simulation
// (C)2020 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module life #(
    parameter WORLD_WIDTH=6,
    parameter WORLD_HEIGHT=6,
    parameter ADDRW=$clog2(WORLD_WIDTH * WORLD_HEIGHT)
    ) (
    input  wire logic clk,
    input  wire logic start,
    input  wire logic run,
    output      logic [ADDRW-1:0] id,
    input  wire logic r_status,
    output      logic w_status,
    output      logic we,
    output      logic done
    );

    // simulation parameters
    localparam CELL_COUNT = WORLD_WIDTH * WORLD_HEIGHT;  // total number of cells
    localparam NEIGHBOURS_COUNT = 8;  // number of neighbours each cell has

    // number of alive neighbours (could be 8!)
    logic [$clog2(NEIGHBOURS_COUNT+1)-1:0] neighbours_alive;

    // internal cell and neighbour IDs
    logic [ADDRW-1:0] cid, cid_next;
    logic [ADDRW-1:0] nid;  // adding nid_next would improve timing slack
    logic [$clog2(NEIGHBOURS_COUNT)-1:0] npos, npos_next;

    // simulation state
    enum {IDLE, NEXT_CELL, NEIGHBOURS, CURRENT_CELL, UPDATE_CELL} state, state_next;
    always_comb begin
        case(state)
            IDLE: state_next = (start && !done) ? NEXT_CELL : IDLE;
            NEXT_CELL: begin
                if (done) begin
                    state_next = IDLE;
                end else if (run) begin
                    state_next = NEIGHBOURS;
                end else begin
                    state_next = NEXT_CELL;
                end
            end
            NEIGHBOURS: state_next = (npos == NEIGHBOURS_COUNT-1) ? CURRENT_CELL : NEIGHBOURS;
            CURRENT_CELL: state_next = UPDATE_CELL;
            UPDATE_CELL: state_next = NEXT_CELL;
            default: state_next = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        state <= state_next;
        cid <= cid_next;
        npos <= npos_next;
    end

    // simulation calculations
    always_comb begin
        we = (state == UPDATE_CELL) ? 1 : 0;  // enable writing when updating
        id = cid;
        npos_next = npos;
        cid_next = cid;
        w_status = 0;

        case(state)
            IDLE: begin
                cid_next = 0;
                nid = 0;
                npos_next = 0;
            end
            NEIGHBOURS: begin
                // map neigbour index onto ID
                case (npos)
                    3'd0: nid = cid - (WORLD_WIDTH + 1);
                    3'd1: nid = cid - WORLD_WIDTH;
                    3'd2: nid = cid - (WORLD_WIDTH - 1);
                    3'd3: nid = cid - 1;
                    3'd4: nid = cid + 1;
                    3'd5: nid = cid + (WORLD_WIDTH - 1);
                    3'd6: nid = cid + WORLD_WIDTH;
                    3'd7: nid = cid + (WORLD_WIDTH + 1);
                endcase

                // because the life universe wraps we need to correct for possible under/overflow
                if (nid >= CELL_COUNT) begin
                    if (npos <= 3'd3) begin
                        nid = CELL_COUNT - (2**ADDRW - nid);
                    end else begin
                        nid = nid - CELL_COUNT;
                    end
                end

                npos_next = (state == NEIGHBOURS) ? npos + 1 : 0;
                id = nid;
            end
            UPDATE_CELL: begin
                if (r_status == 1) begin  // if cell is currently alive
                    w_status = (neighbours_alive == 4'd2 || neighbours_alive == 4'd3) ? 1 : 0;
                end else begin  // or dead
                    w_status = (neighbours_alive == 4'd3) ? 1 : 0;
                end

                // ready for next cell
                cid_next = (cid < CELL_COUNT-1) ? cid + 1 : 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case(state)
            IDLE: begin
                neighbours_alive <= 0;
                done <= 0;
            end
            // BRAM takes one cycle to read data, so we need to offset by one cycle
            NEIGHBOURS: if (npos >= 3'd1) neighbours_alive <= neighbours_alive + {3'b0, r_status};
            CURRENT_CELL: neighbours_alive <= neighbours_alive + {3'b0, r_status};
            UPDATE_CELL: begin
                // prepare for next cell
                if (cid < CELL_COUNT-1) begin
                    neighbours_alive <= 0;
                end else begin
                    done <= 1;
                end
            end
        endcase
    end
endmodule
