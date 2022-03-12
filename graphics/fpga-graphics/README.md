# Intro to FPGA Graphics

This folder accompanies the Project F blog post: **[Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**. These SystemVerilog designs introduce you to displays and demonstrate how to draw your first FPGA graphics. You can freely build on these [MIT licensed](../../LICENSE) designs. Have fun.

File layout:

* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards
* `xc7-hd` - experimental designs for Nexys Video and larger Xilinx 7 Series FPGAs

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules.

Included demos:

* Square
* Flag of Ethipoia
* Flag of Sweden
* Colour

Learn more about the designs and demos from _[Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/)_, or read on for build instructions.

![](../../doc/img/flag_ethiopia.png?raw=true "")

_Traditional flag of Ethiopia._

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](http://www.clifford.at/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://www.clifford.at/icestorm/). 

You can get pre-built tool binaries for Linux, Mac, and Windows from [Open Tool Forge](https://github.com/open-tool-forge/fpga-toolchain). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

For example, to build `flag_ethiopia`; clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/fpga-graphics/ice40
make flag_ethiopia
```

After the build completes, you'll have a bin file, such as `flag_ethiopia.bin`. Use the bin file to program your board:

```shell
iceprog flag_ethiopia.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If you have problems building the iCE40 designs, make sure you're using Yosys 0.10 or later.

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/fpga-graphics/xc7/vivado
source ./create_project.tcl
```

You can then build `top_square`, `top_flag_ethiopia`, `top_flag_sweden`, or `top_colour` as you would for any Vivado project.

### Behavioural Simulation

This design includes test benches for the `clock_480p` and `simple_480p` modules. You can run the test bench simulations from the GUI under the "Flow" menu or from the Tcl Console with:

```tcl
launch_simulation
run all
```

By default, the `simple_480p` test bench is simulated, but you can switch to the `clock_tb` test bench with:

```tcl
set fs_sim_obj [get_filesets sim_1]
set_property -name "top" -value "clock_tb" -objects $fs_sim_obj
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

You can simulate these designs on your PC using Verilator and SDL. The [Simulation README](sim/README.md) has build instructions. If you're new to Verilator sims, check out [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs:

```shell
$ ./fpga-graphics/lint.sh
## Linting top modules in ./sim
##   Checking ./sim/top_colour.sv
##   Checking ./sim/top_flag_ethiopia.sv
##   Checking ./sim/top_flag_sweden.sv
##   Checking ./sim/top_square.sv
## Linting top modules in ./ice40
##   Checking ./ice40/top_colour.sv
##   Checking ./ice40/top_flag_ethiopia.sv
##   Checking ./ice40/top_flag_sweden.sv
##   Checking ./ice40/top_square.sv
## Linting top modules in ./xc7
##   Checking ./xc7/top_colour.sv
##   Checking ./xc7/top_flag_ethiopia.sv
##   Checking ./xc7/top_flag_sweden.sv
##   Checking ./xc7/top_square.sv
## Linting top modules in ./xc7-hd
##   Checking ./xc7-hd/top_colour.sv
##   Checking ./xc7-hd/top_flag_ethiopia.sv
##   Checking ./xc7-hd/top_flag_sweden.sv
##   Checking ./xc7-hd/top_square.sv
```

You can learn more about this from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
