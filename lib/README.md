# Verilog Library from Project F

The [Project F](https://projectf.io) Library includes handy Verilog designs for everyone. You can freely build on these [MIT licensed](../LICENSE) designs. Get an overview from the [Verilog Library blog](https://projectf.io/verilog-lib/) or dive into the designs.

## Library Areas

* [clock](clock) - clock generation (PLL) and domain crossing
* [display](display) - display timings, framebuffer, DVI/HDMI output
* [essential](essential) - handy modules for many designs
* [graphics](graphics) - drawing lines and shapes
* [maths](maths) - divide, LFSR, square root...
* [memory](memory) - roms and ram designs, including BRAM
* [null](null) - null modules for linting
* [res](res) - palettes, fonts, and resource files for testing
* [uart](uart) - UART (serial) transmitter/receiver

_NB. Documentation and test benches are still being added._

### FPGA Architecture

Our designs seek to be vendor-neutral, but some functionality requires
support for vendor primitives. We currently support two FPGA architectures:

* **XC7** - Xilinx 7 Series FPGAs, such as Spartan-7 and Artix-7
  * `BUFG`, `MMCME2_BASE`
  * HDMI support: `OBUFDS`, `OSERDES2`
* **iCE40** - Lattice iCE40 FPGAs, such as iCE40 UltraPlus
  * `SB_IO`, `SB_PLL40_PAD`, `SB_SPRAM256KA`

We also infer block ram (BRAM), see [memory](memory).

Porting to other architectures should be straightforward.

## SystemVerilog?

We use a few simple features of SystemVerilog to make Verilog more pleasant:

* `logic` type is safer and less work than using `wire` and `reg`
* `always_comb` and `always_ff` to make intent clear and catch mistakes
* `$clog2` to calculate vector widths (e.g. for addresses)
* `enum` to make finite state machines simpler to work with
* Matching names in module instances: `.clk_pix` instead of `.clk_pix(clk_pix)`

I believe these features are helpful, especially for beginners. All the SystemVerilog features used are compatible with recent versions of Verilator, Yosys, and Xilinx Vivado. However, if you need to use an older Verilog standard, you can adapt these designs without too much trouble.

For other designs from Project F, see the main [README](../README.md) or visit [projectf.io](https://projectf.io/).

## Resource Licences

Resources in this repository, such as fonts and palettes, may have their own licences. In such cases, the licence is clearly stated at the top of each file. For example, GNU Unifont in `lib/res/fonts/font_unifont_8x16.mem`.
