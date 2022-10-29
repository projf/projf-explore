// (C) 2022 Tristan Itschner

// See DVI 1.0 spec, page 28 for implementation details.

`default_nettype none

module tmds_8b_10b(
	input  logic       clk,
	input  logic [7:0] d,
	input  logic [1:0] c,
	input  logic       de,
	output logic [9:0] q
);

logic signed [4:0] cnt = 0;

function [3:0] n0 (logic [7:0] x);
	n0 = 0;
	for (int i = 0; i < 8; i++) 
		if (!x[i])
			n0 = n0 + 1;
endfunction

function [3:0] n1 (logic [7:0] x);
	n1 = 0;
	for (int i = 0; i < 8; i++) 
		if (x[i])
			n1 = n1 + 1;
endfunction

logic [8:0] q_m;
always_comb
	if (n1(d) > 4 || (n1(d) == 4 && d[0] == 0)) begin
		q_m[0] = d[0];
		for (int i = 0; i <= 6; i++) 
			q_m[i + 1] = ~(q_m[i] ^ d[i + 1]);
		q_m[8] = 0;
	end else begin
		q_m[0] = d[0];
		for (int i = 0; i <= 6; i++) 
			q_m[i + 1] = (q_m[i] ^ d[i + 1]);
		q_m[8] = 1;
	end

always_ff @(posedge clk)
	if (!de) begin
		case (c)
			2'b00: q[9:0] <= 10'b1101010100;
			2'b01: q[9:0] <= 10'b0010101011;
			2'b10: q[9:0] <= 10'b0101010100;
			2'b11: q[9:0] <= 10'b1010101011;
		endcase
	end else
		if (cnt == 0 || n1(q_m[7:0]) == n0(q_m[7:0])) begin
			q[9] <= ~q[8];
			q[8] <=  q[8];
			q[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];
			if (q_m[8])
				cnt <= cnt + n1(q_m[7:0]) - n0(q_m[7:0]);
			else
				cnt <= cnt + n0(q_m[7:0]) - n1(q_m[7:0]);
		end else if ((cnt > 0 && n1(q_m[7:0]) > n0(q_m[7:0])) 
			|| (cnt < 0 && n0(q_m[7:0]) > n1(q_m[7:0]))) begin
				q[9] <= 1;
				q[8] <= q_m[8];
				q[7:0] <= ~q_m[7:0];
				cnt <= cnt + 2*q_m[8] + n0(q_m[7:0]) - n1(q_m[7:0]);
			end else begin
				q[9] <= 0;
				q[8] <= q_m[8];
				q[7:0] <= q_m[7:0];
				cnt <= cnt - 2*q_m[8] + n1(q_m[7:0]) - n0(q_m[7:0]);
			end

endmodule
