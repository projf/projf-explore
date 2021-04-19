# Life on Screen

This folder contains SystemVerilog designs to accompany the Project F blog post: **[Life on Screen](https://projectf.io/posts/life-on-screen/)**.

These designs make use of Project F [common modules](../common/), such as clock generation and display timings. Check the Vivado [create_project.tcl](xc7/vivado/create_project.tcl) script to see which modules are used.

All the designs are under the permissive [MIT licence](../LICENSE), but the blog post is subject to normal copyright restrictions.

## iCEBreaker Build

Designs for iCEBreaker are not available at this time. Have you tried the [other designs](../README.md) in this series?

## Xilinx Vivado Build

To create a Vivado project for the **Digilent Arty** (original or A7-35T); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/life-on-screen/xc7/vivado
source ./create_project.tcl
```

You can then build `top_life` as you would for any Vivado project.

### Simulation

This design includes a test bench for the life module. You can run the test bench simulation from the GUI under the "Flow" menu or from the Tcl console with:

```tcl
launch_simulation
run all
```

In the waveform view, you should add the `memory[0:71]` object from the `bmp_life` instance, so you can see the simulation update.

### Other Xilinx Series 7 Boards

It's straightforward to adapt the project for other Xilinx Series 7 boards:

1. Create a suitable constraints file named `<board>.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in Tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd projf-explore/life-on-screen/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).
