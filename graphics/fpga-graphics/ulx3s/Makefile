## Project F: FPGA Graphics - ULX3S Makefile
## (C) 2022 Will Green, (C) 2022 Tristan Itschner, 
## open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/framebuffers/

PATH_LIB = ../../../lib

# configuration
SHELL     = /bin/sh
FPGA_PKG  = CABGA381
FPGA_TYPE = 85k
PCF       = $(PATH_LIB)/boards/ulx3s/ulx3s_v20.lpf

# included modules
# TODO: 720p version
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_480p.v
# ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_720p.v
ADD_SRC += ${PATH_LIB}/display/ulx3s/pix2gpdi.sv
ADD_SRC += ${PATH_LIB}/display/ulx3s/tmds_8b_10b.sv
ADD_SRC += ../simple_480p.sv
#ADD_SRC += ../simple_720p.sv

all: square flag_ethiopia flag_sweden colour

square:        square.bit
flag_ethiopia: flag_ethiopia.bit
flag_sweden:   flag_sweden.bit
colour:        colour.bit

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-synth.log -p 'synth_ecp5 -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.config: %.json
	nextpnr-ecp5 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --lpf ${PCF} --textcfg $@ --log $(basename $@)-impl.log --timing-allow-fail -r

%.bit: %.config
	ecppack $< $(subst top_,,$@)

clean:
	rm -f *.json *.log *.bit

.PHONY: all clean
