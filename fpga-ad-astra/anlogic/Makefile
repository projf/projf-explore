## Project F: FPGA Ad Astra - lichee Tang Makefile
## (C)2020 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io

# configuration
SHELL = /bin/sh
FPGA_DEV = eagle_s20
FPGA_PKG = BG256
ADC = licheeTang.adc
ADD_SRC = bram.sv clock_gen.sv
ADD_SRC += ../display_timings.sv ../lfsr.sv ../sprite.sv ../starfield.sv

top_lfsr: top_lfsr.bit
top_starfields: top_starfields.bit
top_hello_en: top_hello_en.bit
top_hello_jp: top_hello_jp.bit
top_greet: top_greet.bit

%.tcl: %.v
	echo "import_device $(FPGA_DEV).db -package $(FPGA_PKG)" > $@
	echo "read_verilog $^ -top $*" >> $@
	echo "read_adc $(ADC)" >> $@
	echo "optimize_rtl" >> $@
	echo "map_macro" >> $@
	echo "map" >> $@
	echo "pack" >> $@
	echo "place" >> $@
	echo "route" >> $@
	echo "report_area -io_info -file $*.area" >> $@
	echo "bitgen -bit $*.bit -version 0X0000 -g ucode:00000000000000000000000000000000" >> $@

%.v: %.sv
	yosys -ql $*-yosys.log -p 'synth_anlogic -top $*; write_verilog $@' $< $(ADD_SRC)

%.bit: %.tcl
	$(TD_HOME)/bin/td $^

clean:
	rm -f *.log *.svf *.tde *.bit *.v *.area *.h top*.tcl top*.asc top*.rpt top*.bit top*yosys.log

all: top_lfsr top_starfields top_hello_en top_hello_jp top_greet

.PHONY: all clean
