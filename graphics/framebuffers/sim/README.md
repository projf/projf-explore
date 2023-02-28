# Simulations for Framebuffers

This folder contains Verilator simulations to accompany the Project F blog post: **[Framebuffers](https://projectf.io/posts/framebuffers/)**.

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate a hardware design on your PC: no dev board required! Verilator is fast, but it's still much slower than an FPGA. However, for these simple designs, you can reach 60 FPS on a modern PC.

If you're new to graphics simulations check out the blog post on [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

If you have a dev board, see the main [Framebuffers README](../README.md) for build instructions.

## Demos

All based on an image of David by Michelangelo.

* David Mono - 160x120 dithered monochrome image on 640x480 display
* David 16 Colour - 160x120 16-colour image on 640x480 display
* David Scale - 160x120 16-colour image scaled to fill 640x480 display
* David Fizzle - Fizzle fade on scaled image of David

![](../../../doc/img/framebuffers-fizzle.png?raw=true "")

_David by Michelangelo with fizzle fade from david\_fizzle simulation._

## Tested Versions

These simulations have been tested with:

* Verilator 4.038 (Ubuntu 22.04 amd64)
* Verilator 5.006 (macOS 13 arm64)

## Build & Run

If this is the first time you've used Verilator and SDL, you need to [install dependencies](#installing-dependencies).

Make sure you're in the sim directory `projf-explore/graphics/framebuffers/sim`.

Build a specific simulation (david_mono, david_scale etc.):

```shell
make david_scale
```

Or build all simulations:

```shell
make all
```

Run the simulation executables from `obj_dir`:

```shell
./obj_dir/david_scale
```

You can quit the simulation by pressing the **Q** key.

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
