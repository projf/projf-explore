# Clock - Verilog Library

Clock-related Verilog designs from Project F, including PLL and clock domain crossing. You can freely build on these [MIT licensed](../../LICENSE) designs. See the [Library](../) for other helpful Verilog modules and read the [verilog library overview](https://projectf.io/verilog-lib/) on the blog.

## Verilog Modules

* [xd.sv](xd.sv) - clock domain crossing (CDC) with pulse [[docs](https://projectf.io//posts/lib-clock-xd/)]
* Lattice iCE40 (12 MHz board clock)
  * [ice40/clock_480p.sv](ice40/clock_480p.sv) - PLL clock generation for VGA 640x480 (25.125 MHz)
* Xilinx 7 Series (100 MHz board clock)
  * [xc7/clock_480p.sv](xc7/clock_480p.sv) - PLL clock generation for VGA 640x480 (25.2 MHz)
  * [xc7/clock_720p.sv](xc7/clock_720p.sv) - PLL clock generation for 1280x720 (74.25 & 371.25 MHz)
  * [xc7/clock_1080p.sv](xc7/clock_1080p.sv) - PLL clock generation for 1920x1080 (148.5 MHz & 742.5 MHz)

_The 5x clocks in the Xilinx 7 Series designs are used for DVI/HDMI TMDS encoding._

Locate Vivado test benches in the [xc7](xc7) directory.  
Find other modules in the [Library](../).

## Blog Posts

If you're new to FPGA development, check out the explanation of clocks in [Hello Arty Part 2](https://projectf.io/posts/hello-arty-2/).

The [FPGA Graphics](https://projectf.io/posts/fpga-graphics/) series makes extensive use of these clock generation modules.

See [Simple Clock Domain Crossing](https://projectf.io/posts/lib-clock-xd/) for documentation of the **xd** module.

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
