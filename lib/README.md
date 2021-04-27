# Verilog Library from Project F

The Library includes handy Verilog designs from across Project F.

You can [learn the background to the Library](https://projectf.io/posts/verilog-library-announcement/) and follow [@WillFlux](https://twitter.com/WillFlux) for updates.

* [clock](clock) - clock generation (PLL) and domain crossing
* [display](display) - display timings, framebuffer, DVI/HDMI output
* [essential](essential) - handy modules for many designs
* [graphics](graphics) - drawing lines and shapes
* [maths](maths) - divide, LFSR, square root...
* [memory](memory) - roms and ram designs, including BRAM
* [null](null) - null modules for linting
* [res](res) - resource files for testing

_NB. Documentation is being added throughout April and May 2021._

Our designs seek to be vendor-neutral, but some functionality requires
support for vendor primitives. We currently support two FPGA architectures:

* **XC7** - Xilinx Series 7 FPGAs, such as Spartan-7 and Arty-7
* **iCE40** - Lattice iCE40 FPGAs, such as iCE40 UltraPlus

Porting to other architectures should be straightforward.

We use a few choice features of SystemVerilog to make Verilog more pleasant. I believe these features are helpful, especially for beginners. However, if you need to use an older Verilog standard, you can adapt these designs without too much trouble.
