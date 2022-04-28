# Display Signals

This folder accompanies the Project F blog post: **[Display Signals](https://projectf.io/posts/display-signals/)**. These SystemVerilog designs demostrate the Project F display signal and CLUT modules. You can freely build on these [MIT licensed](../../LICENSE) designs. Have fun.

File layout:

* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards
* `xc7-hd` - experimental designs for Nexys Video and larger Xilinx 7 Series FPGAs

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules.

Included demos:

* TBC

Learn more about the designs and demos from _[Display Signals](https://projectf.io/posts/display-signals/)_, or read on for build instructions.

_Build instructions to follow._
