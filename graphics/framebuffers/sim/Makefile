## Project F: Framebuffers - Verilator Sim Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/framebuffers/

CFLAGS = -O2
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Verilog Library
PROJF_LIBS += -I../../../lib/clock
PROJF_LIBS += -I../../../lib/display
PROJF_LIBS += -I../../../lib/memory

david_mono: david_mono.exe
david_mono_draw: david_mono_draw.exe
david_16colr: david_16colr.exe
david_scale: david_scale.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator -I../ ${PROJF_LIBS} -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${CFLAGS} ${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: david_mono david_mono_draw david_16colr david_scale

clean:
	rm -rf ./obj_dir

.PHONY: all clean
