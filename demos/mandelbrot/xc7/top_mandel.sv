// Project F: Mandelbrot Set (Arty Pmod VGA)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/mandelbrot-set-verilog/

`default_nettype none
`timescale 1ns / 1ps

module top_mandel (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    input  wire logic btn_fire,     // fire button
    input  wire logic btn_up,       // up button
    input  wire logic btn_dn,       // down button
    output      logic [3:0] led,    // four green LEDs
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // maths parameters
    localparam FP_WIDTH =   25;  // total width of fixed-point number: integer + fractional bits
    localparam FP_INT =      4;  // integer bits in fixed-point number
    localparam ITER_MAX =  255;  // maximum iterations: minimum of 128, but (2^n-1 recommneded)
    localparam SUPERSAMPLE = 1;  // combine multiple samples for each coordinate

    // starting coordinates (match FP_WIDTH)
    // localparam X_START = 18'b1100_1000_0000_0000_00;  // starting left: -3.5
    // localparam Y_START = 18'b1110_1000_0000_0000_00;  // starting top:  -1.5i
    // localparam STEP    = 18'b0000_0000_0100_0000_00;  // starting step: 1/64 (320x180)
    localparam X_START = 25'b1100_1000_0000_0000_0000_0000_0;  // starting left: -3.5
    localparam Y_START = 25'b1110_1000_0000_0000_0000_0000_0;  // starting top:  -1.5i
    localparam STEP    = 25'b0000_0000_0100_0000_0000_0000_0;  // starting step: 1/64 (320x180)

    // generate system clock
    logic clk_sys;
    logic clk_sys_locked;
    logic rst_sys;
    clock_sys clock_sys_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_sys,
       .clk_sys_locked
    );
    always_ff @(posedge clk_sys) rst_sys <= !clk_sys_locked;  // wait for clock lock

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       /* verilator lint_off PINCONNECTEMPTY */
       .clk_pix_5x(),  // not used for VGA output
       /* verilator lint_on PINCONNECTEMPTY */
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // debounce buttons
    logic sig_fire, sig_up, sig_dn;
    /* verilator lint_off PINCONNECTEMPTY */
    debounce deb_fire (.clk(clk_sys), .in(btn_fire), .out(), .ondn(), .onup(sig_fire));
    debounce deb_up (.clk(clk_sys), .in(btn_up), .out(sig_up), .ondn(), .onup());
    debounce deb_dn (.clk(clk_sys), .in(btn_dn), .out(sig_dn), .ondn(), .onup());
    /* verilator lint_on PINCONNECTEMPTY */

    // colour parameters
    localparam CHANW = 8;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam CIDXW = 8;        // colour index width (bits)

    // framebuffer (FB)
    localparam FB_WIDTH  = 320;  // framebuffer width in pixels
    localparam FB_HEIGHT = 180;  // framebuffer height in pixels
    localparam FB_SCALE  =   2;  // framebuffer display scale (1-63)
    localparam FB_OFFX   =   0;  // horizontal offset
    localparam FB_OFFY   =  60;  // vertical offset
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = CIDXW;  // colour bits per pixel

    // pixel read and write addresses and colours
    logic [FB_ADDRW-1:0] fb_addr_write, fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_write, fb_colr_read;
    logic fb_we;  // framebuffer write enable

    // framebuffer memory
    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F("")
    ) bram_inst (
        .clk_write(clk_sys),
        .clk_read(clk_sys),
        .we(fb_we),
        .addr_write(fb_addr_write),
        .addr_read(fb_addr_read),
        .data_in(fb_colr_write),
        .data_out(fb_colr_read)
    );

    // display flags in system clock domain
    logic frame_sys, line_sys, line0_sys;
    xd xd_frame (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(frame), .flag_dst(frame_sys));
    xd xd_line  (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(line),  .flag_dst(line_sys));
    xd xd_line0 (.clk_src(clk_pix), .clk_dst(clk_sys),
        .flag_src(line && sy==FB_OFFY), .flag_dst(line0_sys));

    //
    // update rendering params
    //
    logic signed [FP_WIDTH-1:0] x_start, x_start_p;  // left x-coordinate
    logic signed [FP_WIDTH-1:0] y_start, y_start_p;  // top y-coordinate
    logic signed [FP_WIDTH-1:0] step, step_p;        // coordinate step

    logic start_func, render_required;  // control start of function
    logic drawing;  // actively drawing in framebuffer
    logic render_busy;  // rendering in progress
    logic changed_params;  // function params have changed

    enum {HORIZONTAL, VERTICAL, ZOOM, ITER} state;
    always_ff @(posedge clk_sys) begin
        case (state)
            HORIZONTAL: if (sig_fire) state <= VERTICAL;
            VERTICAL:   if (sig_fire) state <= ZOOM;
            ZOOM:       if (sig_fire) state <= HORIZONTAL;
        endcase

        // no change in params by default
        x_start_p <= x_start;
        y_start_p <= y_start;
        step_p <= step;

        if (frame_sys && !changed_params && !render_busy) begin
            case (state)
                HORIZONTAL: begin
                    if (sig_up) begin
                        x_start_p <= x_start - (step <<< 4);
                        changed_params <= 1;
                        $display(">> Move left");
                    end else if (sig_dn) begin
                        x_start_p <= x_start + (step <<< 4);
                        changed_params <= 1;
                        $display(">> Move right");
                    end
                end
                VERTICAL: begin
                    if (sig_up) begin
                        y_start_p <= y_start - (step <<< 4);
                        changed_params <= 1;
                        $display(">> Move up");
                    end else if (sig_dn) begin
                        y_start_p <= y_start + (step <<< 4);
                        changed_params <= 1;
                        $display(">> Move down");
                    end
                end
                ZOOM: begin  // zoom values need adjusting if resolution is not ~320x180
                    if (sig_up) begin
                        x_start_p <= x_start - (step <<< 7);
                        y_start_p <= y_start - (step <<< 6) - (step <<< 5);
                        step_p <= 2 * step;
                        changed_params <= 1;
                        $display(">> Zoom out");
                    end else if (sig_dn) begin
                        x_start_p <= x_start + (step <<< 6);
                        y_start_p <= y_start + (step <<< 5) + (step <<< 4);
                        step_p <= step / 2;
                        changed_params <= 1;
                        $display(">> Zoom in");
                    end
                end
            endcase
        end

        // call function start once unless position/zoom updated
        start_func <= 0;
        if (changed_params && !render_busy) begin  // register new params to improve timing
            changed_params <= 0;
            if (step_p != 0 && step_p <= STEP) begin  // don't zoom in or out too far
                render_required <= 1;
                x_start <= x_start_p;
                y_start <= y_start_p;
                step <= step_p;
            end
        end else if (render_required) begin
            start_func <= 1;
            render_required <= 0;
        end

        if (rst_sys) begin
            state      <= HORIZONTAL;
            x_start    <= X_START;
            y_start    <= Y_START;
            step       <= STEP;
            render_required <= 1;
            changed_params  <= 0;
        end
    end

    //
    // draw in framebuffer
    //

    logic clip;  // location is clipped
    logic signed [CORDW-1:0] drx, dry;  // draw coordinates

    render_mandel #(
        .CORDW(CORDW),
        .FB_WIDTH(FB_WIDTH),
        .FB_HEIGHT(FB_HEIGHT),
        .CIDXW(CIDXW),
        .FP_WIDTH(FP_WIDTH),
        .FP_INT(FP_INT),
        .ITER_MAX(ITER_MAX),
        .SUPERSAMPLE(SUPERSAMPLE)
    ) render_mandel_instance (
        .clk(clk_sys),
        .rst(rst_sys),
        .start(start_func),
        .x_start,
        .y_start,
        .step,
        .x(drx),
        .y(dry),
        .cidx(fb_colr_write),
        .drawing,
        .busy(render_busy),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // calculate pixel address in framebuffer (three-cycle latency)
    bitmap_addr #(
        .CORDW(CORDW),
        .ADDRW(FB_ADDRW)
    ) bitmap_addr_instance (
        .clk(clk_sys),
        .bmpw(FB_WIDTH),
        .bmph(FB_HEIGHT),
        .x(drx),
        .y(dry),
        .offx(0),
        .offy(0),
        .addr(fb_addr_write),
        .clip
    );

    // delay write enable to match address calculation
    localparam LAT_ADDR = 3;  // latency (cycles)
    logic [LAT_ADDR-1:0] fb_we_sr;
    always_ff @(posedge clk_sys) begin
        fb_we_sr <= {drawing, fb_we_sr[LAT_ADDR-1:1]};
        if (rst_sys) fb_we_sr <= 0;
    end
    always_comb fb_we = fb_we_sr[0] && !clip;  // check for clipping

    //
    // read framebuffer for display output via linebuffer
    //

    // count lines for scaling via linebuffer
    logic [$clog2(FB_SCALE):0] cnt_lb_line;
    always_ff @(posedge clk_sys) begin
        if (line0_sys) cnt_lb_line <= 0;
        else if (line_sys) begin
            cnt_lb_line <= (cnt_lb_line == FB_SCALE-1) ? 0 : cnt_lb_line + 1;
        end
    end

    // which screen lines need linebuffer?
    logic lb_line;
    always_ff @(posedge clk_sys) begin
        if (line0_sys) lb_line <= 1;  // enable from sy==0
        if (frame_sys) lb_line <= 0;  // disable at frame start
    end

    // enable linebuffer input
    logic lb_en_in;
    logic [$clog2(FB_WIDTH)-1:0] cnt_lbx;  // horizontal pixel counter
    always_comb lb_en_in = (lb_line && cnt_lb_line == 0 && cnt_lbx < FB_WIDTH);

    // calculate framebuffer read address for linebuffer
    always_ff @(posedge clk_sys) begin
        if (line_sys) begin  // reset horizontal counter at start of line
            cnt_lbx <= 0;
        end else if (lb_en_in) begin  // increment address when LB enabled
            fb_addr_read <= fb_addr_read + 1;
            cnt_lbx <= cnt_lbx + 1;
        end
        if (frame_sys) fb_addr_read <= 0;  // reset address at frame start
    end

    // enable linebuffer output
    logic lb_en_out;
    localparam LAT_LB = 2;  // output latency compensation: lb_en_out+1, LB+1
    always_ff @(posedge clk_pix) begin
        lb_en_out <= (sy >= FB_OFFY && sy < (FB_HEIGHT * FB_SCALE) + FB_OFFY
            && sx >= FB_OFFX - LAT_LB && sx < (FB_WIDTH * FB_SCALE) + FB_OFFX - LAT_LB);
    end

    // display linebuffer
    logic [FB_DATAW-1:0] lb_colr_out;
    linebuffer_simple #(
        .DATAW(FB_DATAW),
        .LEN(FB_WIDTH)
    ) linebuffer_instance (
        .clk_sys,
        .clk_pix,
        .line,
        .line_sys,
        .en_in(lb_en_in),
        .en_out(lb_en_out),
        .scale(FB_SCALE),
        .data_in(fb_colr_read),
        .data_out(lb_colr_out)
    );

    logic [FB_DATAW-1:0] lb_colr_out_2;
    always_comb lb_colr_out_2 = lb_colr_out/2;

    // paint screen
    logic paint_area;  // high in area of screen to paint
    logic [COLRW-1:0] paint_colr;
    /* verilator lint_off UNUSED */
    logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
    /* verilator lint_on UNUSED */
    always_comb begin
        paint_colr = {lb_colr_out_2, lb_colr_out, lb_colr_out};
        paint_area = (sy >= FB_OFFY && sy < (FB_HEIGHT * FB_SCALE) + FB_OFFY
            && sx >= FB_OFFX && sx < FB_WIDTH * FB_SCALE + FB_OFFX);
        {paint_r, paint_g, paint_b} = (de && paint_area) ? paint_colr : 24'h001020;
    end

    // VGA Pmod output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        if (de) begin  // future improvement: dither output
            vga_r <= paint_r[7:4];
            vga_g <= paint_g[7:4];
            vga_b <= paint_b[7:4];
        end else begin  // VGA colour should be black in blanking interval
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
    end

    // show status with LEDs
    always_ff @(posedge clk_sys) begin
        led[3] <= render_busy;
        led[2] <= (state == HORIZONTAL);
        led[1] <= (state == VERTICAL);
        led[0] <= (state == ZOOM);
    end
endmodule
