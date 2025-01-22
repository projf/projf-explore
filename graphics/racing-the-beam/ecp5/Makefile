## Project F: Racing the Beam - ULX3S Makefile
## Copyright Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/racing-the-beam/

## FPGA IC (enable one)
# FPGA_TYPE = 12k  # LFE5U-12
# FPGA_TYPE = 25k  # LFE5U-25
# FPGA_TYPE = 45k  # LFE5U-45
FPGA_TYPE = 85k  # LFE5U-85

## configuration
SHELL = /bin/sh
FPGA_PKG = CABGA381  # IC package
FPGA_SPEED = 8       # FPGA speed grade (6,7,8) - all parts seem fine with fastest speed
LPF = ulx3s.lpf      # pins and constraints
TARGET_FREQ = 74     # target frequency (MHz) for 1280x720

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/display/ecp5/dvi_generator.sv
ADD_SRC += ${PATH_LIB}/display/tmds_encoder_dvi.sv
ADD_SRC += ../simple_720p.sv

rasterbars: rasterbars.bit rasterbars.svf
hitomezashi: hitomezashi.bit hitomezashi.svf
hello: hello.bit hello.svf
colour_cycle: colour_cycle.bit colour_cycle.svf
bounce: bounce.bit bounce.svf

# synthesis
%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'synth_ecp5 -top top_$(basename $@) -json $@' $< $(ADD_SRC)

# place and route
%.config: %.json
	nextpnr-ecp5 --${FPGA_TYPE} --package ${FPGA_PKG} --freq ${TARGET_FREQ} --speed ${FPGA_SPEED} --json $< --textcfg $@ --lpf ${LPF}

# pack bitstream
%.bit: %.config
	ecppack --compress $< $@

# pack SVF (Serial Vector Format)
%.svf: %.config
	ecppack --compress --input $< --svf $@

all: rasterbars hitomezashi hello colour_cycle bounce

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
