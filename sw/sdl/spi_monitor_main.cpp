#define SDL_MAIN_USE_CALLBACKS 1

#include <array>
#include <cstdint>
#include <iostream>

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <verilated.h>

#include "Vtop.h"

static constexpr int WIDTH = 240;
static constexpr int HEIGHT = 240;
static constexpr int DISPLAY_SCALE = 3;
static constexpr int PANEL_PITCH = WIDTH * static_cast<int>(sizeof(uint16_t));

static SDL_Window* window = NULL;
static SDL_Renderer* renderer = NULL;
static SDL_Texture* panel_texture = NULL;
static Vtop* top = NULL;
static std::array<uint16_t, WIDTH * HEIGHT> panel_ram = {};
static int completed_frames = 0;

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

static bool present_panel() {
  if (!SDL_UpdateTexture(panel_texture, NULL, panel_ram.data(), PANEL_PITCH)) {
    SDL_Log("Couldn't update panel texture: %s", SDL_GetError());
    return false;
  }

  SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
  SDL_RenderClear(renderer);
  if (!SDL_RenderTexture(renderer, panel_texture, NULL, NULL)) {
    SDL_Log("Couldn't render panel texture: %s", SDL_GetError());
    return false;
  }

  SDL_RenderPresent(renderer);
  return true;
}

SDL_AppResult SDL_AppInit(void** appstate, int argc, char* argv[]) {
  if (0 && argc && argv) {
  }

  Verilated::debug(0);
  Verilated::randReset(2);
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  Verilated::mkdir("logs");

  top = new Vtop;
  top->clk = 0;
  top->rst_n = 0;
  top->start = 0;
  top->eval();

  SDL_SetAppMetadata("custom-chip-spi-monitor", "1.0",
                     "com.customchip.monitor");

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  if (!SDL_CreateWindowAndRenderer(
          "custom-chip-spi-monitor", WIDTH * DISPLAY_SCALE,
          HEIGHT * DISPLAY_SCALE, 0, &window, &renderer)) {
    SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  panel_texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB565,
                                    SDL_TEXTUREACCESS_STREAMING, WIDTH,
                                    HEIGHT);
  if (!panel_texture) {
    SDL_Log("Couldn't create panel texture: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  SDL_SetRenderLogicalPresentation(renderer, WIDTH, HEIGHT,
                                   SDL_LOGICAL_PRESENTATION_LETTERBOX);
  panel_ram.fill(0);
  if (!present_panel()) {
    return SDL_APP_FAILURE;
  }

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void* appstate, SDL_Event* event) {
  if (event->type == SDL_EVENT_QUIT) {
    return SDL_APP_SUCCESS;
  }
  if (event->type == SDL_EVENT_KEY_DOWN) {
    if (event->key.key == SDLK_C && (event->key.mod & SDL_KMOD_CTRL)) {
      return SDL_APP_SUCCESS;
    }
  }

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void* appstate) {
  static int reset_hold = 5;
  static bool frame_request_pending = false;
  static int start_hold_cycles = 0;

  if (!Verilated::gotFinish()) {
    top->clk = !top->clk;
    top->eval();
    main_time++;
    if (reset_hold > 0) {
      top->rst_n = 0;
      top->start = 0;
      frame_request_pending = false;
      start_hold_cycles = 0;
      reset_hold -= 1;
    } else if (reset_hold == 0) {
      top->rst_n = 1;
      top->start = 0;
      frame_request_pending = true;
      reset_hold -= 1;
    } else {
      top->rst_n = 1;

      if (top->done) {
        frame_request_pending = true;
      }

      if (frame_request_pending && top->ready && start_hold_cycles == 0) {
        start_hold_cycles = 2;
        frame_request_pending = false;
      }

      top->start = (start_hold_cycles > 0);
      if (start_hold_cycles > 0) {
        start_hold_cycles -= 1;
      }
    }

    top->eval();

    if (top->clk && top->monitor_pixel_valid) {
      const uint32_t x = top->monitor_x;
      const uint32_t y = top->monitor_y;

      if (x < WIDTH && y < HEIGHT) {
        panel_ram[y * WIDTH + x] = top->monitor_rgb565;
      }

      if (top->monitor_frame_start) {
        std::cout << "SPI panel: RAM write started at time " << main_time
                  << std::endl;
      }

      if (top->monitor_frame_end) {
        completed_frames += 1;
        if (!present_panel()) {
          return SDL_APP_FAILURE;
        }
        std::cout << "SPI panel: presented frame " << completed_frames
                  << " at time " << main_time << std::endl;
      }
    }
  }

  return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void* appstate, SDL_AppResult result) {
  if (panel_texture != NULL) {
    SDL_DestroyTexture(panel_texture);
    panel_texture = NULL;
  }

  if (top != NULL) {
    top->final();
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif
    delete top;
    top = NULL;
  }

  if (renderer != NULL) {
    SDL_DestroyRenderer(renderer);
    renderer = NULL;
  }

  if (window != NULL) {
    SDL_DestroyWindow(window);
    window = NULL;
  }

  SDL_Quit();
}
