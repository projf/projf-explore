# Project F - FPGA Development

Project F is a little oasis where you can quench your thirst for FPGA knowledge and find accessible, [open-source](LICENSE) designs to learn from and build on. Our projects include the _Verilog Library_, _FPGA Graphics_, and _FPGA Maths_ tutorial series.

The [Project F website](https://projectf.io) features fifty blog posts on a wide range of FPGA and Verilog topics.

Follow [@WillFlux@mastodon.social](https://mastodon.social/@WillFlux) for updates. Join the [Project F Discussions](https://github.com/projf/projf-explore/discussions) and [1BitSquared Discord](https://discord.gg/cf869yDbXf).

![](doc/img/fpga-ad-astra-banner.png?raw=true "")

## Verilog Library

The Project F Library includes handy Verilog designs for everyone. From framebuffers and video output to division and square root, rom and ram, and even circle drawing. You can freely build on these [MIT licensed](../../LICENSE) designs.

Visit the [Library](lib/) for the Verilog designs or get an overview from the [Verilog Library blog post](https://projectf.io/verilog-lib/).

## FPGA Graphics

In this series, we learn about graphics at the hardware level and get a feel for the power of FPGAs. We'll learn how screens work, play Pong, create starfields and sprites, paint Michelangelo's David, draw lines and triangles, and animate characters and shapes. Along the way, you'll experience a range of designs and techniques, from memory and finite state machines to crossing clock domains and translating C algorithms into Verilog.

![](doc/img/fpga-graphics-banner.png?raw=true "")

* **Beginning FPGA Graphics**: [Designs](graphics/fpga-graphics) - [Blog](https://projectf.io/posts/fpga-graphics/)
* **Racing the Beam**: [Designs](graphics/racing-the-beam) - [Blog](https://projectf.io/posts/racing-the-beam/)
* **FPGA Pong**: [Designs](graphics/pong) - [Blog](https://projectf.io/posts/fpga-pong/)
* **Display Signals**: [Blog](https://projectf.io/posts/display-signals/) (no designs in git)
* **Hardware Sprites**: [Designs](graphics/hardware-sprites) - [Blog](https://projectf.io/posts/hardware-sprites/)
* **Framebuffers**: [Designs](graphics/framebuffers) - [Blog](https://projectf.io/posts/framebuffers/)
* **Lines and Triangles**: [Designs](graphics/lines-and-triangles) - [Blog](https://projectf.io/posts/lines-and-triangles/)
* **2D Shapes**: [Designs](graphics/2d-shapes) - [Blog](https://projectf.io/posts/fpga-shapes/)
* **Animated Shapes**: [Designs](graphics/animated-shapes) - [Blog](https://projectf.io/posts/animated-shapes/)

## Hello

A three-part introduction to FPGA development with Verilog with dev boards:

* **Hello Arty**: [Designs](hello/hello-arty) - [Blog 1](https://projectf.io/posts/hello-arty-1/) - [Blog 2](https://projectf.io/posts/hello-arty-2/) - [Blog 3](https://projectf.io/posts/hello-arty-3/)
* **Hello Nexys**: [Designs](hello/hello-nexys) - [Blog 1](https://projectf.io/posts/hello-nexys-1/) - [Blog 2](https://projectf.io/posts/hello-nexys-2/)

## Maths and Algorithms

Maths & Algorithms is our latest tutorial series:

* [Numbers in Verilog](https://projectf.io/posts/numbers-in-verilog/) - introduction to numbers in Verilog
* [Vectors and Arrays](https://projectf.io/posts/verilog-vectors-arrays) - working with Verilog vectors and arrays
* [Multiplication with DSPs](https://projectf.io/posts/multiplication-fpga-dsps) - efficient FPGA multiplication
* [Fixed-Point Numbers](https://projectf.io/posts/fixed-point-numbers-in-verilog/) - precision without complexity
* [Division in Verilog](https://projectf.io/posts/division-in-verilog) - divided we stand
* _More maths soon_

![](doc/img/sea-of-chaos.png?raw=true "")

## Demos and Effects

* **Ad Astra**: [Designs](demos/ad-astra) - [Blog](https://projectf.io/posts/fpga-ad-astra/) - greetings with starfields and hardware sprites
* **Castle Drawing**: [Designs](demos/castle-drawing) - [Blog](https://projectf.io/posts/castle-drawing/) - draw a castle and rainbow in 16 colours
* **Life on Screen**: [Designs](demos/life-on-screen) - [Blog](https://projectf.io/posts/life-on-screen/) - Conway's Game of Life in logic
* **Mandelbrot Set**: [Designs](demos/mandelbrot) - [Blog](https://projectf.io/posts/mandelbrot-verilog/) - Mandelbrot set with fixed-point maths
* **Rasterbars**: [Designs](demos/rasterbars) - [Blog](https://projectf.io/posts/rasterbars/) - classic animated colour bars
* **Sine Scroller**: [Designs](demos/sinescroll) - [Blog](https://projectf.io/posts/sinescroll/) - greet your viewers in style

![](doc/img/sinescroll-sim.png?raw=true "")

## Requirements

### FPGA Architecture

Our designs seek to be vendor-neutral, but some functionality requires
support for vendor primitives. We currently support two FPGA architectures:

* **XC7** - Xilinx 7 Series FPGAs, such as Spartan-7 and Artix-7
  * `BUFG`, `MMCME2_BASE`
  * HDMI support: `OBUFDS`, `OSERDES2`
* **iCE40** - Lattice iCE40 FPGAs, such as iCE40 UltraPlus
  * `SB_IO`, `SB_PLL40_PAD`, `SB_SPRAM256KA`

We also infer block ram (BRAM); see [lib/memory](lib/memory).

Porting to other architectures should be straightforward.

## SystemVerilog?

We use a few simple features of SystemVerilog to make Verilog more pleasant:

* `logic` type is safer and less work than using `wire` and `reg`
* `always_comb` and `always_ff` to make intent clear and catch mistakes
* `$clog2` to calculate vector widths (e.g. for addresses)
* `enum` to make finite state machines simpler to work with
* Matching names in module instances: `.clk_pix` instead of `.clk_pix(clk_pix)`

I believe these features are helpful, especially for beginners. All the SystemVerilog features are compatible with recent versions of Verilator, Yosys, Icarus Verilog, and Xilinx Vivado.

## Thank You, Sponsors!

Thank you to all my sponsors for supporting Project F. Special thanks go to the following: [David C. Norris](https://github.com/dcnorris), [Didier Malenfant](https://github.com/DidierMalenfant), [LaDirth](https://github.com/LaDirth), [matt venn](https://github.com/mattvenn), [Paul Sajna](https://github.com/sajattack), and [STjurny](https://github.com/STjurny) for their recent generosity.
