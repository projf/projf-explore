# FPGA Graphics

This folder contains SystemVerilog designs to accompany the Project F blog post: **[FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**. You can freely build on these [MIT licensed](../../LICENSE) designs for commercial and non-commercial projects. Have fun.

Directory layout:

* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `xc7-hd` - experimental designs for Nexys Video and larger Xilinx 7 Series FPGAs
* `xc7` - designs for Arty and other Xilinx 7 Series boards
* `verilator` - simulation of designs with Verilator and LibSDL; see [Verilator README](verilator/README.md)

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the included modules.

Included demos:

* `top_square` - static coloured square
* `top_beam` - animated square
* `top_bounce` - bouncing red, green, and blue squares overlap

Learn more about these demos from the [FPGA Graphics](https://projectf.io/posts/fpga-graphics/) blog post, or read on for build instructions.

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). 

You can get pre-built tool binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

For example, to build `top_bounce`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/fpga-graphics/ice40
make top_bounce
```

After the build completes, you'll have a bin file, such as `top_bounce.bin`. Use the bin file to program your board:

```shell
iceprog top_bounce.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/fpga-graphics/xc7/vivado
source ./create_project.tcl
```

You can then build `top_bounce`, `top_beam`, or `top_square` as you would for any Vivado project.

### Behavioural Simulation

This design includes test benches for the `clock_gen_480p` and `simple_display_timings_480p` modules. You can run the test bench simulations from the GUI under the "Flow" menu or from the Tcl Console with:

```tcl
launch_simulation
run all
```

By default the `simple_display_timings_480p` test bench is simulated, but you can switch to the `clock_gen_480p` test bench with:

```tcl
set fs_sim_obj [get_filesets sim_1]
set_property -name "top" -value "clock_gen_480p_tb" -objects $fs_sim_obj
relaunch_sim
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
cd projf-explore/graphics/fpga-graphics/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Verilator SDL Simulation

You can simulate these design on your PC using Verilator and SDL. See the [Verilator README](verilator/README.md) and blog introduction: [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs:

```shell
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

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
