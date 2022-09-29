## Project F: Framebuffers - ulx3s Makefile
## (C) 2022 Will Green, (C) 2022 Tristan Itschner, 
## open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/framebuffers/

# configuration
SHELL = /bin/sh
FPGA_PKG = CABGA381
FPGA_TYPE = 85k
PCF = ulx3s_v20.lpf

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_480p.sv

ADD_SRC += ../simple_480p.sv
ADD_SRC += ${PATH_LIB}/display/ulx3s/pix2gpdi.v
ADD_SRC += ${PATH_LIB}/display/ulx3s/tmds_encoder.v

all: square flag_ethiopia flag_sweden colour

square:        square.bit
flag_ethiopia: flag_ethiopia.bit
flag_sweden:   flag_sweden.bit
colour:        colour.bit

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'hierarchy -top top_$(basename $@); synth_ecp5 -json $@' $< $(ADD_SRC)

%.config: %.json
	nextpnr-ecp5 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --lpf ${PCF} --textcfg $@ --log $(basename $@).rpt --timing-allow-fail -r

%.bit: %.config
	ecppack $< $(subst top_,,$@)

clean:
	rm -f *.json *.rpt *.bit *yosys.log

.PHONY: all clean
