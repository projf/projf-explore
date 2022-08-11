# Project F Roadmap

This doc summarises forthcoming work on Project F.

Follow [@WillFlux](https://twitter.com/WillFlux) for updates and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

See [About Project F](https://projectf.io/about/) and the repo [README](README.md) for an introduction to Project F.

## 2022

_New roadmap coming autumn 2022._

### FPGA Graphics

I am revising the [FPGA Graphics](graphics/) series ([blog](https://projectf.io/posts/fpga-graphics/)). All the important designs are in place, but I need to roll out the framebuffer design, fix [bugs](https://github.com/projf/projf-explore/issues), and complete blog explanations framebuffer and drawing blogs.

### Maths & Algorithms Series

This series started in autumn 2021 with [Numbers in Verilog](https://projectf.io/posts/numbers-in-verilog/) and [Multiplication with FPGA DSPs](https://projectf.io/posts/multiplication-fpga-dsps/). This series will incorporate existing designs for division, and square root etc. and will continue during 2022.

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
* `LAT_` - latency in cycles (prefix)

_Other names may be added to these lists in due course._

## Future

These are some of the ideas for future content.

* Board Support
  * Add ULX3S (ECP5) support for _FPGA Graphics_
  * Complete Nexys Video support for _FPGA Graphics_
* Series
  * RISC-V CPU Designs
  * Serial Protocols (UART, PS/2, SPI, I2C)
  * Audio Synth
  * 3D Graphics
  * Other Languages: Amaranth HDL, SpinalHDL etc.
  * Formal Verification
