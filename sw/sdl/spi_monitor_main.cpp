#define SDL_MAIN_USE_CALLBACKS 1

#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <verilated.h>

#include "Vtop.h"

static SDL_Window* window = NULL;
static SDL_Renderer* renderer = NULL;
static Vtop* top = NULL;

static constexpr int WIDTH = 240;
static constexpr int HEIGHT = 240;
static constexpr int DISPLAY_SCALE = 3;

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

static Uint8 expand_r(uint16_t rgb565) {
  return static_cast<Uint8>(((rgb565 >> 11) & 0x1F) << 3);
}
static Uint8 expand_g(uint16_t rgb565) {
  return static_cast<Uint8>(((rgb565 >> 5) & 0x3F) << 2);
}
static Uint8 expand_b(uint16_t rgb565) {
  return static_cast<Uint8>((rgb565 & 0x1F) << 3);
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

  SDL_SetRenderLogicalPresentation(renderer, WIDTH, HEIGHT,
                                   SDL_LOGICAL_PRESENTATION_LETTERBOX);
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
  SDL_RenderClear(renderer);
  SDL_RenderPresent(renderer);

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

  if (!Verilated::gotFinish()) {
    top->clk = !top->clk;
    top->eval();
    main_time++;
    if (reset_hold > 0) {
      top->rst_n = 0;
      top->start = 0;
      reset_hold -= 1;
    } else if (reset_hold == 0) {
      top->rst_n = 1;
      top->start = 1;
      reset_hold -= 1;
    } else {
      top->rst_n = 1;
      top->start = 0;
    }

    top->eval();

    if (top->monitor_pixel_valid) {
      const uint16_t rgb565 = top->monitor_rgb565;
      std::cout << "Pixel: (" << top->monitor_x << ", " << top->monitor_y
                << ") = RGB565(" << std::hex << rgb565 << std::dec << ")"
                << std::endl;
      SDL_SetRenderDrawColor(renderer, expand_r(rgb565), expand_g(rgb565),
                             expand_b(rgb565), SDL_ALPHA_OPAQUE);
      SDL_RenderPoint(renderer, static_cast<float>(top->monitor_x),
                      static_cast<float>(top->monitor_y));

      if (top->monitor_frame_end) {
        SDL_RenderPresent(renderer);
      }
    }
  }

  return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void* appstate, SDL_AppResult result) {
  if (top != NULL) {
    top->final();
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif
    delete top;
    top = NULL;
  }
}
