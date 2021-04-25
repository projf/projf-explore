# Exploring FPGAs from Project F

Project F brings FPGAs to life with exciting [open-source](LICENSE) designs you can build on.  
Learn more at [projectf.io](https://projectf.io/) and follow [@WillFlux](https://twitter.com/WillFlux) for updates.

## Graphics

In this series, we explore graphics at the hardware level and get a feel for the power of FPGAs. If you're new to the
series, start by reading [FPGA Graphics](https://projectf.io/posts/fpga-graphics/).

* **FPGA Graphics**: [Designs](graphics/fpga-graphics) - [Blog](https://projectf.io/posts/fpga-graphics/)
* **Pong**: [Designs](graphics/pong) - [Blog](https://projectf.io/posts/fpga-pong/)
* **Hardware Sprites**: [Designs](graphics/hardware-sprites) - [Blog](https://projectf.io/posts/hardware-sprites/)
* **Ad Astra**: [Designs](graphics/ad-astra) - [Blog](https://projectf.io/posts/fpga-ad-astra/)
* **Framebuffers**: [Designs](graphics/framebuffers) - [Blog](https://projectf.io/posts/framebuffers/)
* **Life on Screen** - [Designs](graphics/life-on-screen) - [Blog](https://projectf.io/posts/life-on-screen/)
* **Lines and Triangles** - [Designs](graphics/lines-and-triangles) - [Blog](https://projectf.io/posts/lines-and-triangles/)
* **2D Shapes** - [Designs](graphics/2d-shapes) - [Blog](https://projectf.io/posts/fpga-shapes/)
* **Simple 3D** - _coming soon_

## Hello

A three-part introduction to FPGA development with Verilog; currently available for two boards: the Arty A7 and Nexys Video.

* **Hello Arty**: [Designs](hello/hello-arty) - [Blog 1](https://projectf.io/posts/hello-arty-1/) - [Blog 2](https://projectf.io/posts/hello-arty-2/)
* **Hello Nexys**: [Designs](hello/hello-nexys) - [Blog 1](https://projectf.io/posts/hello-nexys-1/) - [Blog 2](https://projectf.io/posts/hello-nexys-2/)

The third part will be available in spring 2021.

## Maths

Maths & Algorithms is our next topic. Stay tuned for this series in 2021.

## Library

Verilog library used across Project F. See [Library](lib/) for details.

## Requirements

### FPGA

Our designs seek to be vendor-neutral, but some functionality requires
support for vendor primitives. We currently support two FPGA architectures:

* **XC7** - Xilinx Series 7 FPGAs, such as Spartan-7 and Arty-7
* **iCE40** - Lattice iCE40 FPGAs, such as iCE40 UltraPlus

Porting to other architectures should be straightforward.

### SystemVerilog

We use a few choice features from SystemVerilog to make Verilog a little more pleasant. If you’re familiar with Verilog, you’ll have no trouble. All the designs are tested with Yosys and Vivado.
