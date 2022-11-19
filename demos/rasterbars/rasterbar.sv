// Project F: Rasterbar Render (12-bit colour)
// (C)2022 Will Green & Ben Blundell, open source hardware released under the MIT License
// From "All You Need" by Chapterhouse released at Revision 2022 (with minor emendations)
// Learn more at https://projectf.io/posts/rasterbars/

`default_nettype none
`timescale 1ns / 1ps

module rasterbar (
    input  wire logic clk,                      // clock
    input  wire logic start,                    // start control
    input  wire logic line,                     // signal new screen line
    input  wire logic [11:0] base_colr,         // base bar colour
    input  wire logic [3:0] colr_steps,         // bar colour steps
    input  wire logic [3:0] colr_lines,         // lines of each colour
    output      logic [11:0] bar_colr,          // bar draw colour
    output      logic drawing,                  // bar is drawing
    output      logic done                      // bar drawing is complete
    );

    // NB. We don't (yet) register colr_steps and colr_lines

    logic bar_inc;  // increasing (or decreasing) brightness
    logic [3:0] cnt_step;  // count colour steps in each bar
    logic [3:0] cnt_line;  // count lines of each colour
    
    // generate bar colours
    always_ff @(posedge clk) begin
        if (start) begin  // reset colour at start of bar
            bar_colr <= base_colr;
            bar_inc <= 1;  // start by increasing brightness
            cnt_step <= 0;
            cnt_line <= 0;
            drawing <= 1;
            done <= 0;
        end else if (line) begin  // on each screen line
            if (cnt_line == colr_lines-1) begin  // colour complete
                cnt_line <= 0;
                if (cnt_step == colr_steps-1) begin  // switch increase/decrease
                    if (bar_inc == 1) begin
                        bar_inc <= 0;
                        cnt_step <= 0;
                    end else begin
                        drawing <= 0;
                        done <= 1;
                        bar_colr <= 12'h000;
                    end
                end else begin
                    bar_colr <= (bar_inc) ? bar_colr + 12'h111 : bar_colr - 12'h111;
                    cnt_step <= cnt_step + 1;
                end
            end else cnt_line <= cnt_line + 1;
        end
    end
endmodule
