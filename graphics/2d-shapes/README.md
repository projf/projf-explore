# 2D Shapes

This folder accompanies the Project F blog post: **[2D Shapes](https://projectf.io/posts/fpga-shapes/)**. These SystemVerilog designs draw circles, rectangles, and filled shapes in a framebuffer. You can freely build on these [MIT licensed](../../LICENSE) designs. Have fun.

File layout:

* `160x90` - render modules for 160x90 with 4 colours
* `320x180` - render modules for 320x180 with 16 colours
* `ice40` - designs for iCEBreaker and other Lattice iCE40 boards
* `sim` - simulation with Verilator and LibSDL; see the [Simulation README](sim/README.md)
* `xc7` - designs for Arty and other Xilinx 7 Series boards with VGA output
* `xc7-dvi` - designs for Nexys Video and other Xilinx 7 Series boards with DVI output

These designs make use of modules from the [Project F library](../../lib/). Check the included iCE40 [Makefile](ice40/Makefile) or Vivado [create_project.tcl](xc7/vivado/create_project.tcl) to see the list of modules.

There is one demo top module that can draw different things.

To switch between the different demos, change the render instance near line 125 in `top_demo`:

* `render_rects` - many rectangles inside rectangles
* `render_rects_fill` - overlapping filled rectangles
* `render_triangles_fill` - three filled triangles
* `render_cube_fill` - filled cube from six triangles
* `render_circles` - circles inside circles
* `render_circles_fill` - filled circles inside circles

Learn more about the designs and demo from the [2D Shapes](https://projectf.io/posts/fpga-shapes/) blog post, or read on for build instructions. New to graphics development on FPGA? Check out [Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

![](../../doc/img/2d-shapes.jpg?raw=true "")

_Circles drawn by an iCE40 FPGA on an HDMI monitor._

## iCEBreaker Build

You can build projects for [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/) using the included [Makefile](ice40/Makefile) with [Yosys](https://yosyshq.net/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr), and [IceStorm Tools](http://bygone.clairexen.net/icestorm/).

You can get pre-built tool binaries for Linux, Mac, and Windows from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build). If you want to build the tools yourself, check out [Building iCE40 FPGA Toolchain on Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/).

To build the `demo` project, clone the projf-explore git repo, then:

```shell
cd projf-explore/graphics/2d-shapes/ice40
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

To create a Vivado project for the Digilent Arty ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/2d-shapes/xc7/vivado
source ./create_project.tcl
```

You can then build `top_demo` as you would for any Vivado project.

### Simulation

This design includes a test bench for the new drawing modules. You can run the test bench simulations from the GUI under the "Flow" menu or from the Tcl console with:

```tcl
launch_simulation
run all
```

By default the `draw_rectangle` test bench is simulated, but you can switch to another test bench, such as `draw_rectangle_fill` with:

```tcl
set fs_sim_obj [get_filesets sim_1]
set_property -name "top" -value "draw_rectangle_fill" -objects $fs_sim_obj
relaunch_sim
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
cd projf-explore/graphics/2d-shapes/xc7/vivado
source ./create_project.tcl
```

Replace `<board>` and `<fpga-part>` with the actual board and part names.

## Nexys Video Build

To create a Vivado project for the Digilent [Nexys Video](https://digilent.com/reference/programmable-logic/nexys-video/reference-manual); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/graphics/2d-shapes/xc7-dvi/vivado
source ./create_project.tcl
```

You can then build `top_demo` as you would for any Vivado project.

### Tested Versions

The Nexys Video designs have been tested with:

* Vivado 2022.2

## Verilator SDL Simulation

You can simulate these designs on your computer using Verilator and SDL. The [Simulation README](sim/README.md) has build instructions.

## Linting

If you have [Verilator](https://www.veripool.org/wiki/verilator) installed, you can run the linting shell script `lint.sh` to check the designs. Learn more from [Verilog Lint with Verilator](https://projectf.io/posts/verilog-lint-with-verilator/).

## SystemVerilog?

These designs use a little SystemVerilog to make Verilog more pleasant. See the [Library README](../../lib/README.md#systemverilog) for details of SV features used.
