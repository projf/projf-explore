// Project F: FPGA Graphics - Beam Verilator C++
// (C)2021 Will Green, open source software released under the MIT License
// Learn more at https://projectf.io

#include <stdio.h>
#include <SDL2/SDL.h>
#include "Vtop_beam.h"

const int SCREEN_WIDTH  = 640;
const int SCREEN_HEIGHT = 480;

typedef struct Pixel {  // for SDL texture
    uint8_t a;
    uint8_t b;
    uint8_t g;
    uint8_t r;
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if(SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed.\n");
        return 1;
    }

    SDL_Window*   sdl_window   = NULL;
    SDL_Renderer* sdl_renderer = NULL;
    SDL_Texture*  sdl_texture  = NULL;

    Pixel screenbuffer[SCREEN_WIDTH*SCREEN_HEIGHT];

	sdl_window = SDL_CreateWindow("Top Beam", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
	if (!sdl_window) {
		printf( "Window creation failed: %s\n", SDL_GetError());
        return 1;
	}

    sdl_renderer = SDL_CreateRenderer(sdl_window, -1, SDL_RENDERER_ACCELERATED);
	if (!sdl_renderer) {
		printf("Create renderer failed: %s\n", SDL_GetError());
        return 1;
	}

    sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, SCREEN_WIDTH, SCREEN_HEIGHT);
	if (!sdl_texture) {
		printf( "Texture creation failed: %s\n", SDL_GetError());
        return 1;
	}

    // initialize Verilog module
    Vtop_beam *top = new Vtop_beam;
    top->rst = 1;
    top->clk_pix = 0;
    top->eval();
    top->rst = 0;
    top->eval();

    while (1) {
        SDL_Event e;
        if (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) {
                break;
            }
        }

        top->clk_pix = 1;
        top->eval();
        top->clk_pix = 0;
        top->eval();

        if (top->sy < SCREEN_HEIGHT && top->sx < SCREEN_WIDTH) {
            Pixel *p = &screenbuffer[top->sy*SCREEN_WIDTH + top->sx];
            p->a = 0xFF;  // transparency
            p->b = top->sdl_b;
            p->g = top->sdl_g;
            p->r = top->sdl_r;
        }

        // update texture once per frame at start of blanking
        if (top->sy == SCREEN_HEIGHT && top->sx == 0) {
            SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, SCREEN_WIDTH*sizeof(Pixel));
            SDL_RenderClear(sdl_renderer);
            SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
            SDL_RenderPresent(sdl_renderer);
        }
    }

    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();
    return 0;
}
