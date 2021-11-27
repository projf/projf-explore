// Project F: Maths Demo - Graphing (Verilator SDL)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_graphing #(parameter CORDW=16) (   // coordinate width (in bits)
    input  wire logic clk_pix,                // pixel clock
    input  wire logic rst,                    // reset
    output      logic signed [CORDW-1:0] sx,  // horizontal screen position
    output      logic signed [CORDW-1:0] sy,  // vertical screen position
    output      logic de,                     // data enable (low in blanking interval)
    output      logic frame,                  // high at start of frame
    output      logic [7:0] sdl_r,            // 8-bit red
    output      logic [7:0] sdl_g,            // 8-bit green
    output      logic [7:0] sdl_b             // 8-bit blue
    );

    // display sync signals and coordinates
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de,
        .frame,
        /* verilator lint_on PINCONNECTEMPTY */
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // signal when to draw mathematical function and axis
    logic draw, axes;

    // SDL output
    always_ff @(posedge clk_pix) begin
        sdl_r <= !de ? 8'h0 : (axes ? 8'hCC : (draw ? 8'h33 : 8'h22));
        sdl_g <= !de ? 8'h0 : (axes ? 8'hCC : (draw ? 8'hBB : 8'h22));
        sdl_b <= !de ? 8'h0 : (axes ? 8'hCC : (draw ? 8'hCC : 8'h22));
    end


    //
    // Graphing Logic
    //

    // function coordinates
    logic signed [CORDW-1:0] x, y;

    // adjust screen coordinates so (0,0) is at centre of screen
    localparam X_OFFS = 320;
    localparam Y_OFFS = 239;
    always_ff @(posedge clk_pix) begin
        x <= sx - X_OFFS + 4;  // latency for function (+n) and offset calculation (+1)
        y <= Y_OFFS - sy;
    end

    // draw X and Y axes
    logic x_axis, y_axis;
    always_comb begin
        x_axis = (sy == Y_OFFS);
        y_axis = (sx == X_OFFS);
        axes = x_axis || y_axis;
    end

    // function to graph
    func_squared #(.CORDW(CORDW)) func_inst (
        .clk(clk_pix),
        .x,
        .y,
        .r(draw)
    );
endmodule
