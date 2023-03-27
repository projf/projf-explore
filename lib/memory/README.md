# Memory - Verilog Library

Memory Verilog designs from [Project F](https://projectf.io), including ROM, block ram, and SPRAM. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* [rom_async.sv](rom_async.sv) - asynchronous ROM in logic (no clock)
* [rom_sync.sv](rom_sync.sv) - synchronous ROM in logic (uses clock)
* [bram_sdp.sv](bram_sdp.sv) - simple dual-port block RAM (one read port, one write port)
* [ice40/spram.sv](ice40/spram.sv) - iCE40 single port RAM (16-bit data width)
* [ice40/spram_nibble.sv](ice40/spram_nibble.sv) - iCE40 single port RAM (4-bit data width)

Find other modules in the [Library](../).

## Blog Posts

The following blog posts document and make use of these memory modules:

* Practical ROM usage: [Hardware Spites](https://projectf.io/posts/hardware-sprites/)
* Practical BRAM usage: [Lines & Triangles](https://projectf.io/posts/lines-and-triangles/)
* [SPRAM on iCE40 FPGA](https://projectf.io/posts/spram-ice40-fpga/) - learn how to use SPRAM with Yosys and contrast it with Block RAM
* [Initialize Memory in Verilog](https://projectf.io/posts/initialize-memory-in-verilog/) - use `$readmemh` and `$readmemb` to initialize the contents of ROM or RAM

## Memory Modules Interface

These memory modules share similar parameters:

* `WIDTH` - data width in bits (may be renamed `DATAW` in future)
* `DEPTH` - memory depth (number of elements)
* `INIT_F` - data file to load into memory at initialization
* `ADDRW` - address width; by default this is calculated with `$clog2(DEPTH)`

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
