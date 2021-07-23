# Pong

This folder contains designs to accompany the Project F blog post: **[Pong](https://projectf.io/posts/fpga-pong/)**.

These designs make use of [clock generation](../../lib/clock) from the [Project F library](../../lib/).

Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see all the files used in these designs.

## iCEBreaker Build

You can build projects for iCEBreaker using the included [makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). If you don't already have these tools, you can get pre-built binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you'd rather build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/). Once you have a working toolchain, you're ready to build Project F designs.

For example, to build `top_pong`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/pong/ice40
make top_pong
```

After the build completes you'll have a bin file, such as `top_pong.bin`. Use the bin file to program your board:

```shell
iceprog top_pong.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Xilinx Vivado Build

To create a Vivado project for the **Digilent Arty** (original or A7-35T); clone the projf-explore git repo, then start Vivado and run the following in the Tcl Console:

```tcl
cd projf-explore/graphics/pong/xc7/vivado
source ./create_project.tcl
```

You can then build `top_pong` etc. as you would for any Vivado project.

NB. You can safely ignore Vivado warnings about unused button constraints when building top_pong_v1 to v3: `No port matched btn_` and `set_property expects at least one object`.

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

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).
