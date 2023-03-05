# Mandelbrot Set

This SystemVerilog demo uses Q4.21 fixed-point multiplication and a small framebuffer to render the Mandelbrot set.

This design has an associated Project F blog post: _Mandelbrot Set in Verilog_ (coming soon).

I've included project files for:

* [Digilent Arty A7-35T](#arty-a7-35t-build)
* [Digilent Nexys Video](#nexys-video-dvi-build)
* [Verilator/SDL Simulation](#verilator-build)

It should be straightforward to adapt to any FPGA board with video output.

![](../../doc/img/sea-of-chaos.png?raw=true "")

_Mandelbrot set rendered by Verilator/SDL._

## Demo Parameters

We consider up to 255 iterations by default, but you can adjust this by changing `ITER_MAX` in the top module. The minimum number of iterations supported is 128, but you get the best results with 2<sup>n</sup>-1, for example, 511, as this best uses the full range of colours.

The starting position (top-left corner) is (-3.5,-1.5i) with a step of 1/64 (0.015625).

With the default 25-bit precision, you can zoom in 15 times to a minimum step of 1/2<sup>21</sup>. You can adjust the precision by changing `FP_WIDTH` in the top module (don't forget to adjust `X_START`, `Y_START`, and `STEP`).

### Resolution

To change the render resolution, you need to adjust the following in `top_mandel.sv`:

1. The rendering step parameter: `STEP`
2. The framebuffer dimensions:
    - `FB_WIDTH`
    - `FB_HEIGHT`
    - `FB_SCALE`
3. The zoom scale factors:
    - `x_start_p <= x_start - (step <<< 7);`
    - `y_start_p <= y_start - (step <<< 6) - (step <<< 5);`
    - `x_start_p <= x_start + (step <<< 6);`
    - `y_start_p <= y_start + (step <<< 5) + (step <<< 4);`

_NB. The current version of the demo renders one pixel at a time using four samples. Rendering performance could be increased significantly by tackling multiple pixels simultaneously and only rendering new pixels when scrolling._

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

Arty button controls:

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

Arty button controls:

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

Verilator controls:

* **Up Arrow** - left/up/zoom-out
* **Space Bar** - select mode: horizontal/vertical/zoom
* **Down Arrow** - right/down/zoom-in

_NB. Controls don't work if rendering is in progress._

You can quit the simulation by pressing the **Q** key.

### Fullscreen Mode

To run in fullscreen mode, edit `main_mandelbrot.cpp` so that `FULLSCREEN = true`, then rebuild.
