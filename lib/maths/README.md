# Maths - Verilog Library

Maths Verilog designs from [Project F](https://projectf.io), including division, square root, and transcendental functions. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* Division
  * **[div.sv](div.sv)** - signed fixed-point with Gaussian rounding
  * **[divu.sv](divu.sv)** - unsigned fixed-point that rounds towards zero
  * **[divu_int.sv](divu_int.sv)** - unsigned integer with remainder
* Linear Feedback Shift Register: **[lfsr.sv](lfsr.sv)**
* Multiplication: **[mul.sv](mul.sv)** - signed fixed-point with Gaussian rounding
* Square Root
  * **[sqrt.sv](sqrt.sv)** - fixed point
  * **[sqrt_int.sv](sqrt_int.sv)** - integer
* Trigonometry
  * **[sine_table.sv](sine_table.sv)** - sine and cosine from lookup table (ROM)

## Test Benches

Modules in the Verilog library have test benches for cocotb and/or Vivado. Cocotb test bench coverage will expand during 2023.

### cocotb

You can find [cocotb](https://www.cocotb.org) test benches using [Icarus Verilog](http://iverilog.icarus.com) in the [test](test) directory. Use the included Makefile to run tests.

Some tests use the Simple Python Fixed-Point Module: [spfpm](https://pypi.org/project/spfpm/)

Add the following to a Verilog module to generate a VCD waveform file from cocotb test benches:

```verilog
// generate waveform file with cocotb
`ifdef COCOTB_SIM
initial begin
    $dumpfile($sformatf("%m.vcd"));
    $dumpvars;
end
`endif
```

### Vivado

You can find Vivado test benches in the [xc7](xc7) directory. Associated waveform configuration is in [xc7/vivado](xc7/vivado).

## Blog Posts

The following blog posts document and make use of these maths designs:

* [Ad Astra](https://projectf.io/posts/fpga-ad-astra/) - animated starfields using LFSR
* [Division](https://projectf.io/posts/division-in-verilog/) - explains how the division algorithms work
* [Sine Table](https://projectf.io/posts/fpga-sine-table/) - lookup sine and cosine from ROM
  * [sine2fmem](https://github.com/projf/fpgatools/tree/master/sine2fmem) - Python script to generate sine tables for ROM
* [Square Root](https://projectf.io/posts/square-root-in-verilog/) - calculate square roots for integers and fixed-point

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
