# Racing the Beam

This folder accompanies the Project F blog post: **[Racing the Beam](https://projectf.io/posts/racing-the-beam/)**. These SystemVerilog designs race the beam to create simple demos. You can freely build on these [MIT licensed](../../LICENSE) designs. Have fun.

File layout:

* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards
* `xc7-hd` - experimental designs for Nexys Video and larger Xilinx 7 Series FPGAs

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules used.

## Demos

* Raster Bars
* Hitomezashi
* Hello
* Colour Cycle
* Bounce

Learn more about the designs and demos from _[Racing the Beam](https://projectf.io/posts/racing-the-beam/)_, or read on for build instructions.

![](../../doc/img/rasterbars.png?raw=true "")

_Raster Bars running as a Verilator simulation._

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](https://yosyshq.net/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://bygone.clairexen.net/icestorm/).

You can get pre-built tool binaries for Linux, Mac, and Windows from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

For example, to build `rasterbars`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/racing-the-beam/ice40
make rasterbars
```

After the build completes, you'll have a bin file, such as `rasterbars.bin`. Use the bin file to program your board:

```shell
iceprog rasterbars.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If you have problems building the iCE40 designs, make sure you're using Yosys 0.10 or later.

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/racing-the-beam/xc7/vivado
source ./create_project.tcl
```

You can then build the demos as you would for any Vivado project.

### Other Xilinx 7 Series Boards

It's straightforward to adapt the project for other Xilinx 7 Series boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/graphics/racing-the-beam/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Verilator SDL Simulation

You can simulate these designs on your computer using Verilator and SDL. The [Simulation README](sim/README.md) has build instructions.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
