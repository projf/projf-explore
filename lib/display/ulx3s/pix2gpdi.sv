// (C) 2022 Tristan Itschner

module pix2gpdi(
	input  logic       clk_pix, clk_tmds_half,
	input  logic [7:0] r, g, b,
	input  logic       de, hs, vs,
	output logic [3:0] gpdi_dp
);

logic [9:0] tmds_r, tmds_g, tmds_b;

tmds_8b_10b encode_R(.clk(clk_pix), .d(r), .c(2'b00)  , .de(de), .q(tmds_r));
tmds_8b_10b encode_G(.clk(clk_pix), .d(g), .c(2'b00)  , .de(de), .q(tmds_g));
tmds_8b_10b encode_B(.clk(clk_pix), .d(b), .c({vs,hs}), .de(de), .q(tmds_b));

// register stage to improve timing
logic [9:0] r_tmds_r, r_tmds_g, r_tmds_b;
always_ff @(posedge clk_pix)
	{r_tmds_r, r_tmds_g, r_tmds_b} <= {tmds_r, tmds_g, tmds_b};

// use shift registers as counter to 5
// we start in position 2 due to register stage above
logic [4:0] mod5 = 2;
always_ff @(posedge clk_tmds_half)
	mod5 <= {mod5[3:0], mod5[4]};
logic load = mod5[4];

// shift two lowest bits every cycle
logic [9:0] shift_r, shift_g, shift_b;
always @(posedge clk_tmds_half) begin
		shift_r <= load ? r_tmds_r : {2'b0, shift_r[9:2]};
		shift_g <= load ? r_tmds_g : {2'b0, shift_g[9:2]};
		shift_b <= load ? r_tmds_b : {2'b0, shift_b[9:2]};
	end

// ddr primitive
ODDRX1F ddr_r(.D0(shift_r[0]), .D1(shift_r[1]), .Q(gpdi_dp[2]), .SCLK(clk_tmds_half), .RST(1'b0));
ODDRX1F ddr_g(.D0(shift_g[0]), .D1(shift_g[1]), .Q(gpdi_dp[1]), .SCLK(clk_tmds_half), .RST(1'b0));
ODDRX1F ddr_b(.D0(shift_b[0]), .D1(shift_b[1]), .Q(gpdi_dp[0]), .SCLK(clk_tmds_half), .RST(1'b0));

assign gpdi_dp[3] = clk_pix;

endmodule
