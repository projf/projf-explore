# Maths - Verilog Library

Maths Verilog designs from Project F, including division, square root, and transcendental functions. You can freely build on these [MIT licensed](../../LICENSE) designs for commercial and non-commercial projects. See the [Library](../) for other helpful Verilog modules or discover the [background to the Library](https://projectf.io/posts/verilog-library-announcement/).

Learn more at [projectf.io](https://projectf.io/), follow [@WillFlux](https://twitter.com/WillFlux) for updates, and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

## Verilog Modules

* Division
  * [div.sv](div.sv) - fixed point
  * [div_int.sv](div_int.sv) - integer
* Linear Feedback Shift Register: [lfsr.sv](lfsr.sv)
* Square Root
  * [sqrt.sv](sqrt.sv) - fixed point
  * [sqrt_int.sv](sqrt_int.sv) - integer
* Trigonometry
  * [sine_table.sv](sine_table.sv) - sine and cosine from ROM

Locate Vivado test benches in the [xc7](xc7) directory.  
Find other modules in the [Library](../).

## Blog Posts

The following blog posts document and make use of these maths designs:

* [Ad Astra](https://projectf.io/posts/fpga-ad-astra/) - animated starfields using LFSR
* [Division](https://projectf.io/posts/division-in-verilog/) - simple division algorithm for integers and fixed-point
* [Sine Table](https://projectf.io/posts/fpga-sine-table/) - lookup sine and cosine from ROM
  * [sine2fmem](https://github.com/projf/fpgatools/tree/master/sine2fmem) - Python script to generate sine tables for ROM
* [Square Root](https://projectf.io/posts/square-root-in-verilog/) - calculate square roots for integers and fixed-point

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
