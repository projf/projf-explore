# Display - Verilog Library

Video display Verilog designs from Project F covering signal generation, TMDS, and framebuffers. You can freely build on these [MIT licensed](../../LICENSE) designs for commercial and non-commercial projects. See the [Library](../) for other helpful Verilog modules or discover the [background to the Library](https://projectf.io/posts/verilog-library-announcement/).

Learn more at [projectf.io](https://projectf.io/), follow [@WillFlux](https://twitter.com/WillFlux) for updates, and join the FPGA discussion on [1BitSquared Discord](https://1bitsquared.com/pages/chat).

## Verilog Modules

* Display Signal Generation
  * [display_timings_480p.sv](display_timings_480p.sv) - 640x480 60 Hz using traditional VGA timings
  * [display_timings_720p.sv](display_timings_720p.sv) - 1280x720 60 Hz (720p)
  * [display_timings_1080p.sv](display_timings_1080p.sv) - 1920x1080 60 Hz (1080p)
* Framebuffer
  * [framebuffer_bram.sv](framebuffer_bram.sv) - framebuffer backed by block RAM (works with XC7 and iCE40)
  * [framebuffer_db_bram.sv](framebuffer_db_bram.sv) - double-buffered framebuffer backed by block RAM (recommended for XC7)
  * [ice40/framebuffer_spram.sv](ice40/framebuffer_spram.sv) - framebuffer backed by SPRAM (works with iCE40)
  * `ice40/framebuffer_db_spram.sv` - double-buffered framebuffer backed by SPRAM (coming soon)
  * [linebuffer.sv](linebuffer.sv) - line buffer used by the framebuffer designs for performance and clock isolation
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
* [Framebuffers](https://projectf.io/posts/framebuffers/) has examples of framebuffers and linebuffers
* [Animated Shapes](https://projectf.io/posts/animated-shapes/) has examples of double-buffering
* [Video Timings: VGA, SVGA, 720p, 1080p](https://projectf.io/posts/video-timings-vga-720p-1080p/) has all the gory details on video timings

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
