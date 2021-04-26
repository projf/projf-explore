// Project F Library - Division (Fixed-Point) Test Bench (XC7)
// (C)2021 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

module div_tb();

    parameter CLK_PERIOD = 10;  // 10 ns == 100 MHz
    parameter WIDTH = 8;
    parameter FBITS = 4;
    parameter SF = 2.0**-4.0;  // Q4.4 scaling factor is 2^-4

    logic clk;
    logic start;            // start signal
    logic busy;             // calculation in progress
    logic valid;            // quotient and remainder are valid
    logic dbz;              // divide by zero flag
    logic ovf;              // overflow flag (fixed-point only)
    logic [WIDTH-1:0] x;    // dividend
    logic [WIDTH-1:0] y;    // divisor
    logic [WIDTH-1:0] q;    // quotient
    logic [WIDTH-1:0] r;    // remainder

    div #(.WIDTH(WIDTH), .FBITS(FBITS)) div_inst (.*);

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        $monitor("\t%d:\t%f / %f = %b (%f) (r = %b) (V=%b) (DBZ=%b) (OVF=%b)",
            $time, x*SF, y*SF, q, q*SF, r, valid, dbz, ovf);
    end

    initial begin
                clk = 1;

        #100    x = 8'b0011_0000;  // 3.0
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0010_0000;  // 2.0
                y = 8'b0001_0110;  // 1.375 (the largest number that's ≤√2 in Q4.4)
                start = 1;
        #10     start = 0;

        #120    x = 8'b0010_0000;  // 2.0
                y = 8'b0000_0000;  // 0.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0000_0000;  // 0.0
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b0000_0010;  // 0.125
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b1000_0000;  // 8.0
                y = 8'b0000_0100;  // 0.25
                start = 1;
        #10     start = 0;

        #120    x = 8'b1111_1110;  // 15.875
                y = 8'b0010_0000;  // 2.0
                start = 1;
        #10     start = 0;

        #120    x = 8'b1000_0000;  // 8.0
                y = 8'b1001_0000;  // 9.0
                start = 1;
        #10     start = 0;

        // ...
    end
endmodule
