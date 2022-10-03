# Simulation for Animated Shapes

This folder contains a Verilator simulation to accompany the Project F blog post: **[Animated Shapes](https://projectf.io/posts/animated-shapes/)**.

[Verilator](https://www.veripool.org/verilator/) creates C++ simulations of Verilog designs, while [SDL](https://www.libsdl.org) produces simple cross-platform graphics applications. By combining the two, you can simulate a hardware design on your PC: no dev board required! Verilator is fast, but it's still much slower than an FPGA. However, for these simple designs, you can reach 60 FPS on a modern PC.

If you're new to graphics simulations check out the blog post on [Verilog Simulation with Verilator and SDL](https://projectf.io/posts/verilog-sim-verilator-sdl/).

If you have a dev board, see the main [Animated Shapes README](../README.md) for build instructions.

## Demos

There is one demo top module that can draw different things.

_Full README to follow..._