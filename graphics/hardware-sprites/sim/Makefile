## Project F: Hardware Sprites - Verilator Sim Makefile
## (C)2023 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/hardware-sprites/

VFLAGS = -O3 --x-assign fast --x-initial fast --noassert
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Verilog Library
PROJF_LIBS += -I../../../lib/display
PROJF_LIBS += -I../../../lib/memory

tinyf_inline: tinyf_inline.exe
tinyf_rom: tinyf_rom.exe
tinyf_scale: tinyf_scale.exe
tinyf_move: tinyf_move.exe
hourglass: hourglass.exe
hedgehog: hedgehog.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator ${VFLAGS} -I.. ${PROJF_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: tinyf_inline tinyf_rom tinyf_scale tinyf_move hourglass hedgehog

clean:
	rm -rf ./obj_dir

.PHONY: all clean
