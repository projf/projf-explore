# Essential - Verilog Library

Essential Verilog designs from Project F that don't quite fit in another category. You can freely build on these [MIT licensed](../../LICENSE) designs. See the [Library](../) for other helpful Verilog modules or discover the [background to the Library](https://projectf.io/posts/verilog-library-announcement/).

Learn more at [projectf.io](https://projectf.io/), follow [@WillFlux](https://mastodon.social/@WillFlux) for updates, and join the FPGA discussion on [1BitSquared Discord](https://discord.gg/cf869yDbXf).

## Verilog Modules

* [debounce.sv](debounce.sv) - button debouncing
* [xc7/async_reset.sv](xc7/async_reset.sv) - asynchronous reset for Xilinx 7 Series

Locate Vivado test benches in the [xc7](xc7) directory.  
Find other modules in the [Library](../).

## Blog Posts

Button debouncing is used in [Hello Arty Part 3](https://projectf.io/posts/hello-arty-3/) and [Pong](https://projectf.io/posts/fpga-pong/).

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
