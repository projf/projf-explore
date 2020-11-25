# FPGA Ad Astra

This folder contains the SystemVerilog designs to accompany Project F **[FPGA Ad Astra](https://projectf.io/posts/fpga-ad-astra/)**. All the designs are under the permissive [MIT licence](../LICENSE), but the blog posts themselves are subject to normal copyright restrictions. The fonts included in this project are under different licences: see the individual font*.mem files for details.

These designs make use of Project F [common modules](../common/), such as clock generation and display timings.

## iCEBreaker Build

You can build projects for iCEBreaker with the included makefile. You need the iCE40 toolchain installed, see [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/) for details.

For example, to build `top_greet`:

```bash
cd ice40
make top_greet
```

After the build completes you'll have bin file, such as `top_greet.bin`. Use the bin file to program your board:

```bash
iceprog top_greet.bin
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

You can then build `top_greet`, `top_hello_jp` etc. as you would for any Vivado project.

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

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs.
