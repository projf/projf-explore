## Project F: Lines and Triangles - ULX3S Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/lines-and-triangles/

# render module version
RENDER_MODS = 160x90

# configuration
SHELL = /bin/sh
FPGA_PKG = CABGA381
FPGA_TYPE = 85k
PCF = ulx3s_v20.lpf

# included modules
PATH_LIB = ../../../lib
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_480p.sv
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_1080p_30hz.sv
ADD_SRC += ${PATH_LIB}/clock/ulx3s/clock_720p.sv
ADD_SRC += ${PATH_LIB}/display/display_1080p_cvtrbv2.sv
ADD_SRC += ${PATH_LIB}/display/display_720p_cvtrbv2.sv
ADD_SRC += ${PATH_LIB}/clock/xd2.sv
ADD_SRC += ${PATH_LIB}/display/bitmap_addr.sv
ADD_SRC += ${PATH_LIB}/display/clut_simple.sv
ADD_SRC += ${PATH_LIB}/display/display_480p.sv
ADD_SRC += ${PATH_LIB}/display/linebuffer_simple.sv
ADD_SRC += ${PATH_LIB}/graphics/draw_*.sv
ADD_SRC += ${PATH_LIB}/memory/bram_sdp.sv
ADD_SRC += ../${RENDER_MODS}/render_*.sv
ADD_SRC += ${PATH_LIB}/display/ulx3s/pix2gpdi.v
ADD_SRC += ${PATH_LIB}/display/ulx3s/tmds_encoder.v

demo: demo.bit

%.json: top_%.sv $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'hierarchy -top top_$(basename $@); synth_ecp5 -json $@' $< $(ADD_SRC)

%.config: %.json
	nextpnr-ecp5 --${FPGA_TYPE} --package ${FPGA_PKG} --json $< --lpf ${PCF} --textcfg $@ --log $(basename $@).rpt --timing-allow-fail -r

%.bit: %.config
	ecppack $< $(subst top_,,$@)

clean:
	rm -f *.json *.rpt *.bit *yosys.log

.PHONY: all clean
