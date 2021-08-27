## Project F: 2D Shapes - iCEBreaker Makefile
## (C)2021 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC  = ${PATH_LIB}/clock/xd.sv
ADD_SRC += ${PATH_LIB}/clock/ice40/clock_gen_480p.sv
ADD_SRC += ${PATH_LIB}/display/display_timings_480p.sv
ADD_SRC += ${PATH_LIB}/display/ice40/framebuffer_spram.sv
ADD_SRC += ${PATH_LIB}/display/linebuffer.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_circle.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_line.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_line_1d.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_rectangle.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_rectangle_fill.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_triangle_fill.sv
ADD_SRC += ${PATH_LIB}/maths/lfsr.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ${PATH_LIB}/memory/ice40/bram_sdp.sv
ADD_SRC += ${PATH_LIB}/memory/ice40/spram_nibble.sv

top_castle: top_castle.rpt top_castle.bin
top_rectangles: top_rectangles.rpt top_rectangles.bin
top_rectangles_fill: top_rectangles_fill.rpt top_rectangles_fill.bin
top_triangles_fill: top_triangles_fill.rpt top_triangles_fill.bin
top_cube_fill: top_cube_fill.rpt top_cube_fill.bin
top_circles: top_circles.rpt top_circles.bin

%.json: %.sv $(ADD_SRC)
	yosys -ql $(subst .json,,$@)-yosys.log -p 'synth_ice40 -abc2 -top $(subst .json,,$@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $@

clean:
	rm -f top*.json top*.asc top*.rpt top*.bin top*yosys.log

all: top_castle top_circles top_rectangles top_rectangles_fill top_triangles_fill top_cube_fill

.PHONY: all clean
