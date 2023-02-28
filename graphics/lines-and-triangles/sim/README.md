# Simulation for Lines and Triangles

This folder contains a Verilator simulation to accompany the Project F blog post: **[Lines and Triangles](https://projectf.io/posts/lines-and-triangles/)**.

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate a hardware design on your PC: no dev board required! Verilator is fast, but it's still much slower than an FPGA. However, for these simple designs, you can reach 60 FPS on a modern PC.

If you're new to graphics simulations check out the blog post on [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

If you have a dev board, see the main [Lines and Triangles README](../README.md) for build instructions.

## Demos

There is one demo that can draw a line, cube, or triangles.

![](../../../doc/img/lines-and-triangles-sim.png?raw=true "")

_Triangles drawn by sim demo._

## Tested Versions

This simulation has been tested with:

* Verilator 4.038 (Ubuntu 22.04 amd64)
* Verilator 5.006 (macOS 13 arm64)

## Build & Run

If this is the first time you've used Verilator and SDL, you need to [install dependencies](#installing-dependencies).

Make sure you're in the sim directory `projf-explore/graphics/lines-and-triangles/sim`.

Build the demo:

```shell
make demo
```

Run the simulation executable from `obj_dir`:

```shell
./obj_dir/demo
```

### Switching Demo

To switch between the different demos, change the render instance near line 110 in `top_demo`, then rerun make.

* `render_line` - single diagonal line
* `render_edge` - line around the edge of the screen buffer
* `render_cube` - cube outline from nine lines
* `render_triangles` - three triangle outlines

### Fullscreen Mode

To run in fullscreen mode, edit `main_demo.cpp` so that `FULLSCREEN = true`, then rebuild.

You can quit the demo with the usual key combination: Ctrl-Q on Linux or Command-Q on macOS.

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
