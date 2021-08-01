## Project F: Framebuffers - iCEBreaker Makefile
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
ADD_SRC += ${PATH_LIB}/display/framebuffer_bram.sv
ADD_SRC += ${PATH_LIB}/display/linebuffer.sv
ADD_SRC += ${PATH_LIB}/maths/lfsr.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ${PATH_LIB}/memory/ice40/bram_sdp.sv 

top_david: top_david.rpt top_david.bin
top_line: top_line.rpt top_line.bin
top_david_v1: top_david_v1.rpt top_david_v1.bin
top_david_v2: top_david_v2.rpt top_david_v2.bin
top_david_v3: top_david_v3.rpt top_david_v3.bin

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

all: top_david top_line top_david_v1 top_david_v2 top_david_v3

.PHONY: all clean
