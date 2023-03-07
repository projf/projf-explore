# Mandelbrot Set

This SystemVerilog demo uses fixed-point multiplication and a small framebuffer to render the Mandelbrot set.

This design has an associated Project F blog post: [Mandelbrot in Verilog](https://projectf.io/posts/mandelbrot-verilog/).

I've included project files for:

* [Digilent Arty A7-35T](#arty-a7-35t-build)
* [Digilent Nexys Video](#nexys-video-dvi-build)
* [Verilator/SDL Simulation](#verilator-build)

This demo makes use of modules from the [Project F library](../../lib).

![](../../doc/img/sea-of-chaos.png?raw=true "")

_Mandelbrot set rendered by Verilator/SDL._

## Demo Parameters

We consider up to 255 iterations by default, but you can adjust this by changing `ITER_MAX` in the top module. The minimum number of iterations supported is 128, but you get the best results with 2<sup>n</sup>-1, for example, 511, as this best uses the full range of colours.

With the default 25-bit precision, you can zoom in 15 times to a minimum step of 1/2<sup>21</sup>. You can adjust the precision by changing `FP_WIDTH` in the top module (don't forget to adjust `X_START`, `Y_START`, and `STEP`).

## Xilinx 7-Series FPGAs

This demo have been tested with:

* Vivado 2022.2

### Arty A7-35T Build

To create a Vivado project for the Digilent [Arty A7-35T](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/reference-manual) with Pmod VGA; clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/demos/mandelbrot/xc7-vga/arty-a7-35
source ./create_project.tcl
```

You can then build `top_mandel` as you would for any Vivado project.

Button controls:

* **BTN2** - left/up/zoom-out
* **BTN1** - select mode: horizontal/vertical/zoom
* **BTN0** - right/down/zoom-in
* **RESET** - return to starting coordinates and zoom

_NB. Controls don't work if rendering is in progress._

Four green LEDs show status:

* **LD7** - rendering in progress
* **LD6** - horizontal motion
* **LD5** - vertical motion
* **LD4** - zoom

### Nexys Video DVI Build

To create a Vivado project for the Digilent [Nexys Video](https://reference.digilentinc.com/reference/programmable-logic/nexys-video/reference-manual) with DVI output; clone the projf-explore git repo, then start Vivado and run the following in the Tcl console:

```tcl
cd projf-explore/demos/mandelbrot/xc7-dvi/nexys-video
source ./create_project.tcl
```

You can then build `top_mandel` as you would for any Vivado project.

Button controls:

* **BTNU** - left/up/zoom-out
* **BTNC** - select mode: horizontal/vertical/zoom
* **BTND** - right/down/zoom-in
* **CPU_RESET** - return to starting coordinates and zoom

_NB. Controls don't work if rendering is in progress._

Four green LEDs show status:

* **LD3** - rendering in progress
* **LD2** - horizontal motion
* **LD1** - vertical motion
* **LD0** - zoom

## Verilator

This demo have been tested with:

* Verilator 4.038 (Ubuntu 22.04 amd64)
* Verilator 5.006 (macOS 13 arm64)

### Verilator Build

If this is the first time you've used Verilator and SDL, you need to [install dependencies](https://projectf.io/posts/verilog-sim-verilator-sdl/#installing-dependencies).

Build the demo:

```shell
cd projf-explore/demos/mandelbrot/verilator-sdl
make
```

Run the simulation executable from `obj_dir`:

```shell
./obj_dir/mandelbrot
```

Keyboard controls:

* **Up Arrow** - left/up/zoom-out
* **Space Bar** - select mode: horizontal/vertical/zoom
* **Down Arrow** - right/down/zoom-in

_NB. Controls don't work if rendering is in progress._

You can quit the simulation by pressing the **Q** key.

To run in fullscreen mode, edit `main_mandelbrot.cpp` so that `FULLSCREEN = true`, then rebuild.
