# Verilog Library from Project F

The Project F Library includes handy Verilog designs for everyone. You can freely build on these [MIT licensed](../LICENSE) designs for commercial and non-commercial projects. Have fun.

Discover the [background to the Library](https://projectf.io/posts/verilog-library-announcement/), follow [@WillFlux](https://twitter.com/WillFlux) for updates, and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

## Library Areas

* [clock](clock) - clock generation (PLL) and domain crossing
* [display](display) - display timings, framebuffer, DVI/HDMI output
* [essential](essential) - handy modules for many designs
* [graphics](graphics) - drawing lines and shapes
* [maths](maths) - divide, LFSR, square root...
* [memory](memory) - roms and ram designs, including BRAM
* [null](null) - null modules for linting
* [res](res) - resource files for testing

_NB. Documentation and test benches are still being added._

Our designs seek to be vendor-neutral, but some functionality requires
support for vendor primitives. We currently support two FPGA architectures:

* **XC7** - Xilinx 7 Series FPGAs, such as Spartan-7 and Artix-7
  * Uses: `BUFG`, `MMCME2_BASE`
  * TMDS (HDMI) uses: `OBUFDS`, `OSERDES2`
* **iCE40** - Lattice iCE40 FPGAs, such as iCE40 UltraPlus
  * Uses: `SB_IO`, `SB_PLL40_PAD`, `SB_SPRAM256KA`

We also infer block ram (BRAM), see [memory](memory).

Porting to other architectures should be straightforward.

## SystemVerilog?

We use a few simple features of SystemVerilog to make Verilog more pleasant:

* `logic` type to avoid deciding between `wire` and `reg` all the time
* `always_comb` and `always_ff` to make intent clear and catch mistakes
* `$clog2` to calculate vector widths (e.g. for addresses)
* `enum` to make finite state machines simpler to work with
* Matching names in module instances: `.clk_pix` instead of `.clk_pix(clk_pix)`

I believe these features are helpful, especially for beginners. All the SystemVerilog features used are compatible with recent versions of Verilator, Yosys, and Xilinx Vivado. However, if you need to use an older Verilog standard, you can adapt these designs without too much trouble.

For other designs from Project F, see the main [README](../README.md) or visit [projectf.io](https://projectf.io/).
