# Life on Screen

This folder contains the SystemVerilog designs to accompany Project F **[Life on Screen](https://projectf.io/posts/life-on-screen/)**.

All the designs are under the permissive [MIT licence](../LICENSE), but the blog posts themselves are subject to normal copyright restrictions.

## iCEBreaker Build

Designs for iCEBreaker are being tested and will be available soon. Until then, have you tried [other designs](../README) in this series?

## Vivado Project

To create a Vivado project for the **Digilent Arty** (original or A7-35T); start Vivado and run the following in the tcl console:

```tcl
cd xc7/vivado
source ./create_project.tcl
```

You can then build `top_life` or `top_earth`. as you would for any Vivado project.

### Simulation

This design includes a test bench for the life module. You can run the test bench simulation from the GUI under the "Flow" menu or from the TCL console with:

```tcl
launch_simulation
run all
```

You should add the `memory[0:71]` object from the `bmp_life` instance, so you can see the simulation update.

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
