# FPGA Shapes

This folder contains SystemVerilog designs to accompany the Project F blog post: **[FPGA Shapes](https://projectf.io/posts/fpga-shapes/)**.

These designs make use of Project F [common modules](../common/), such as clock generation and display timings. Check the Vivado [create_project.tcl](xc7/vivado/create_project.tcl) script to see which modules are used.

All the designs are under the permissive [MIT licence](../LICENSE), but the blog post is subject to normal copyright restrictions.

## iCEBreaker Build

Designs for iCEBreaker are not available yet. Have you tried the [other designs](../README.md) in this series?

## Xilinx Vivado Build

To create a Vivado project for the **Digilent Arty** (original or A7-35T); clone the projf-explore git repo, then start Vivado and run the following in the tcl console:

```tcl
cd projf-explore/fpga-shapes/xc7/vivado
source ./create_project.tcl
```

You can then build `top_tunnel` or `top_rectangles_filled` as you would for any Vivado project.

### Simulation

This design includes a test bench for the new drawing modules. You can run the test bench simulations from the GUI under the "Flow" menu or from the TCL console with:

```tcl
launch_simulation
run all
```

By default the `draw_rectangle` test bench is simulated, but you can switch to another test bench, such as `draw_rectangle_filled` with:

```tcl
set fs_sim_obj [get_filesets sim_1]
set_property -name "top" -value "draw_rectangle_filled" -objects $fs_sim_obj
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
cd projf-explore/fpga-shapes/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).
