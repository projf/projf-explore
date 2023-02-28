## Project F: Racing the Beam - Verilator Sim Makefile
## (C)2023 Will Green, open source hardware released under the MIT License
## Learn more at https://projectf.io/posts/racing-the-beam/

VFLAGS = -O3 --x-assign fast --x-initial fast --noassert
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

rasterbars: rasterbars.exe
hitomezashi: hitomezashi.exe
hello: hello.exe
colour_cycle: colour_cycle.exe
bounce: bounce.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.sv
	verilator ${VFLAGS} -I.. ${PROJF_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: rasterbars hitomezashi hello colour_cycle bounce

clean:
	rm -rf ./obj_dir

.PHONY: all clean
