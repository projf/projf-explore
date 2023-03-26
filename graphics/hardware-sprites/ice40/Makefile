## Project F: Hardware Sprites - iCEBreaker Makefile
## (C)2023 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/hardware-sprites/

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ice40/clock_480p.sv
ADD_SRC += ${PATH_LIB}/display/clut_simple.sv
ADD_SRC += ${PATH_LIB}/display/display_480p.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv
ADD_SRC += ${PATH_LIB}/memory/rom_async.sv
ADD_SRC += ../sprite_inline.sv
ADD_SRC += ../sprite_rom.sv
ADD_SRC += ../sprite.sv

tinyf_inline: tinyf_inline.rpt tinyf_inline.bin
tinyf_rom: tinyf_rom.rpt tinyf_rom.bin
tinyf_scale: tinyf_scale.rpt tinyf_scale.bin
tinyf_move: tinyf_move.rpt tinyf_move.bin
hourglass: hourglass.rpt hourglass.bin
hedgehog: hedgehog.rpt hedgehog.bin

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

%.bin: %.asc
	icepack $< $(subst top_,,$@)

all: tinyf_inline tinyf_rom tinyf_scale hourglass hedgehog

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean
