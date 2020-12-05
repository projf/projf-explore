# Common SystemVerilog Designs for Project F

This folder contains common SystemVerilog designs used by Project F, such as those in the **[Exploring FPGA Graphics](https://projectf.io/posts/fpga-graphics/)** series. All the designs are under the permissive [MIT licence](../LICENSE).

The main modules are as follows:

* Clock Generation: [XC7](xc7/clock_gen.sv) and [iCE40](ice40/clock_gen.sv)
* [Debounce](debounce.sv) - debounce buttons
* [Display Timings](display_timings.sv) - 640x480 VGA display timings
* [Linear-Feedback Shift Register](lfsr.sv) - Galois LFSR
* [Linebuffer](linebuffer.sv) - graphic scaling and CDC
* [Synchronous ROM](rom_sync.sv)

XC7 refers to Xilinx Series 7 FPGAs, such as Spartan-7 and Arty-7. iCE40 refers to Lattice iCE40 FPGAs, such as iCE40 UltraPLus.
