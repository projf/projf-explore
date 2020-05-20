# Exploring FPGA Graphics

This folder contains the SystemVerilog designs to accompany Project F **[Exploring FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**.

All the designs are under the permissive [MIT licence](../LICENSE), but the posts themselves are subject to normal copyright restrictions.

## iCEBreaker Build

A makefile will be added shortly. Until then, you can run the following.

_Replace `top_square` with `top_beam` to build the second project._

### 12-bit DVI Pmod

```bash
cd ice40
if [ ! -d build ]; then mkdir -p build; fi;
yosys -ql build/out.log -p 'synth_ice40 -top top_square -json build/out.json' \
    top_square.sv clock_gen.sv ../display_timings.sv
nextpnr-ice40 --up5k --package sg48 --json build/out.json --pcf icebreaker.pcf --asc build/out.asc
icetime -d up5k -mtr build/out.rpt build/out.asc
icepack build/out.asc build/out.bin
```

### Pmod VGA

```bash
cd ice40
if [ ! -d build ]; then mkdir -p build; fi;
yosys -ql build/out.log -p 'synth_ice40 -top top_square_vga -json build/out.json' \
    top_square_vga.sv clock_gen.sv ../display_timings.sv
nextpnr-ice40 --up5k --package sg48 --json build/out.json --pcf icebreaker_vga.pcf --asc build/out.asc
icetime -d up5k -mtr build/out.rpt build/out.asc
icepack build/out.asc build/out.bin
```

### Problems Building?

If you have problems building, your tools are probably too old. You can find the latest versions in their respective GitHub repos: [Yosys](https://github.com/YosysHQ/yosys), [NextPNR]((https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](https://github.com/cliffordwolf/icestorm.git).

## Vivado Project

To create a Vivado project for the Digilent Arty (original or A7-35T):

```tcl
cd xc7/vivado
source ./create_project.tcl
```

For other Xilinx Series 7 boards:

1. Create a suitable constraints file named `my-board.xdc` within the `xc7` directory
2. Make a note of your board's FPGA part, such as `xc7a35ticsg324-1L`
3. Set the board and part names in tcl, then source the create project script:

```tcl
set board_name my-board
set fpga_part my-fpga-part
cd xc7/vivado
source ./create_project.tcl
```

Replace `my-board` and `my-fpga-part` with the actual board and part names.
