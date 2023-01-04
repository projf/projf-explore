# Graphics - Verilog Library

Graphics Verilog designs from [Project F](https://projectf.io), including line and shape drawing. You can freely build on these [MIT licensed](../../LICENSE) designs. Get an overview of the whole lib from the [Verilog Library blog](https://projectf.io/verilog-lib/).

## Verilog Modules

* [draw_char](draw_char.sv) - Draw character glyph from bitmap font
* [draw_circle](draw_circle.sv) - Draw circle outline
* [draw_circle_fill](draw_circle_fill.sv) - Draw filled circle
* [draw_line](draw_line.sv) - Draw arbitrary straight line with Bresenham's algorithm
* [draw_line_1d.sv](draw_line_1d.sv) - Draw straight line (left to right only)
* [draw_rectangle](draw_rectangle.sv) - Draw rectangle outline
* [draw_rectangle_fill](draw_rectangle_fill.sv) - Draw filled rectangle
* [draw_triangle](draw_triangle.sv) - Draw triangle outline
* [draw_triangle_fill](draw_triangle_fill.sv) - Draw filled triangle

Locate Vivado test benches in the [xc7](xc7) directory.  
For modules to drive a display, see [display](../display/).  
Find other modules in the [Library](../).

## Blog Posts

The following blog posts document and make use of these graphics designs:

* [Lines and Triangles](https://projectf.io/posts/lines-and-triangles/) - drawing lines and triangles with a framebuffer
* [2D Shapes](https://projectf.io/posts/fpga-shapes/) - circles, filled shapes, and drawing pictures
* [Animated Shapes](https://projectf.io/posts/animated-shapes/) - animation and double-buffering

## Graphics Modules Interface

These graphic modules share a similar interface:

* `input: clk` - clock
* `input: rst` - synchronous reset (active high)
* `input: start` - start drawing (if currently idle)
* `input: oe` - output enable (allows drawing to be paused)
* `input: (x0,y0)` - vertex 0
* `input: (x1,y1)` - vertex 1
* `input: (x2,y2)` - vertex 2 (used by triangles)
* `input: r0` - radius (used by circles)
* `input: ucp` - Unicode code point (used by text)
* `output: (x,y)` - output drawing coordinate
* `output: drawing` - graphics are being drawn at `(x,y)`
* `output: busy` - drawing request in progress
* `output: done` - drawing is complete (high for one tick)

Graphics coordinates are signed, with a width in bits set by parameter `CORDW`.  
The default coordinate width is 16 bits for a range from -32,768 to 32,767.

Drawing order or direction may differ from the order coordinates are given;
for example, drawing doesn't necesserily begin from `(x0,y0)`.

## SystemVerilog?

These modules use a little SystemVerilog to make Verilog more pleasant, see the main [Library README](../README.md#systemverilog) for details.
