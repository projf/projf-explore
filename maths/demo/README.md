# Maths Demo

This folder accompanies the Project F series: **[Maths and Algorithms with FPGAs](https://projectf.io/posts/numbers-in-verilog/)**. These SystemVerilog maths demos let your visualize many of the concepts we cover. You can freely build on these [MIT licensed](../../LICENSE) designs for commercial and non-commercial projects. Have fun.

_Demos under construction. Please be patient._

File layout:

* `xc7-hd` - designs for Nexys Video and larger Xilinx 7 Series FPGAs
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)

The following directories will be added as the designs are created:

* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `xc7` - designs for Arty and other Xilinx 7 Series boards
* `res` - resources: colour palettes

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules.

Included demos:

* `top_graphing` - graph a mathematical function

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). 

You can get pre-built tool binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

For example, to build `top_graphing`; clone the projf-explore git repo, then:

```shell
cd projf-explore/maths/demos/ice40
make top_graphing
```

After the build completes, you'll have a bin file, such as `top_graphing.bin`. Use the bin file to program your board:

```shell
iceprog top_graphing.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/maths/demos/xc7/vivado
source ./create_project.tcl
```

You can then build `top_graphing` etc. as you would for any Vivado project.

### Other Xilinx 7 Series Boards

It's straightforward to adapt the project for other Xilinx 7 Series boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/maths/demos/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
