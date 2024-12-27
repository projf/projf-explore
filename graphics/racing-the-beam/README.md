# Racing the Beam

This folder accompanies the Project F blog post: **[Racing the Beam](https://projectf.io/posts/racing-the-beam/)**. These SystemVerilog designs race the beam to create simple demos. You can freely build on these [MIT licensed](../../LICENSE) designs. Have fun.

File layout:

* `ecp5` - designs for ULX3S and other Lattice ECP5 boards with DVI output
* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards with VGA output
* `xc7-dvi` - designs for Nexys Video and other Xilinx 7 Series boards with DVI output

These designs make use of modules from the [Project F library](../../lib/).

Jump to build instructions for: [Arty](#arty-build) | [iCEBreaker](#icebreaker-build) | [Nexys Video](#nexys-video-build) | [ULX3S](#ulx3s-build) | [Verilator](sim/README.md)

## Demos

* Raster Bars - `rasterbars`
* Hitomezashi - `hitomezashi`
* Hello - `hello`
* Colour Cycle - `colour_cycle`
* Bounce - `bounce`

Learn more about the designs and demos from _[Racing the Beam](https://projectf.io/posts/racing-the-beam/)_, or read on for build instructions.

![](../../doc/img/rasterbars.png?raw=true "")

_Raster Bars running as a Verilator simulation._

## Arty Build

To create a Vivado project for the Digilent Artyå ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/racing-the-beam/xc7/vivado
source ./create_project.tcl
```

You can then build the designs as you would for any Vivado project. These designs run at 640x480 on the Arty.

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
cd projf-explore/graphics/racing-the-beam/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](https://yosyshq.net/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](https://github.com/YosysHQ/icestorm).

You can get pre-built binaries for Linux, Mac, and Windows from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build).

For example, to build `rasterbars`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/racing-the-beam/ice40
make rasterbars
```

After the build completes, you'll have a bin file, such as `rasterbars.bin`. Use the bin file to program your board:

```shell
iceprog rasterbars.bin
```

These designs run at 640x480 on the iCEBreaker.

### Tested Versions

The iCE40 designs have been tested with:

* OSS CAD Suite 2023-03-01

## Nexys Video Build

To create a Vivado project for the Digilent [Nexys Video](https://digilent.com/reference/programmable-logic/nexys-video/reference-manual); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/racing-the-beam/xc7-dvi/vivado
source ./create_project.tcl
```

You can then build the designs as you would for any Vivado project. These designs run at 1280x720 on the Nexys Video.

### Tested Versions

The Nexys Video designs have been tested with:

* Vivado 2022.2

## ULX3S Build

I have tested these designs with recent (late 2024) versions of Yosys and nextpnr. You can get pre-built binaries for Linux, Mac, and Windows from [YosysHQ OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

Once the tools are installed, it's straightforward to build the designs.

For example, to build `rasterbars`; clone the projf-explore git repo, check the correct FPGA model is set near the top of `projf-explore/graphics/racing-the-beam/ecp5/Makefile` then:

```shell
cd projf-explore/graphics/racing-the-beam/ecp5
make rasterbars
```

After the build completes, you'll have a bit file, such as `rasterbars.bit`. Use the bit file to program your board:

```shell
openFPGALoader --board=ulx3s rasterbars.bit
```

These designs run at 1280x720 on the ULX3S.

For advice on board programming without root, see the [FPGA Graphics README](../fpga-graphics/README.md#board-programming-without-root).

## Verilator SDL Simulation

You can simulate these designs on your computer using Verilator and SDL. The [Simulation README](sim/README.md) has build instructions.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
