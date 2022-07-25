## Project F: Framebuffers - iCEBreaker Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/framebuffers/

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ice40/clock_480p.sv
ADD_SRC += ${PATH_LIB}/clock/xd2.sv
ADD_SRC += ${PATH_LIB}/display/clut_simple.sv
ADD_SRC += ${PATH_LIB}/display/display_480p.sv
ADD_SRC += ${PATH_LIB}/display/linebuffer_simple.sv
ADD_SRC += ${PATH_LIB}/maths/lfsr.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv

david_mono: david_mono.rpt david_mono.bin
david_16colr: david_16colr.rpt david_16colr.bin
david_scale: david_scale.rpt david_scale.bin
david_fizzle: david_fizzle.rpt david_fizzle.bin

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $(subst top_,,$@)

all: david_mono david_16colr david_scale david_fizzle

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean
