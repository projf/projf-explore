# Maths - Verilog Library from Project F

Verilog maths designs used across Project F. Learn more at [projectf.io](https://projectf.io/) and follow [@WillFlux](https://twitter.com/WillFlux) for updates.

* Division
  * [div.sv](div.sv) - fixed point
  * [div_int.sv](div_int.sv) - integer
* Linear Feedback Shift Register: [lfsr.sv](lfsr.sv)
* Square Root
  * [sqrt.sv](sqrt.sv) - fixed point
  * [sqrt_int.sv](sqrt_int.sv) - integer
* Trigonometry
  * [sine_table.sv](sine_table.sv) - sine and cosine from ROM

You can find Vivado test benches in the [xc7](xc7) directory.

The following blog posts document and make use of these maths designs:

* [Ad Astra](https://projectf.io/posts/fpga-ad-astra/) - animated starfields using LFSR
* [Division](https://projectf.io/posts/division-in-verilog/) - simple division algorithm for integers and fixed-point
* [Sine Table](https://projectf.io/posts/fpga-sine-table/) - lookup sine and cosine from ROM
  * [sine2fmem](https://github.com/projf/fpgatools/tree/master/sine2fmem) - Python script to generate sine tables for ROM
* [Square Root](https://projectf.io/posts/square-root-in-verilog/) - calculate square roots for integers and fixed-point

For other library modules, see the main [Library README](../README.md).
