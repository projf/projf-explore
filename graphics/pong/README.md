# FPGA Pong

This folder accompanies the Project F blog post: **[FPGA Pong](https://projectf.io/posts/fpga-pong/)**. These SystemVerilog designs recreate the arcade classic in logic. You can freely build on this [MIT licensed](../../LICENSE) design. Have fun.

File layout:

* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules used.

Learn more about the designs and demos from _[FPGA Pong](https://projectf.io/posts/fpga-pong/)_, or read on for build instructions.

![](../../doc/img/pong-verilator-sdl.png?raw=true "")

_Pong running as a Verilator simulation on macOS._

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](https://yosyshq.net/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](https://github.com/YosysHQ/icestorm).

You can get pre-built binaries for Linux, Mac, and Windows from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build).

To build `pong`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/pong/ice40
make pong
```

After the build completes, you'll have a bin file `pong.bin`. Use the bin file to program your board:

```shell
iceprog pong.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

The game controls for iCEBreaker:

* **Button 3** - up
* **Button 2** - start (fire)
* **Button 1** - down

### Tested Versions

The iCE40 designs have been tested with:

* OSS CAD Suite 2023-03-01

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/pong/xc7/vivado
source ./create_project.tcl
```

You can then build Pong as you would any Vivado project.

The game controls for Arty:

* **BTN2** - up
* **BTN1** - start (fire)
* **BTN0** - down

### Tested Versions

The Arty designs have been tested with:

* Vivado 2022.2

### Other Xilinx 7 Series Boards

It's straightforward to adapt the project for other Xilinx 7 Series boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/graphics/pong/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Verilator SDL Simulation

You can simulate these designs on your computer using Verilator and SDL. The [Simulation README](sim/README.md) has build instructions.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
