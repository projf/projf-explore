# Project F Roadmap

This page summarises the plans for Project F.

Follow [@WillFlux](https://twitter.com/WillFlux) for updates and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

See [About Project F](https://projectf.io/about/) and the repo [README](README.md) for an introduction to Project F.

## 2022

I will announce plans for 2022 in the spring. In the meantime, I will continue to update and improve existing designs as described below.

## 2021

### FPGA Graphics

I will complete the [FPGA Graphics](graphics/) series ([blog](https://projectf.io/posts/fpga-graphics/)) by the end of 2021. All the important designs are in place, but I need to add some iCEBreaker versions, fix [bugs](https://github.com/projf/projf-explore/issues), and complete blog explanations for framebuffers.

Update December 2021: Minor updates continue. I still need to create a double-buffer for iCE40.

### Maths & Algorithms Series

I plan to begin the next major blog series, covering Maths & Algorithms. The first part is due to cover the representation of numbers in Verilog. This series will incorporate existing designs for division, and square root etc.

Update December 2021: This series started in autumn 2021 with [Numbers in Verilog](https://projectf.io/posts/numbers-in-verilog/) and [Multiplication with FPGA DSPs](https://projectf.io/posts/multiplication-fpga-dsps/). It will continue in spring 2022.

### Module & Signal Naming

Project F module and signal naming aren't as consistent and straightforward as they could be. Renaming things can be painful for users, but it's better done now while the project has relatively few forks.

I plan to make the following module name changes:

* `clock_gen_NNN.sv` to `clock_NNN.sv`
* `display_timings_NNN.sv` to `display_NNN.sv` - DONE
* `simple_display_timings_NNN.sv` to `simple_NNN.sv` - DONE

Where `NNN` is `480p`, `720p` etc. Xilinx `clock_480p` will also gain support for 5x clocks to match other display clocks.

I plan to standardise on the following signal names:

* `clk_FOO` - clock
  * `clk_pix`, `clk_sys`, `clk_100m`
* `cnt_FOO` - counter (with associated `FOO_NUM` parameter)
  * `cnt_line`, `cnt_shape`, `cnt_sprite`
* `FOO_id` - numerical identifier for a collection of things
  * `line_id`, `shape_id`, `sprite_id`

We use `clk` and `cnt` prefixes because these signals are treated differently.

For memory/storage signals:

* `addr` - single-port address
* `addr_write` - write address
* `addr_read` - read address
* `data_in` - data in
* `data_out` - data out

Control signals:

* `start` - start module process (if idle)
* `busy` - module is busy processing
* `done` - process is complete (high for one tick)
* `oe` - output enable
* `we` - write enable

And the following parameter names:

* `ADDRW` - address width
* `CORDW` - coordinate width
* `DATAW` - data width
* `DEPTH` - number of elements

_Other names may be added to these lists during 2021-22._

## Future

These are some of the ideas for future content.

* Board Support
  * Add ULX3S (ECP5) support for _FPGA Graphics_
  * Complete Nexys Video support for _FPGA Graphics_
* Series
  * RISC-V CPU Designs
  * Serial Protocols
  * 3D Graphics
  * Other Languages: Amaranth HDL, SpinalHDL etc.
  * Formal Verification
