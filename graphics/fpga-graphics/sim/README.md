# Simulations for Beginning FPGA Graphics

This folder contains Verilator simulations to accompany the Project F blog post: **[Beginning FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**.

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate a hardware design on your PC: no dev board required! Verilator is fast, but it's still much slower than an FPGA. However, for these simple designs, you can reach 60 FPS on a modern PC.

If you're new to graphics simulations check out the blog post on [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

If you have a dev board, see the main [Beginning FPGA Graphics README](../README.md) for build instructions.

## Demos

* Square - `square`
* Flag of Ethiopia - `flag_ethiopia`
* Flag of Sweden - `flag_sweden`
* Colour - `colour`

![](../../../doc/img/flag_ethiopia.png?raw=true "")

_Traditional flag of Ethiopia running as a Verilator simulation._

## Tested Versions

These simulations have been tested with:

* Verilator 4.038 (Ubuntu 22.04 amd64)
* Verilator 5.006 (macOS 13 arm64)

These simulations run at 640x480.

## Build & Run

If this is the first time you've used Verilator and SDL, you need to [install dependencies](#installing-dependencies).

Make sure you're in the sim directory `projf-explore/graphics/fpga-graphics/sim`.

Build a specific simulation (square, flag_ethiopia, flag_sweden, or colour):

```shell
make square
```

Or build all simulations:

```shell
make all
```

Run the simulation executables from `obj_dir`:

```shell
./obj_dir/square
```

You can quit the simulation by pressing the **Q** key.

If you want to manually build a simulation, here's an example for 'square':

```shell
verilator -I.. -cc top_square.sv --exe main_square.cpp -o square \
    -CFLAGS "$(sdl2-config --cflags)" -LDFLAGS "$(sdl2-config --libs)"

make -C ./obj_dir -f Vtop_square.mk
```

_Note: all these designs use [simple_480p.sv](../simple_480p.sv) from the main [FPGA Graphics](../) folder._

## Installing Dependencies

To build the simulations, you need:

1. C++ Toolchain
2. Verilator
3. SDL

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

### Windows

Windows users can run Verilator with SDL under Windows Subsystem for Linux. [WSL2 supports GUI Linux apps](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps) in Windows 10 Build 19044+ and Windows 11.

Once you have WSL2 running, you can use the Linux instructions (above).

I have successfully tested Verilator/SDL simulations with Debian 12 running on Windows 10.
