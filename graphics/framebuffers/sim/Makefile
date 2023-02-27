## Project F: Framebuffers - Verilator Sim Makefile
## (C)2023 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/framebuffers/

VFLAGS = -O3 --x-assign fast --x-initial fast --noassert
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Verilog Library
PROJF_LIBS += -I../../../lib/clock
PROJF_LIBS += -I../../../lib/display
PROJF_LIBS += -I../../../lib/maths
PROJF_LIBS += -I../../../lib/memory

david_mono: david_mono.exe
david_16colr: david_16colr.exe
david_scale: david_scale.exe
david_fizzle: david_fizzle.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator ${VFLAGS} -I.. ${PROJF_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: david_mono david_16colr david_scale david_fizzle

clean:
	rm -rf ./obj_dir

.PHONY: all clean
