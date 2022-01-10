## Project F: Lines and Triangles - iCEBreaker Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
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
ADD_SRC += ${PATH_LIB}/display/display_480p.sv
ADD_SRC += ${PATH_LIB}/display/ice40/framebuffer_spram.sv
ADD_SRC += ${PATH_LIB}/display/linebuffer.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_line.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_triangle.sv
ADD_SRC += ${PATH_LIB}/maths/lfsr.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ${PATH_LIB}/memory/ice40/bram_sdp.sv
ADD_SRC += ${PATH_LIB}/memory/ice40/spram_nibble.sv

top_triangles: top_triangles.rpt top_triangles.bin
top_line: top_line.rpt top_line.bin
top_cube: top_cube.rpt top_cube.bin
top_latency_check: top_latency_check.rpt top_latency_check.bin

%.json: %.sv $(ADD_SRC)
	yosys -ql $(subst .json,,$@)-yosys.log -p 'synth_ice40 -abc9 -device u -top $(subst .json,,$@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $@

clean:
	rm -f top*.json top*.asc top*.rpt top*.bin top*yosys.log

all: top_triangles top_cube top_line top_latency_check

.PHONY: all clean
