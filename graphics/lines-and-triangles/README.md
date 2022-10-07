# Lines and Triangles

This folder accompanies the Project F blog post: **[Lines and Triangles](https://projectf.io/posts/lines-and-triangles/)**. These SystemVerilog designs draw lines and triangles in a framebuffer. You can freely build on these [MIT licensed](../../LICENSE) designs. Have fun.

File layout:

* `160x90` - render modules for 160x90 with 4 colours
* `320x180` - render modules for 320x180 with 16 colours
* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules.

## Demos

There is one demo top module that can draw several shapes.

To switch between the different demos, change the render instance near line 120 in `top_demo`:

* `render_line` - single diagonal line
* `render_edge` - line around the edge of the framebuffer
* `render_cube` - cube outline from nine lines
* `render_triangles` - three triangle outlines

Learn more about the designs and demo from the [Lines and Triangles](https://projectf.io/posts/lines-and-triangles/) blog post, or read on for build instructions. New to graphics development on FPGA? Check out [Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

![](../../doc/img/lines-and-triangles.jpg?raw=true "")

_Cube drawn by an Artix-7 FPGA on VGA monitor._

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](https://yosyshq.net/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://bygone.clairexen.net/icestorm/).

You can get pre-built tool binaries for Linux, Mac, and Windows from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

To build the `demo` project, clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/lines-and-triangles/ice40
make demo
```

After the build completes, you'll have a bin file called `demo.bin`. Use the bin file to program your board:

```shell
iceprog demo.bin
```

If you get the error `Can't find iCE FTDI USB device`, try running `iceprog` with `sudo`.

### Problems Building

If Yosys reports "syntax error, unexpected TOK_ENUM", then your version is too old to support Project F designs. Try building the latest version of Yosys from source (see above for links).

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/lines-and-triangles/xc7/vivado
source ./create_project.tcl
```

You can then build `top_demo` as you would for any Vivado project.

### Simulation

This design includes test benches for the line and triangle drawing modules. You can run the test bench simulations from the GUI under the "Flow" menu or from the Tcl console with:

```tcl
launch_simulation
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
cd projf-explore/graphics/lines-and-triangles/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Verilator SDL Simulation

You can simulate these designs on your computer using Verilator and SDL. The [Simulation README](sim/README.md) has build instructions.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
