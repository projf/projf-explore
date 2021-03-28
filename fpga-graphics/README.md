# Exploring FPGA Graphics

This folder contains SystemVerilog designs to accompany the Project F blog post: **[Exploring FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**.

These designs make use of Project F [common modules](../common/), such as clock generation and display timings. Check the included iCE40 [makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) script to see which modules are used.

All the designs are under the permissive [MIT licence](../LICENSE), but the blog post is subject to normal copyright restrictions.

## iCEBreaker Build

You can build projects for iCEBreaker using the included [makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). If you don't already have these tools, you can get pre-built binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you'd rather build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/). Once you have a working toolchain, you're ready to build Project F designs.

For example, to build `top_bounce`; clone the projf-explore git repo, then:

```bash
cd projf-explore/fpga-graphics/ice40
make top_bounce
```

After the build completes you'll have a bin file, such as `top_bounce.bin`. Use the bin file to program your board:

```bash
iceprog top_bounce.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Xilinx Vivado Build

To create a Vivado project for the **Digilent Arty** (original or A7-35T); clone the projf-explore git repo, then start Vivado and run the following in the tcl console:

```tcl
cd projf-explore/fpga-graphics/xc7/vivado
source ./create_project.tcl
```

You can then build `top_bounce`, `top_beam`, or `top_square` as you would for any Vivado project.

### Simulation

This design includes test benches for the `clock_gen_480p` and `display_timings_480p` modules. You can run the test bench simulations from the GUI under the "Flow" menu or from the TCL console with:

```tcl
launch_simulation
run all
```

By default the `display_timings_480p` test bench is simulated, but you can switch to the `clock_gen_480p` test bench with:

```tcl
set fs_sim_obj [get_filesets sim_1]
set_property -name "top" -value "clock_gen_480p_tb" -objects $fs_sim_obj
relaunch_sim
run all
```

### Other Xilinx Series 7 Boards

It's straightforward to adapt the project for other Xilinx Series 7 boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/fpga-graphics/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs:

```bash
$ ./fpga-graphics/lint.sh
## Linting top modules in ./fpga-graphics/xc7
##   Checking ./fpga-graphics/xc7/top_beam.sv
##   Checking ./fpga-graphics/xc7/top_bounce.sv
##   Checking ./fpga-graphics/xc7/top_square.sv
## Linting top modules in ./fpga-graphics/ice40
##   Checking ./fpga-graphics/ice40/top_beam.sv
##   Checking ./fpga-graphics/ice40/top_bounce.sv
##   Checking ./fpga-graphics/ice40/top_square.sv
```

You can learn more about this from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).
