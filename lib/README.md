# Verilog Library from Project F

Verilog designs used across Project F.

This section of the repository is still being populated.

* [clock](clock) - clock generation (PLL) and domain crossing
* [display](display) - display timings, DVI, and HDMI output
* [essential](essential) - handy modules for many designs
* [maths](maths) - divide, LFSR, square root...
* [memory](memory) - roms and ram designs, including BRAM
* [null](null) - null modules for linting
* [res](res) - resource files for testing

_Documentation will be added shortly._

Our designs seek to be vendor-neutral, but some functionality requires
support for vendor primitives. We currently support two FPGA architectures:

* **XC7** - Xilinx Series 7 FPGAs, such as Spartan-7 and Arty-7
* **iCE40** - Lattice iCE40 FPGAs, such as iCE40 UltraPLus

Porting to other architectures should be straightforward.
