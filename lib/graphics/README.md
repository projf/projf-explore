# Graphics - Verilog Library

Verilog graphics designs used across Project F.  
Learn more at [projectf.io](https://projectf.io/) and follow [@WillFlux](https://twitter.com/WillFlux) for updates.

## Verilog Modules

* [draw_line](draw_line.sv) - Bresenham’s line algorithm
* [draw_line_1d.sv](draw_line_1d.sv) - Draw straight line (left to right only)
* [draw_rectangle](draw_rectangle.sv) - Draw a rectangle outline
* [draw_rectangle_fill](draw_rectangle_fill.sv) - Draw a filled rectangle
* [draw_triangle](draw_triangle.sv) - Draw a triangle outline
* [draw_triangle_fill](draw_triangle_fill.sv) - Draw a filled triangle

You can find Vivado test benches in the [xc7](xc7) directory.    
For modules to drive a display, see [display](../display/); for other library modules, see the [Library](../) root.

## Blog Posts

The following blog posts document and make use of these graphics designs:

* [Lines and Triangles](https://projectf.io/posts/lines-and-triangles/) - drawing lines and triangles with a framebuffer
* [2D Shapes](https://projectf.io/posts/fpga-shapes/) - filled shapes and drawing pictures
* Animated Shapes - animating shapes (coming soon)

## Graphics Interface

These graphic modules share a similar interface:

* `input: clk` - clock
* `input: rst` - synchronous reset (active high)
* `input: start` - start drawing (if currently idle)
* `input: oe` - output enable (allows drawing to be paused)
* `input: (x0,y0)` - vertex 0
* `input: (x1,y1)` - vertex 1
* `input: (x2,y2)` - vertex 2 (used by triangles)
* `output: (x,y)` - output drawing coordinate
* `output: drawing` - graphics are being drawn at `(x,y)`
* `output: complete` - drawing is complete (remains high)
* `output: done` - drawing is complete (high for one tick)

Coordinates signed with width in bits set by parameter `CORDW`.  
The default coordinate width is 16-bits for a range from -32,768 to 32,767.

Drawing order or direction may differ from the order coordinates are given;
for example, drawing doesn't necesserily begin from `(x0,y0)`.
