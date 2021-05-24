## Project F: Ad Astra - iCEBreaker Makefile
## (C)2021 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC  = ${PATH_LIB}/clock/ice40/clock_gen_480p.sv
ADD_SRC += ${PATH_LIB}/display/display_timings_480p.sv
ADD_SRC += ${PATH_LIB}/maths/lfsr.sv
ADD_SRC += ${PATH_LIB}/memory/rom_sync.sv
ADD_SRC += ../sprite.sv ../starfield.sv

top_greet: top_greet.rpt top_greet.bin
top_greet_v1: top_greet_v1.rpt top_greet_v1.bin
top_lfsr: top_lfsr.rpt top_lfsr.bin
top_starfields: top_starfields.rpt top_starfields.bin
top_space_f: top_space_f.rpt top_space_f.bin
top_hello_en: top_hello_en.rpt top_hello_en.bin
top_hello_jp: top_hello_jp.rpt top_hello_jp.bin

# Uses ABC logic lib version 9 for improved timing with complex sprite designs
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

all: top_lfsr top_starfields top_space_f top_hello_en top_hello_jp top_greet_v1 top_greet

.PHONY: all clean
