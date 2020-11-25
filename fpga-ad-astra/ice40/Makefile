## Project F: FPGA Ad Astra - iCEBreaker Makefile
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_CM  = ../../common
ADD_SRC  = ${PATH_CM}/display_timings.sv ${PATH_CM}/lfsr.sv ${PATH_CM}/rom_sync.sv
ADD_SRC += ${PATH_CM}/ice40/clock_gen.sv
ADD_SRC += ../sprite.sv ../starfield.sv

top_greet: top_greet.rpt top_greet.bin
top_greet_v1: top_greet_v1.rpt top_greet_v1.bin
top_lfsr: top_lfsr.rpt top_lfsr.bin
top_starfields: top_starfields.rpt top_starfields.bin
top_space_f: top_space_f.rpt top_space_f.bin
top_hello_en: top_hello_en.rpt top_hello_en.bin
top_hello_jp: top_hello_jp.rpt top_hello_jp.bin

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

all: top_lfsr top_starfields top_space_f top_hello_en top_hello_jp top_greet_v1 top_greet

.PHONY: all clean
