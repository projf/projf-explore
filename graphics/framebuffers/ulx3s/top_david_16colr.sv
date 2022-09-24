// Project F: Framebuffers - 16 Colour David (ulx3s)
// (C)2022 Will Green, (C) 2022 Tristan Itschner, 
// open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/framebuffers/

`default_nettype none
`timescale 1ns / 1ps

module top_david_16colr (
    input  wire logic clk_25mhz,      // 25 MHz clock
	output wire logic [3:0] gpdi_dp
    );

    // generate pixel clock
    logic clk_pix;
	logic clk_tmds_half;
    logic clk_pix_locked;

    clock_480p clock_pix_inst (
       .clk_25mhz,
       .clk_25m(clk_pix),
       .clk_tmds_half,
       .clk_pix_locked
    );

    // reset in pixel clock domain
    logic rst_pix;
    always_comb rst_pix = !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        /* verilator lint_off PINCONNECTEMPTY */
        .line()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // library resource path
    localparam LIB_RES = "../../../lib/res";

    // bitmap images
    localparam BMAP_IMAGE = "../res/david/david.mem";
    // localparam BMAP_IMAGE = {LIB_RES,"/test/test_box_160x120.mem"};

    // colour palettes
    localparam PAL_FILE = {LIB_RES,"/palettes/grey16_4b.mem"};
    // localparam PAL_FILE = {LIB_RES,"/palettes/greyinvert16_4b.mem"};
    // localparam PAL_FILE = {LIB_RES,"/palettes/sepia16_4b.mem"};
    // localparam PAL_FILE = {LIB_RES,"/palettes/sweetie16_4b.mem"};

    // colour parameters
    localparam CHANW = 4;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam CIDXW = 4;        // colour index width (bits)

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;  // framebuffer width in pixels
    localparam FB_HEIGHT = 120;  // framebuffer width in pixels
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel

    // pixel read address and colour
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_read;

    // framebuffer memory
    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(BMAP_IMAGE)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .we(),
        .addr_write(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_read(fb_addr_read),
        /* verilator lint_off PINCONNECTEMPTY */
        .data_in(),
        /* verilator lint_on PINCONNECTEMPTY */
        .data_out(fb_colr_read)
    );

    // calculate framebuffer read address for display output
    localparam LAT = 3;  // read_fb+1, BRAM+1, CLUT+1
    logic read_fb;
    always_ff @(posedge clk_pix) begin
        read_fb <= (sy >= 0 && sy < FB_HEIGHT && sx >= -LAT && sx < FB_WIDTH-LAT);
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (read_fb) begin  // increment address in painting area
            fb_addr_read <= fb_addr_read + 1;
        end
    end

    // colour lookup table
    logic [COLRW-1:0] fb_pix_colr;
    clut_simple #(
        .COLRW(COLRW),
        .CIDXW(CIDXW),
        .F_PAL(PAL_FILE)
        ) clut_instance (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(0),
        .cidx_write(0),
        .cidx_read(fb_colr_read),
        .colr_in(0),
        .colr_out(fb_pix_colr)
    );

    // paint screen
    logic paint_area;  // area of framebuffer to paint
    logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
    always_comb begin
        paint_area = (sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx < FB_WIDTH);
        {paint_r, paint_g, paint_b} = paint_area ? fb_pix_colr: 12'h000;
    end

	// gpdi output
	pix2gpdi pix2gpdi_inst(
		.clk_pix, // ~25 MHz
		.clk_tmds_half, // 5* clk_pix, ~ 125 MHz, must be phase aligned
		.red ( {paint_r, 4'b0000 } ),
		.green ( { paint_g, 4'b0000 } ),
		.blue ( { paint_b, 4'b0000 } ),
		.de (paint_area),
		.hsync,
		.vsync,
		.gpdi_dp
	);

endmodule
