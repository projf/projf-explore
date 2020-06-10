## Project F: FPGA Ad Astra - iCEBreaker Makefile
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
PCF = icebreaker.pcf
ADD_SRC = bram.sv clock_gen.sv 
ADD_SRC += ../display_timings.sv ../lfsr.sv ../sprite.sv ../starfield.sv

top_lfsr: top_lfsr.rpt top_lfsr.bin
top_starfields: top_starfields.rpt top_starfields.bin
top_hello_en: top_hello_en.rpt top_hello_en.bin
top_hello_jp: top_hello_jp.rpt top_hello_jp.bin
top_greet: top_greet.rpt top_greet.bin

%.json: %.sv
	yosys -ql $(subst .json,,$@)-yosys.log -p 'synth_ice40 -top $(subst .json,,$@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --up5k --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d up5k -mtr $@ $<

%.bin: %.asc
	icepack $< $@

clean:
	rm -f top*.json top*.asc top*.rpt top*.bin top*yosys.log

all: top_lfsr top_starfields top_hello_en top_hello_jp top_greet

.PHONY: all clean
