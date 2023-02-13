# Mandelbrot Set

This SystemVerilog drawing demo uses Q4.21 fixed-point multiplication and a small framebuffer to render the Mandelbrot set.

This design has an associated Project F blog post: [Mandelbrot Set in Verilog](https://projectf.io/posts/mandelbrot-set-verilog/) (coming soon).

The current version of the demo renders one pixel at a time using four samples. Rendering performance could be increased significantly by tackling multiple pixels simultaneously and only rendering new pixels when scrolling.

We consider up to 255 iterations by default, but you can adjust this by changing `ITER_MAX` in the top module. The minimum number of iterations supported is 128, but you get the best results with 2<sup>n</sup>-1, for example, 511, as this best uses the full range of colours.

The starting position (top-left corner) is (-3.5,-1.5i) with a step of 1/64 (0.015625).

With the default 25-bit precision, you can zoom in 15 times to a minimum step of 1/2<sup>21</sup>. You can adjust the precision by changing `FP_WIDTH` in the top module (don't forget to adjust `X_START`, `Y_START`, and `STEP`) and see _DSP Usage_ (below).

New to FPGA maths? Check out [Numbers in Verilog](https://projectf.io/posts/numbers-in-verilog/).

![](../../doc/img/sea-of-chaos.png?raw=true "")

_Mandelbrot set drawn by Verilator/SDL sim._

## Arty Build

To create a Vivado project for the **Digilent Arty** ([original](https://digilent.com/reference/programmable-logic/arty/reference-manual) or [A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual)); clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/demos/mandelbrot/xc7/vivado
source ./create_project.tcl
```

You can then build `top_mandel` as you would for any Vivado project.

Arty button controls:

* **BTN2** - left/up/zoom-out
* **BTN1** - select mode: horizontal/vertical/zoom
* **BTN0** - right/down/zoom-in
* **RESET** - return to starting coordinates and zoom

_NB. Controls don't work if rendering is in progress._

The four green LEDs show status:

* **LD7** - rendering in progress
* **LD6** - horizontal motion
* **LD5** - vertical motion
* **LD4** - zoom

### DSP Usage

Each Xilinx 7 Series DSP block (DSP48E1) can multiply 25 × 18 bits.

The DSP usage of each Mandelbrot module instance depends on `FP_WIDTH`:

* 18 bits = 1 DSP (zoom in 8 times)
* 25 bits = 2 DSPs (zoom in 15 times)
* 32 bits = 4 DSPs (zoom in 22 times)

18-bit fixed-point only leaves 14 bits for the fraction, so you can't zoom in far, but it's frugal with DSPs. 25 bits is a good compromise as it provides a decent zoom level without consuming too many blocks. Above 25 bits wide, DSP usage rises quickly.

This demo uses four Mandelbrot module instances for supersampling, plus one DSP is used in address calculation. Thus, the total number of DSPs with 25-bit precision is `4 * 2 + 1`: 9 of 90 DSPs on the Artix A7-35T.

Learn more from [Multiplication with FPGA DSPs](https://projectf.io/posts/multiplication-fpga-dsps/).

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

Verilator controls:

* **Up Arrow** - left/up/zoom-out
* **Space Bar** - select mode: horizontal/vertical/zoom
* **Down Arrow** - right/down/zoom-in

_NB. Controls don't work if rendering is in progress._

### Fullscreen Mode

To run in fullscreen mode, edit `main_mandelbrot.cpp` so that `FULLSCREEN = true`, then rebuild.

You can quit the demo with the usual key combination: Ctrl-Q on Linux or Command-Q on macOS.
