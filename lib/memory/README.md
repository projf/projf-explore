# Memory - Verilog Library

Memory Verilog designs from Project F, including ROM, block ram, and SPRAM. You can freely build on these [MIT licensed](../../LICENSE) designs. See the [Library](../) for other helpful Verilog modules or discover the [background to the Library](https://projectf.io/posts/verilog-library-announcement/).

Learn more at [projectf.io](https://projectf.io/), follow [@WillFlux](https://mastodon.social/@WillFlux) for updates, and join the FPGA discussion on [1BitSquared Discord](https://discord.gg/cf869yDbXf).

## Verilog Modules

* [rom_async.sv](rom_async.sv) - asynchronous ROM in logic (no clock)
* [rom_sync.sv](rom_sync.sv) - synchronous ROM in logic (uses clock)
* [ice40/bram_sdp.sv](ice40/bram_sdp.sv) - iCE40 simple dual-port block RAM (one read port, one write port)
* [ice40/spram.sv](ice40/spram.sv) - iCE40 single port RAM (16-bit data width)
* [ice40/spram_nibble.sv](ice40/spram_nibble.sv) - iCE40 single port RAM (4-bit data width)
* [xc7/bram_sdp.sv](xc7/bram_sdp.sv) - XC7 simple dual-port block RAM (one read port, one write port)

Locate Vivado test benches in the [xc7](xc7) directory.  
Find other modules in the [Library](../).

## Blog Posts

The following blog posts document and make use of these memory modules:

* Practical ROM usage: [Hardware Spites](https://projectf.io/posts/hardware-sprites/)
* Practical BRAM and SPRAM usage: [Lines & Triangles](https://projectf.io/posts/lines-and-triangles/)
* [SPRAM on iCE40 FPGA](https://projectf.io/posts/spram-ice40-fpga/) - learn how to use SPRAM with Yosys and contrast it with Block RAM
* [Initialize Memory in Verilog](https://projectf.io/posts/initialize-memory-in-verilog/) - use $readmemh and $readmemb to initialize the contents of ROM or RAM

## Memory Modules Interface

These memory modules share similar parameters:

* `WIDTH` - data width in bits (may be renamed `DATAW` in future)
* `DEPTH` - memory depth (number of elements)
* `INIT_F` - data file to load into memory at initialization
* `ADDRW` - address width; by default this is calculated with `$clog2(DEPTH)`

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
