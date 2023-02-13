# Mandelbrot

This SystemVerilog drawing demo uses Q4.21 fixed-point multiplication and a small framebuffer to render the Mandelbrot set.

This design has an associated Project F blog post: [Mandelbrot Set in Verilog](https://projectf.io/posts/mandelbrot-set-verilog/).  
New to FPGA maths? Check out [Numbers in Verilog](https://projectf.io/posts/numbers-in-verilog/).

The current version of the demo renders one pixel at a time using four samples. Rendering performance could be increased significantly by tackling multiple pixels simultaneously and only rendering new pixels when scrolling.

By default, we consider up to 255 interations, but you can adjust this by changing `ITER_MAX` in the top module.

The starting position (top-left corner) is (-3.5,-1.5i) with a step of 1/64 (0.015625). You can zoom in 15 times to the minimum step of 1/2097152 (0.000000476837158). You can adjust the precision by changing `FP_WIDTH` and `FP_INT` in the top module.

![](../../doc/img/sea-of-chaos.png?raw=true "")

_Mandelbrot set drawn by Verilator/SDL sim._

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/demos/mandelbrot/xc7/vivado
source ./create_project.tcl
```

You can then build `top_mandel` as you would for any Vivado project.

## Verilator Build

If this is the first time you've used Verilator and SDL, you need to [install dependencies](https://projectf.io/posts/verilog-sim-verilator-sdl/#installing-dependencies).

Make sure you're in the sim directory `projf-explore/demos/mandelbrot/sim`.

Build the demo:

```shell
make
```

Run the simulation executable from `obj_dir`:

```shell
./obj_dir/mandelbrot
```

### Fullscreen Mode

To run in fullscreen mode, edit `main_mandelbrot.cpp` so that `FULLSCREEN = true`, then rebuild.

You can quit the demo with the usual key combination: Ctrl-Q on Linux or Command-Q on macOS.
