# Simulation for Pong

This folder contains a Verilator simulation to accompany the Project F blog post: **[Pong](https://projectf.io/posts/fpga-pong/)**.

This sim is based on `top_pong_v3`: it doesn't include user controls, so you can't play against the hardware, only watch. However, it should be straightforward to add controls via SDL if you want to make the game playable.

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate a hardware design on your PC: no dev board required! Verilator is fast, but it's still much slower than an FPGA. However, for this simple design, you can reach 60 FPS on a modern PC.

If you're new to graphics simulations check out [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).  

![Pong simulated on macOS](../../../doc/img/pong-verilator-sdl.png?raw=true "")

## Build & Run

If this is the first time you've used Verilator and SDL, you need to [install dependencies](#installing-dependencies).

Make sure you're in the sim directory `projf-explore/graphics/pong/sim`.

The use make to build:

```shell
make
```

Run the simulation executables from `obj_dir`:

```shell
./obj_dir/pong
```

_Note: this design uses [simple_480p.sv](../simple_480p.sv) from the main [Pong](../) folder._

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
apt update
apt install verilator libsdl2-dev
```

That's it!

_If you want to build the latest version of Verilator yourself, see [Building Verilator for Linux](https://projectf.io/posts/building-ice40-fpga-toolchain/#verilator)._

### macOS

Install [Xcode](https://developer.apple.com/xcode/) to get a C++ toolchain.

Install the [Homebrew](https://brew.sh/) package manager.

With Homebrew installed, you can run:

```shell
brew install verilator sdl2
```

And you're ready to go.
