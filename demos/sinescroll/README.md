# Sine Scrolling Demo

Design from the demo "All You Need" by Chapterhouse released at Revision 2022 (with minor emendations).

This demo has an associated Project F blog post: [Sine Scroller](https://projectf.io/posts/sinescroll/).  
New to FPGA graphics design? Check out [Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

![](../../doc/img/sinescroll-sim.png?raw=true "")

_Scrolling with Verilator/SDL sim._

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/demos/sinescroll/xc7/vivado
source ./create_project.tcl
```

You can then build `top_sinescroll` as you would for any Vivado project.

## Verilator Build

If this is the first time you've used Verilator and SDL, you need to [install dependencies](https://projectf.io/posts/verilog-sim-verilator-sdl/#installing-dependencies).

Make sure you're in the sim directory `projf-explore/demos/sinescroll/sim`.

Build the demo:

```shell
make
```

Run the simulation executable from `obj_dir`:

```shell
./obj_dir/sinescroll
```

### Fullscreen Mode

To run in fullscreen mode, edit `main_sinescroll.cpp` so that `FULLSCREEN = true`, then rebuild.

You can quit the demo with the usual key combination: Ctrl-Q on Linux or Command-Q on macOS.
