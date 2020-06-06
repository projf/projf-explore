# Exploring FPGA Graphics

This folder contains the SystemVerilog designs to accompany Project F **[Exploring FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**.

All the designs are under the permissive [MIT licence](../LICENSE), but the posts themselves are subject to normal copyright restrictions.

## iCEBreaker Build

You can build the projects for the iCEBreaker board the included makefile.

For example, to build the DVI version of top_beam:

```bash
cd ice40
make top_beam
```

The VGA version works the same way, but you append _vga to the target:

```bash
cd ice40
make top_beam_vga
```

After the build completes you'll have bin file, such as `top_beam.bin`. Use the bin file to program your board:

```bash
iceprog top_beam.bin
```

If you get an error of the form `Can't find iCE FTDI USB device`; try running `iceprog` with `sudo`.

### Problems Building

If you have problems building, your tools are probably too old. You can find the latest versions in their respective GitHub repos: [Yosys](https://github.com/YosysHQ/yosys), [NextPNR](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](https://github.com/cliffordwolf/icestorm.git).

## Vivado Project

To create a Vivado project for the Digilent Arty (original or A7-35T). Start Vivado and run the following in the TCL console:

```tcl
cd xc7/vivado
source ./create_project.tcl
```

For other Xilinx Series 7 boards:

1. Create a suitable constraints file named `my-board.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in tcl, then source the create project script:

```tcl
set board_name <board>
set fpga_part <fpga-part>
cd xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.
