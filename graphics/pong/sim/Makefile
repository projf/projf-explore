## Project F: Pong - Verilator Sim Makefile
## (C)2022 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/fpga-pong/

CFLAGS = -O3
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Project F Library Path
PATH_LIB = ../../../lib/essential

pong: pong.exe
ball_paddles: ball_paddles.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator -I../ -I${PATH_LIB} -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${CFLAGS} ${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: pong ball_paddles

clean:
	rm -rf ./obj_dir

.PHONY: all clean
