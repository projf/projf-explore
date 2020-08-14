# FPGA Pong

This folder contains the SystemVerilog designs to accompany Project F **[FPGA Pong](https://projectf.io/posts/fpga-pong/)**.

All the designs are under the permissive [MIT licence](../LICENSE), but the blog posts themselves are subject to normal copyright restrictions.

## iCEBreaker Build

You can build projects for iCEBreaker with the included makefile. You need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](https://github.com/cliffordwolf/icestorm.git). You can find instructions for building Yosys, nextpnr, and IceStorm Tools from source at [FPGA Tooling on Ubuntu 20.04](https://projectf.io/posts/fpga-dev-ubuntu-20.04/).

For example, to build `top_pong_v4`:

```bash
cd ice40
make top_pong_v4
```

After the build completes you'll have bin file, such as `top_pong_v4.bin`. Use the bin file to program your board:

```bash
iceprog top_pong_v4.bin
```

Try running `iceprog` with `sudo` if you get the error `Can't find iCE FTDI USB device`.

### Problems Building

If you have problems building for iCEBreaker, your tools are probably too old. Try building the latest versions (see above for links).

## Vivado Project

**NB. The Arty version of Pong is not yet in the repo. It will be added during August 2020.**

To create a Vivado project for the **Digilent Arty** (original or A7-35T); start Vivado and run the following in the tcl console:

```tcl
cd xc7/vivado
source ./create_project.tcl
```

You can then build `top_pong_v4` etc. as you would for any Vivado project.

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
