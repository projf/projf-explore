## Project F: Racing the Beam - ULX3S Makefile
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
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_480p.v
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_720p.v
ADD_SRC += ${PATH_LIB}/display/ulx3s/pix2gpdi.sv
ADD_SRC += ${PATH_LIB}/display/ulx3s/tmds_8b_10b.sv
ADD_SRC += ../simple_480p.sv
ADD_SRC += ../simple_720p.sv

all: rasterbars hitomezashi hello colour_cycle bounce

rasterbars:   rasterbars.bit
hitomezashi:  hitomezashi.bit
hello:        hello.bit
colour_cycle: colour_cycle.bit
bounce:       bounce.bit

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-synth.log -p 'synth_ecp5 -top top_$(basename $@) -json $@' $< $(ADD_SRC)

%.config: %.json
	nextpnr-ecp5 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --lpf ${PCF} --textcfg $@ --log $(basename $@)-impl.log --timing-allow-fail -r

%.bit: %.config
	ecppack $< $(subst top_,,$@)

clean:
	rm -f *.json *.log *.bit

480p:
	sed -i "s/720p/480p/g" top_*.sv
	sed -i "s/localparam CORDW = [0-9]\+/localparam CORDW = 10/g" top_*.sv

720p:
	sed -i "s/480p/720p/g" top_*.sv
	sed -i "s/localparam CORDW = [0-9]\+/localparam CORDW = 12/g" top_*.sv

.PHONY: all clean
