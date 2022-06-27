## Project F: Framebuffers - Verilator Sim Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/hardware-sprites/

CFLAGS = -O2
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Verilog Library
PROJF_LIBS += -I../../../lib/memory
PROJF_LIBS += -I../../../lib/display

david_mono: david_mono.exe
david_mono_draw: david_mono_draw.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator -I../ ${PROJF_LIBS} -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${CFLAGS} ${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: david_mono david_mono_draw

clean:
	rm -rf ./obj_dir

.PHONY: all clean
