# Simulation for Animated Shapes

This folder contains a Verilator simulation to accompany the Project F blog post: **[Animated Shapes](https://projectf.io/posts/animated-shapes/)**.

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate a hardware design on your PC: no dev board required! Verilator is fast, but it's still much slower than an FPGA. However, for these simple designs, you can reach 60 FPS on a modern PC.

If you're new to graphics simulations check out the blog post on [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

If you have a dev board, see the main [Animated Shapes README](../README.md) for build instructions.

## Demos

There are two demo top module that can draw different things:

* `top_demo_sb` - single buffer animation without screen clear
* `top_demo` double buffer animation with screen clear

To switch between the different demos, change the render instance near line 155 in `top_demo` or line 100 in `top_demo_sb`:

* `render_square_colr` - colour-cycling square bounces around the screen
* `render_cube_shatter` - shatter 3D cube drawn from six triangles
* `render_teleport` - teleport effect with nested squares

## Tested Versions

These simulations have been tested with:

* Verilator 4.038 (Ubuntu 22.04 amd64)
* Verilator 5.006 (macOS 13 arm64)

## Build & Run

If this is the first time you've used Verilator and SDL, you need to [install dependencies](#installing-dependencies).

Make sure you're in the sim directory `projf-explore/graphics/animated-shapes/sim`.

Build the demo:

```shell
make demo
```

Run the simulation executable from `obj_dir`:

```shell
./obj_dir/demo
```

You can quit the demo by pressing the **Q** key.

For the single buffer version, replace `demo` with `demo_sb` in the above instructions.

### Fullscreen Mode

To run in fullscreen mode, edit `main_demo.cpp` or `main_demo_sb.cpp` so that `FULLSCREEN = true`, then rebuild.

## Installing Dependencies

To build the simulations, you need:

1. C++ Toolchain
2. Verilator
3. SDL

The simulations should work on any modern platform, but I've confined my instructions to Linux and macOS. Windows installation depends on your choice of compiler, but the sims should work fine there too. For advice on SDL development on Windows, see [Lazy Foo' - Setting up SDL on Windows](https://lazyfoo.net/tutorials/SDL/01_hello_SDL/windows/index.php).

### Linux

For Debian and Ubuntu-based distros, you can use the following. Other distros will be similar.

Install a C++ toolchain via 'build-essential':

```shell
apt update
apt install build-essential
```

Install packages for Verilator and the dev version of SDL:

```shell
apt install verilator libsdl2-dev
```

That's it!

_If you want to build the latest version of Verilator yourself, see [Building Verilator for Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/#verilator)._

### macOS

Install the [Homebrew](https://brew.sh/) package manager; this will also install Xcode Command Line Tools.

With Homebrew installed, you can run:

```shell
brew install verilator sdl2
```

And you're ready to go.
