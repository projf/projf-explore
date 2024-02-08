## Project F: FPGA Graphics - iCEBreaker Makefile
## Copyright Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/fpga-graphics/

# configuration
SHELL = /bin/sh
FPGA_PKG = sg48
FPGA_TYPE = up5k
PCF = icebreaker.pcf

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ice40/clock_480p.sv
ADD_SRC += ../simple_480p.sv

square: square.rpt square.bin
flag_ethiopia: flag_ethiopia.rpt flag_ethiopia.bin
flag_sweden: flag_sweden.rpt flag_sweden.bin
colour: colour.rpt colour.bin

# synthesis
%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'synth_ice40 -abc9 -device u -top top_$(basename $@) -json $@' $< $(ADD_SRC)

# place and route
%.asc: %.json
	nextpnr-ice40 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --pcf ${PCF} --asc $@

# timing
%.rpt: %.asc
	icetime -d ${FPGA_TYPE} -mtr $@ $<

# pack bitstream
%.bin: %.asc
	icepack $< $(subst top_,,$@)

all: square flag_ethiopia flag_sweden colour

clean:
	rm -f *.json *.asc *.rpt *.bin *yosys.log

.PHONY: all clean
