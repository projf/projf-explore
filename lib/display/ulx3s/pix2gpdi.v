// 
// This is based upon https://github.com/BrunoLevy/learn-fpga with some minor
// renamings.
// Path: learn-fpga/Basic/ULX3S/ULX3S_hdmi/HDMI_test_hires.v
//

`default_nettype none

module pix2gpdi(
	// comments are for 640 x 480
	input wire clk_pix, // ~25 MHz
		input wire clk_tmds_half, // 5* clk_pix, ~ 125 MHz, must be phase aligned
		input wire [7:0] red,
		input wire [7:0] green,
		input wire [7:0] blue,
		input wire de,
		input wire hsync,
		input wire vsync,

		// output wire
		output wire [3:0] gpdi_dp
	);

	/******** RGB TMDS encoding ***************************************************/
	// Generate 10-bits TMDS red,green,blue signals. Blue embeds HSync/VSync in its 
	// control part.
	wire [9:0] tmds_red, tmds_green, tmds_blue;
	tmds_encoder encode_R(.clk(clk_pix), .VD(red  ), .CD(2'b00)        , .VDE(de), .TMDS(tmds_red));
	tmds_encoder encode_G(.clk(clk_pix), .VD(green), .CD(2'b00)        , .VDE(de), .TMDS(tmds_green));
	tmds_encoder encode_B(.clk(clk_pix), .VD(blue ), .CD({vsync,hsync}), .VDE(de), .TMDS(tmds_blue));

	reg [4:0] tmds_mod5=1;
	always @(posedge clk_tmds_half) tmds_mod5 <= {tmds_mod5[3:0],tmds_mod5[4]};
	wire tmds_shift_load = tmds_mod5[4];

// Shifter now shifts two bits at each clock
reg [9:0] tmds_shift_red=0, tmds_shift_green=0, tmds_shift_blue=0;
always @(posedge clk_tmds_half) begin
	tmds_shift_red   <= tmds_shift_load ? tmds_red   : tmds_shift_red  [9:2];
	tmds_shift_green <= tmds_shift_load ? tmds_green : tmds_shift_green[9:2];
	tmds_shift_blue  <= tmds_shift_load ? tmds_blue  : tmds_shift_blue [9:2];
end

// DDR serializers: they send D0 at the rising edge and D1 at the falling edge.
ODDRX1F ddr_red  (.D0(tmds_shift_red[0]),   .D1(tmds_shift_red[1]),   .Q(gpdi_dp[2]), .SCLK(clk_tmds_half), .RST(1'b0));
ODDRX1F ddr_green(.D0(tmds_shift_green[0]), .D1(tmds_shift_green[1]), .Q(gpdi_dp[1]), .SCLK(clk_tmds_half), .RST(1'b0));
ODDRX1F ddr_blue (.D0(tmds_shift_blue[0]),  .D1(tmds_shift_blue[1]),  .Q(gpdi_dp[0]), .SCLK(clk_tmds_half), .RST(1'b0));

// The pixel clock is sent through the fourth differential pair.
assign gpdi_dp[3] = clk_pix;

endmodule
