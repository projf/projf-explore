// Project F: Racing the Beam - Colour Cycle (Verilator SDL)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/racing-the-beam/

`default_nettype none
`timescale 1ns / 1ps

module top_colour_cycle #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,             // pixel clock
    input  wire logic sim_rst,             // sim reset
    output      logic [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,         // 8-bit red
    output      logic [7:0] sdl_g,         // 8-bit green
    output      logic [7:0] sdl_b          // 8-bit blue
    );

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic de;
    simple_480p display_inst (
        .clk_pix,
        .rst_pix(sim_rst),
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de
    );

    // screen dimensions (must match display_inst)
    localparam V_RES = 480;  // vertical screen resolution

    logic frame;  // high for one clock tick at the start of vertical blanking
    always_comb frame = (sy == V_RES && sx == 0);

    // update the colour level every N frames
    localparam FRAME_NUM = 30;  // frames between colour level change
    logic [$clog2(FRAME_NUM):0] cnt_frame;  // frame counter
    logic [3:0] colr_level;  // level of colour being cycled

    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (cnt_frame == FRAME_NUM-1) begin  // every FRAME_NUM frames
                cnt_frame <= 0;
                colr_level <= colr_level + 1;
            end else cnt_frame <= cnt_frame + 1;
        end
    end

    // paint colour: based on screen position
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = sx[7:4];  // 16 horizontal pixels of each red level
        paint_g = sy[7:4];  // 16 vertical pixels of each green level
        paint_b = colr_level;  // blue level changes over time
    end

    // display colour: black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r <= {2{display_r}};  // double signal width from 4 to 8 bits
        sdl_g <= {2{display_g}};
        sdl_b <= {2{display_b}};
    end
endmodule
