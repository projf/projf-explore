## Project F: Hardware Sprites - iCEBreaker Makefile
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_CM  = ../../common
ADD_SRC  = ${PATH_CM}/display_timings.sv ${PATH_CM}/rom_sync.sv
ADD_SRC += ${PATH_CM}/ice40/clock_gen.sv
ADD_SRC += ../sprite_v1.sv ../sprite_v2.sv ../sprite_v3.sv ../sprite.sv

top_hedgehog: top_hedgehog.rpt top_hedgehog.bin
top_sprite_v1: top_sprite_v1.rpt top_sprite_v1.bin
top_sprite_v2: top_sprite_v2.rpt top_sprite_v2.bin
top_sprite_v3: top_sprite_v3.rpt top_sprite_v3.bin
top_sprite_v3a: top_sprite_v3a.rpt top_sprite_v3a.bin
top_hedgehog_v1: top_hedgehog_v1.rpt top_hedgehog_v1.bin

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

all: top_sprite_v1 top_sprite_v2 top_sprite_v3 top_sprite_v3a top_hedgehog_v1 top_hedgehog

.PHONY: all clean
