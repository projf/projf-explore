# Exploring FPGA Graphics

This folder contains the SystemVerilog designs to accompany Project F **[Exploring FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**.

All the designs are under the permissive [MIT licence](../LICENSE), but the blog posts themselves are subject to normal copyright restrictions.

## iCEBreaker Build

You can build projects for iCEBreaker with the included makefile. You need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](https://github.com/cliffordwolf/icestorm.git). You can find instructions for building Yosys, nextpnr, and IceStorm Tools from source at [FPGA Tooling on Ubuntu 20.04](https://projectf.io/posts/fpga-dev-ubuntu-20.04/).

For example, to build the DVI version of `top_bounce`:

```bash
cd ice40
make top_bounce
```

The VGA version works the same way, but you append `_vga` to the target. For example:

```bash
cd ice40
make top_bounce_vga
```

After the build completes you'll have bin file, such as `top_bounce.bin`. Use the bin file to program your board:

```bash
iceprog top_bouncebin
```

Try running `iceprog` with `sudo` if you get the error `Can't find iCE FTDI USB device`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Vivado Project

To create a Vivado project for the **Digilent Arty** (original or A7-35T); start Vivado and run the following in the tcl console:

```tcl
cd xc7/vivado
source ./create_project.tcl
```

You can then build `top_bounce`, `top_beam`, or `top_square` as you would for any Vivado project.

### Simulation

This design includes test benches for the `clock_gen` and `display_timings` modules. You can run the test bench simulation from the GUI under the "Flow" menu or from the TCL console with:

```tcl
launch_simulation
run all
```

By default the `display_timings` test bench is simulated, but you can switch to the `clock_gen` test bench with:

```tcl
set fs_sim_obj [get_filesets sim_1]
set_property -name "top" -value "clock_gen_tb" -objects $fs_sim_obj
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
cd xc7/vivado
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
##   Checking ./fpga-graphics/ice40/top_beam_vga.sv
##   Checking ./fpga-graphics/ice40/top_bounce.sv
##   Checking ./fpga-graphics/ice40/top_bounce_vga.sv
##   Checking ./fpga-graphics/ice40/top_square.sv
##   Checking ./fpga-graphics/ice40/top_square_vga.sv
```
