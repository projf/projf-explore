## Project F Library - Maths Test Bench Makefile
## (C)2023 Will Green, open source software released under the MIT License
## Learn more at https://projectf.io/verilog-lib/

div:
	make -f div.mk

divu:
	make -f divu.mk

divu_int:
	make -f divu_int.mk

all: div divu divu_int

clean:
	make -f div.mk clean
	make -f divu.mk clean
	make -f divu_int.mk clean
	rm -f results*.xml
	rm -rf __pycache__
	rm -rf sim_build

.PHONY: all clean
