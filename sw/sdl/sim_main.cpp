// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

#define SDL_MAIN_USE_CALLBACKS 1 /* use the callbacks instead of main() */

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <stdio.h>
#include <verilated.h>

#include "Vtop.h"

static SDL_Window* window = NULL;
static SDL_Renderer* renderer = NULL;
static Vtop* top = NULL;

#define WIDTH 240
#define HEIGHT 240
#define DISPLAY_SCALE 3

vluint64_t main_time = 0;
double sc_time_stamp() {
  return main_time;  // Note does conversion to real, to match SystemC
}

// THe main function gets the system verilog code
SDL_AppResult SDL_AppInit(void** appstate, int argc, char* argv[]) {
  // This example started with the Verilator example files.
  // Please see those examples for commented sources, here:
  // https://github.com/verilator/verilator/tree/master/examples

  if (0 && argc && argv) {
  }

  Verilated::debug(0);
  Verilated::randReset(2);
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  Verilated::mkdir("logs");

  top = new Vtop;

  SDL_SetAppMetadata("custom-chip-sim", "1.0", "com.customchip.sim");

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  if (!SDL_CreateWindowAndRenderer("custom-chip-sim", WIDTH * DISPLAY_SCALE, HEIGHT * DISPLAY_SCALE,
                                   0, &window, &renderer)) {
    SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  SDL_SetRenderLogicalPresentation(renderer, WIDTH, HEIGHT, SDL_LOGICAL_PRESENTATION_LETTERBOX);
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void* appstate, SDL_Event* event) {
  if (event->type == SDL_EVENT_QUIT) {
    return SDL_APP_SUCCESS; /* end the program, reporting success to the OS. */
  }
  // Checking for if Ctrl c pressed
  if (event->type == SDL_EVENT_KEY_DOWN) {
    if (event->key.key == SDLK_C && (event->key.mod & SDL_KMOD_CTRL)) {
      return SDL_APP_SUCCESS;  // Exit the app
    }
  }

  return SDL_APP_CONTINUE; /* carry on with the program! */
}

SDL_AppResult SDL_AppIterate(void* appstate) {
  const double now = ((double)SDL_GetTicks()) / 1000.0; /* convert from milliseconds to seconds. */
  /* choose the color for the frame we will draw. The sine wave trick makes it
   * fade between colors smoothly. */
  const float red = (float)(0.5 + 0.5 * SDL_sin(now));
  const float green = (float)(0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 2 / 3));
  const float blue = (float)(0.5 + 0.5 * SDL_sin(now + SDL_PI_D * 4 / 3));

  /* as you can see from this, rendering draws over whatever was drawn before
   * it. */
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE); /* black, full alpha */
  SDL_RenderClear(renderer);                                   /* start with a blank canvas. */
  SDL_SetRenderDrawColorFloat(renderer, red, green, blue,
                              SDL_ALPHA_OPAQUE_FLOAT); /* new color, full alpha. */
  // SDL_RenderPoint(renderer, static_cast<float>(top->out1),
  // static_cast<float>(top-]>out2));

  /* You can also draw single points with SDL_RenderPoint(), but it's
     cheaper (sometimes significantly so) to do them all at once. */
  // printf("Pixel value %f \n", static_cast<float>(top->out1));
  top->eval();
  SDL_RenderPresent(renderer); /* put it all on the screen! */

  return SDL_APP_CONTINUE; /* carry on with the program! */
}

// top->clk = 0;
void SDL_AppQuit(void* appstate, SDL_AppResult result) {
  /* SDL will clean up the window/renderer for us. */
  top->final();
#if VM_COVERAGE
  Verilated::mkdir("logs");
  VerilatedCov::write("logs/coverage.dat");
#endif
  delete top;
  top = NULL;
}
