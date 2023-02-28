# Castle Drawing

This SystemVerilog drawing demo uses shapes to build a simple castle and rainbow in 16 colours.

This design has an associated Project F blog post: [Castle Drawing](https://projectf.io/posts/castle-drawing/).  
New to FPGA graphics design? Check out [Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

![](../../doc/img/castle-sim.png?raw=true "")

_Castle drawn by Verilator/SDL sim._

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/demos/castle-drawing/xc7/vivado
source ./create_project.tcl
```

You can then build `top_castle` as you would for any Vivado project.

## Verilator

### Tested Versions

This simulation have been tested with:

* Verilator 4.038 (Ubuntu 22.04 amd64)
* Verilator 5.006 (macOS 13 arm64)

### Verilator Build

If this is the first time you've used Verilator and SDL, you need to [install dependencies](https://projectf.io/posts/verilog-sim-verilator-sdl/#installing-dependencies).

Make sure you're in the sim directory `projf-explore/demos/castle-drawing/sim`.

Build the demo:

```shell
make
```

Run the simulation executable from `obj_dir`:

```shell
./obj_dir/castle
```

### Fullscreen Mode

To run in fullscreen mode, edit `main_castle.cpp` so that `FULLSCREEN = true`, then rebuild.

You can quit the demo with the usual key combination: Ctrl-Q on Linux or Command-Q on macOS.
