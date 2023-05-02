// Project F Library - TMDS Encoder for DVI
// (C)2023 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module tmds_encoder_dvi (
    input   wire logic clk_pix,
    input   wire logic rst_pix,
    input   wire logic [7:0] data_in,  // colour data
    input   wire logic [1:0] ctrl_in,  // control data
    input   wire logic de,             // data enable
    output       logic [9:0] tmds      // encoded TMDS data
    );

    // select basic encoding based on the ones in the input data
    logic [3:0] data_1s;
    logic use_xnor;
    always_comb begin
        /* verilator lint_off WIDTH */
        data_1s = data_in[0] + data_in[1] + data_in[2] + data_in[3] + 
                    data_in[4] + data_in[5] + data_in[6] + data_in[7];
        /* verilator lint_on WIDTH */
        use_xnor = (data_1s > 4'd4) || ((data_1s == 4'd4) && (data_in[0] == 0));
    end
     
    // encode colour data with xor/xnor
    integer i;
    logic [8:0] enc_qm;
    always_comb begin
        enc_qm[0] = data_in[0];
        for (i=0; i<7; i=i+1) begin
            /* verilator lint_off ALWCOMBORDER */
            enc_qm[i+1] = (use_xnor) ? (enc_qm[i] ~^ data_in[i+1]) : (enc_qm[i] ^ data_in[i+1]);
            /* verilator lint_on ALWCOMBORDER */
        end
        enc_qm[8] = (use_xnor) ? 0 : 1;
    end

    // disparity in encoded data for DC balancing: needs to cover -8 to +8
    logic signed [4:0] ones, zeros, balance;
    always_comb begin
        /* verilator lint_off WIDTH */
        ones = enc_qm[0] + enc_qm[1] + enc_qm[2] + enc_qm[3] + 
                    enc_qm[4] + enc_qm[5] + enc_qm[6] + enc_qm[7];
        /* verilator lint_on WIDTH */
        zeros   = 5'd8 - ones;
        balance = ones - zeros;
    end

    // record ongoing DC bias
    logic signed [4:0] bias;
    always_ff @ (posedge clk_pix) begin
        if (de == 0) begin  // send control data in blanking interval
            case (ctrl_in)  // ctrl sequences (always have 7 transitions)
                2'b00:   tmds <= 10'b1101010100;
                2'b01:   tmds <= 10'b0010101011;
                2'b10:   tmds <= 10'b0101010100;
                default: tmds <= 10'b1010101011;
            endcase
            bias <= 5'sb00000;
        end else begin  // send pixel colour data (at most 5 transitions)
            if (bias == 0 || balance == 0) begin  // no prior bias or disparity
                if (enc_qm[8] == 0) begin
                    $display("\t%d %b %d, %d, A1", data_in, enc_qm, ones, bias);
                    tmds[9:0] <= {2'b10, ~enc_qm[7:0]};
                    bias <= bias - balance;
                end else begin
                    $display("\t%d %b %d, %d, A0", data_in, enc_qm, ones, bias);
                    tmds[9:0] <= {2'b01, enc_qm[7:0]};
                    bias <= bias + balance;
                end
            end
            else if ((bias > 0 && balance > 0) || (bias < 0 && balance < 0)) begin
                $display("\t%d %b %d, %d, B1", data_in, enc_qm, ones, bias);
                tmds[9:0] <= {1'b1, enc_qm[8], ~enc_qm[7:0]};
                bias <= bias + {3'b0, enc_qm[8], 1'b0} - balance;
            end else begin
                $display("\t%d %b %d, %d, B0", data_in, enc_qm, ones, bias);
                tmds[9:0] <= {1'b0, enc_qm[8], enc_qm[7:0]};
                bias <= bias - {3'b0, ~enc_qm[8], 1'b0} + balance;
            end
        end

        if (rst_pix) begin
            tmds <= 10'b1101010100;  // equivalent to ctrl 2'b00
            bias <= 5'sb00000;
        end
    end
endmodule
