## Project F: Framebuffers - iCEBreaker Makefile
## (C)2021 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_CM  = ../../common
ADD_SRC  = ${PATH_CM}/rom_async.sv ${PATH_CM}/lfsr.sv ${PATH_CM}/xd.sv
ADD_SRC += ${PATH_CM}/ice40/bram_sdp.sv ${PATH_CM}/ice40/clock_gen_480p.sv
ADD_SRC += ../display_timings_480p.sv ../framebuffer.sv ../linebuffer.sv

top_david: top_david.rpt top_david.bin
top_line: top_line.rpt top_line.bin
top_david_v1: top_david_v1.rpt top_david_v1.bin
top_david_v2: top_david_v2.rpt top_david_v2.bin
top_david_v3: top_david_v3.rpt top_david_v3.bin

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

all: top_david top_line top_david_v1 top_david_v2 top_david_v3

.PHONY: all clean
