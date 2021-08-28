# Animated Shapes

This folder contains SystemVerilog designs to accompany the Project F blog post: **Animated Shapes** (coming soon). New to graphics on FPGA? Check out our introductory post: [FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

Included demos for iCEBreaker and Arty FPGA boards:

* `top_sb_bounce` - persistent bouncing square in single buffer
* `top_db_bounce` - bouncing square in double buffer
* `top_cube_pieces` - breaking a cube into triangle
* `top_rotate` - rotating triangles with trigonometry
* `top_teleport` - teleport in style

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the included modules.

## iCEBreaker Build

Designs for iCEBreaker are not available yet. Have you tried the [other designs](../README.md) in this series?

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/animated-shapes/xc7/vivado
source ./create_project.tcl
```

You can then build `top_telport`, `top_cube_pieces` etc. as you would for any Vivado project.

### Other Xilinx 7 Series Boards

It's straightforward to adapt the project for other Xilinx 7 Series boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/animated-shapes/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
