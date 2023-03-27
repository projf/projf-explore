# Clock - Verilog Library

Clock-related Verilog designs from [Project F](https://projectf.io), including PLL and clock domain crossing. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* [xd.sv](xd.sv) - clock domain crossing (CDC) with pulse [[docs](https://projectf.io//posts/lib-clock-xd/)]
* Lattice iCE40 (12 MHz board clock)
  * [ice40/clock_480p.sv](ice40/clock_480p.sv) - 25.125 MHz clock for VGA 640x480 ~60 Hz
* Xilinx 7 Series (100 MHz board clock)
  * [xc7/clock_480p.sv](xc7/clock_480p.sv) - 25.2 & 126 MHz clocks for VGA 640x480 60Hz
  * [xc7/clock_720p.sv](xc7/clock_720p.sv) - 74.25 & 371.25 MHz clocks for 1280x720 60Hz 
  * [xc7/clock_1080p.sv](xc7/clock_1080p.sv) - 148.5 MHz & 742.5 MHz clocks for 1920x1080 60Hz
  * [xc7/clock_sys.sv](xc7/clock_sys.sv) - 125 MHz clock for general system use

_The 5x clock outputs in the Xilinx 7 Series designs are used for DVI/HDMI TMDS encoding._

Locate Vivado test benches in the [xc7](xc7) directory.  
Find other modules in the [Library](../).

### Clock Lock

The clock frequency generation modules include a lock signal. You should wait for clock lock before using the generated clock. For example, we hold the display controller in reset until the clock is locked so we don't send any spurious signals to the screen:

```verilog
clock_480p clock_pix_inst (
    .clk_100m,
    .rst(!btn_rst_n),  // reset button is active low
    .clk_pix,
    .clk_pix_5x,
    .clk_pix_locked
);
always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

display_480p #(.CORDW(CORDW)) display_inst (
    .clk_pix,
    .rst_pix,
    ...
```

## Blog Posts

If you're new to FPGA development, check out the explanation of clocks in [Hello Arty Part 2](https://projectf.io/posts/hello-arty-2/).

The [FPGA Graphics](https://projectf.io/posts/fpga-graphics/) series makes extensive use of these clock generation modules. The [Framebuffers](https://projectf.io/posts/framebuffers/) post includes examples of `xc7/clock_480p.sv`, `xc7/clock_sys.sv` and `xd.sv`. 

See [Simple Clock Domain Crossing](https://projectf.io/posts/lib-clock-xd/) for documentation of the **xd** module.

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
