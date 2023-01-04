# Essential - Verilog Library

Essential Verilog designs from [Project F](https://projectf.io) that don't fit in another category. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* [debounce.sv](debounce.sv) - button debouncing
* [xc7/async_reset.sv](xc7/async_reset.sv) - asynchronous reset for Xilinx 7 Series

Locate Vivado test benches in the [xc7](xc7) directory.  
Find other modules in the [Library](../).

## Blog Posts

Button debouncing is used in [Hello Arty Part 3](https://projectf.io/posts/hello-arty-3/) and [Pong](https://projectf.io/posts/fpga-pong/).

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
