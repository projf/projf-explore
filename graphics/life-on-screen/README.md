# Life on Screen

This folder contains SystemVerilog designs to accompany the Project F blog post: **[Life on Screen](https://projectf.io/posts/life-on-screen/)**.

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the included modules.

## iCEBreaker Build

You can build projects for iCEBreaker using the included [Makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). If you don't already have these tools, you can get pre-built binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you'd rather build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/). Once you have a working toolchain, you're ready to build Project F designs.

For example, to build `top_life`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/life-on-screen/ice40
make top_life
```

After the build completes you'll have a bin file, such as `top_life.bin`. Use the bin file to program your board:

```shell
iceprog top_life.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Xilinx Vivado Build

To create a Vivado project for the **Digilent Arty** (original or A7-35T); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/life-on-screen/xc7/vivado
source ./create_project.tcl
```

You can then build `top_life` as you would for any Vivado project.

### Simulation

This design includes a test bench for the life module. You can run the test bench simulation from the GUI under the "Flow" menu or from the Tcl console with:

```tcl
launch_simulation
run all
```

### Other Xilinx 7 Series Boards

It's straightforward to adapt the project for other Xilinx 7 Series boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/graphics/life-on-screen/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
