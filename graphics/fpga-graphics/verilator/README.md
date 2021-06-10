# FPGA Graphics Verilator SDL Simulation

This folder contains Verilator simulations to accompany the Project F blog post: **[FPGA Graphics](https://projectf.io/posts/fpga-graphics/)**.

There are separate instructions for building _FPGA Graphics_ for [FPGA dev boards](../README.md) (iCEBreaker and Arty).

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate your design without needing an FPGA. Verilator is fast, but it's still much slower than an FPGA. For these single-threaded designs, you can expect around one frame per second on a modern PC.

![](../../../doc/img/top-bounce-verilator-sdl.png?raw=true "")

## Build & Run

If this is the first time you've used Verilator and SDL, you need to [install dependencies](#dependencies)!

Then navigate to the Verilator directory:

```bash
cd projf-explore/graphics/fpga-graphics/verilator
```

### Top Square

```bash
verilator -I../ -cc top_square.sv --exe main_square.cpp -LDFLAGS "`sdl2-config --libs`"
make -C ./obj_dir -f Vtop_square.mk
./obj_dir/Vtop_square
```

### Top Beam

```bash
verilator -I../ -cc top_beam.sv --exe main_beam.cpp -LDFLAGS "`sdl2-config --libs`"
make -C ./obj_dir -f Vtop_beam.mk
./obj_dir/Vtop_beam
```

### Top Bounce

```bash
verilator -I../ -cc top_bounce.sv --exe main_bounce.cpp -LDFLAGS "`sdl2-config --libs`"
make -C ./obj_dir -f Vtop_bounce.mk
./obj_dir/Vtop_bounce
```

## Dependencies

### Linux Install

For Debian and Ubuntu-based distros you can use the following. For other distros, check your docs, but there should be pre-built packages for everything you need.

You need a C++ toolchain:

```bash
apt update
apt install build-essential
```

You need to install Verilator and the dev version of SDL.

```bash
apt update
apt install verilator libsdl2-dev
```

That's it!

### macOS Install

Install [Xcode](https://developer.apple.com/xcode/) to get a C++ compiler and toolchain.

Install the [Homebrew](https://brew.sh/) package manager.

Once Homebrew is installed, you can run:

```bash
brew install verilator sdl2
```

And you're ready to go.

### Windows Install

Sorry, but I don't have installation instructions for Windows at the moment.
