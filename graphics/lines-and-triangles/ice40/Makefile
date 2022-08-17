## Project F: Lines and Triangles - iCEBreaker Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/lines-and-triangles/

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ice40/clock_480p.sv
ADD_SRC += ${PATH_LIB}/clock/xd2.sv
ADD_SRC += ${PATH_LIB}/display/bitmap_addr.sv
ADD_SRC += ${PATH_LIB}/display/clut_simple.sv
ADD_SRC += ${PATH_LIB}/display/display_480p.sv
ADD_SRC += ${PATH_LIB}/display/linebuffer_simple.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_line.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_triangle.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv
ADD_SRC += ../render_cube_sm.sv
ADD_SRC += ../render_line_sm.sv
ADD_SRC += ../render_triangles_sm.sv

demo: demo.rpt demo.bin

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $(subst top_,,$@)

all: demo

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean
