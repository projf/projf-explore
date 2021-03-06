## Project F: Lines and Triangles - iCEBreaker Makefile
## (C)2021 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_CM  = ../../common
ADD_SRC  = ${PATH_CM}/display_timings_480p.sv ${PATH_CM}/rom_async.sv
ADD_SRC += ${PATH_CM}/linebuffer.sv ${PATH_CM}/xd.sv
ADD_SRC += ${PATH_CM}/ice40/bram_sdp.sv ${PATH_CM}/ice40/clock_gen.sv
ADD_SRC += ../draw_line.sv ../draw_triangle.sv ../pix_addr.sv

top_triangles: top_triangles.rpt top_triangles.bin
top_line: top_line.rpt top_line.bin
top_cube: top_cube.rpt top_cube.bin

%.json: %.sv
	yosys -ql $(subst .json,,$@)-yosys.log -p 'synth_ice40 -top $(subst .json,,$@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $@

clean:
	rm -f top*.json top*.asc top*.rpt top*.bin top*yosys.log

all: top_triangles top_cube top_line

.PHONY: all clean
