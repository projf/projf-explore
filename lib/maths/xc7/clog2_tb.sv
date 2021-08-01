// Project F Library - $clog2 Test Bench (XC7)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

module clog2_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz

    logic clk;
    logic rst;
    logic [7:0] num, clog_num;

    always_ff @(posedge clk) begin
        num <= num + 1;
        if (rst) num <= 0;
    end

    always_comb clog_num = $clog2(num);

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial $monitor("$clog2(%d) = %d", num, clog_num);

    initial begin
        clk = 1;
        rst = 1;

        #100 rst = 0;
        #2560 $finish();
    end
endmodule
