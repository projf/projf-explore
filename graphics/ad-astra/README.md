# Ad Astra

This folder contains SystemVerilog designs to accompany the Project F blog post: **[Ad Astra](https://projectf.io/posts/fpga-ad-astra/)**. You can freely build on these [MIT licensed](../../LICENSE) designs for commercial and non-commercial projects. Have fun.

Included demos for iCEBreaker and Arty FPGA boards:

* `top_lfsr` - simple background using a linear feedback register (LFSR)
* `top_starfield` - layered starfields using multiple LFSRs
* `top_space_f` - 'F' character overlaid on starfield using sprite
* `top_hello_en` - multiple sprites spell "Hello" on starfield
* `top_hello_jp` - multiple sprites spell "こんにちは" on starfield
* `top_greet_v1` - greetings to open source hardware projects
* `top_greet` - greetings to open source hardware projects with copper colours

Learn more about these demos from the [Ad Astra](https://projectf.io/posts/fpga-ad-astra/) blog post, or read on for build instructions.

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the included modules.

The included fonts are distributed under different licences: see the individual font files for details.

New to graphics development on FPGA? Check out our [introduction to FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). 

You can get pre-built tool binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

For example, to build `top_greet`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/ad-astra/ice40
make top_greet
```

After the build completes, you'll have a bin file, such as `top_greet.bin`. Use the bin file to program your board:

```shell
iceprog top_greet.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/ad-astra/xc7/vivado
source ./create_project.tcl
```

You can then build `top_greet`, `top_hello_jp` etc. as you would for any Vivado project. You'll also need the [Pmod VGA](https://reference.digilentinc.com/reference/pmod/pmodvga/reference-manual) to drive your screen.

### Other Xilinx 7 Series Boards

It's straightforward to adapt the project for other Xilinx 7 Series boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/graphics/ad-astra/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
