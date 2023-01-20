## Project F Library - divu cocotb Test Bench Makefile
## (C)2023 Will Green, open source software released under the MIT License
## Learn more at https://projectf.io/verilog-lib/

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

DUT = divu
VERILOG_SOURCES += $(PWD)/../${DUT}.sv
TOPLEVEL = ${DUT}
MODULE = ${DUT}

# pass Verilog module parameters to Icarus Verilog
COMPILE_ARGS += -P${DUT}.WIDTH=8 -P${DUT}.FBITS=4

# each test Makefile needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build_${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
