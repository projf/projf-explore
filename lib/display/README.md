# Display - Verilog Library

Video display Verilog designs from [Project F](https://projectf.io) covering signal generation, TMDS, and buffers. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* Display Signal Generation
  * [display_480p.sv](display_480p.sv) - 640x480 60Hz using traditional VGA timings
  * [display_720p.sv](display_720p.sv) - 1280x720 60Hz (720p)
  * [display_1080p.sv](display_1080p.sv) - 1920x1080 60Hz (1080p)
* Display Buffering
  * [linebuffer_simple.sv](linebuffer_simple.sv) - line buffer for performance and clock isolation
* Signal Encoding
  * [tmds_encoder_dvi.sv](tmds_encoder_dvi.sv) - TMDS encoder for DVI (HDMI compatible, but no audio)
  * [xc7/dvi_generator.sv](xc7/dvi_generator.sv) - generates a DVI signal on Xilinx 7 Series
  * [xc7/oserdes_10b.sv](xc7/oserdes_10b.sv) - 10:1 Output Serializer for Xilinx 7 Series with OSERDESE2
  * [xc7/tmds_out.sv](xc7/tmds_out.sv) - output TMDS to I/O pins on Xilinx 7 Series with OBUFDS

Locate Vivado test benches in the [xc7](xc7) directory.  
For modules to draw lines and shapes, see [graphics](../graphics/).  
Find other modules in the [Library](../).

## Blog Posts

* The [FPGA Graphics](https://projectf.io/posts/fpga-graphics/) series makes extensive use of these display modules
* [Framebuffers](https://projectf.io/posts/framebuffers/) has examples of framebuffers using the linebuffer module
* [Animated Shapes](https://projectf.io/posts/animated-shapes/) has examples of double-buffering
* [Video Timings: VGA, SVGA, 720p, 1080p](https://projectf.io/posts/video-timings-vga-720p-1080p/) has all the gory details on video timings

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
