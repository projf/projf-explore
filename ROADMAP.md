# Project F Roadmap

This page summarises the plans for Project F over the next few months and in the longer term.  
Follow [@WillFlux](https://twitter.com/WillFlux) for updates and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

See [About Project F](https://projectf.io/about/) and the repo [README](README.md) for an introduction to Project F.

## During 2021

### FPGA Graphics

I will complete the [FPGA Graphics](graphics/) series ([blog](https://projectf.io/posts/fpga-graphics/)) by the end of 2021. All the important designs are in place, but I need to add some iCEBreaker versions, fix [bugs](https://github.com/projf/projf-explore/issues), and complete blog explanations for framebuffers.

### Maths & Algorithms Series

I plan to begin the next major blog series, covering Maths & Algorithms. The first part is due to cover the representation of numbers in Verilog. This series will incorporate existing designs for division, and square root etc.

### Module & Signal Naming

Project F module and signal naming aren't as consistent and straightforward as theys could be. Renaming things can be painful for users, but it's better done now while the project has relatively few forks.

I plan to make the following module name changes:

* `clock_gen_NNN.sv` to `clock_NNN.sv`
* `display_timings_NNN.sv` to `display_NNN.sv`
* `simple_display_timings_NNN.sv` to `simple_NNN.sv`

Where `NNN` is `480p`, `720p` etc. Xilinx `clock_480p` will also gain support for 5x clocks to match other display clocks.

I plan to standardise on the following signal names for memory/storage signals:

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

_Other names may be added to these lists during 2021._

## Future

These are some of the ideas for future content.

* Board Support
  * Add ULX3S (ECP5) support for _FPGA Graphics_
  * Complete Nexys Video support for _FPGA Graphics_
* Series
  * RISC-V CPU Designs
  * Serial Protocols
  * 3D Graphics
  * FPGA Languages: nMigen, SpinalHDL etc.
  * Formal Verification
