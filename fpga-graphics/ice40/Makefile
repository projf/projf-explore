## Project F: FPGA Graphics: iCEBreaker Makefile
## (C)2020 Will Green, Open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/fpga-graphics/

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
PCF = icebreaker.pcf
ADD_SRC = clock_gen.sv ../display_timings.sv

# override constraints for VGA targets
top_square_vga top_beam_vga: PCF = icebreaker_vga.pcf

top_square: top_square.rpt top_square.bin
top_beam: top_beam.rpt top_beam.bin
top_square_vga: top_square_vga.rpt top_square_vga.bin
top_beam_vga: top_beam_vga.rpt top_beam_vga.bin

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

dvi: top_beam top_square
vga: top_beam_vga top_square_vga
all: dvi vga

.PHONY: dvi vga all clean
