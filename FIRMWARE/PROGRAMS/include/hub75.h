#include <stdint.h>
#include "../../LIBFEMTORV32/femtorv32.h"

#define HUB75_BASE_ADDR (IO_BASE | IO_BIT_TO_OFFSET(IO_HUB75_bit))

#define LAYER_BG 0U
#define LAYER_SPRITE 1U
#define LAYER_TEXT 2U

#define COLOR_BLACK   0x0000
#define COLOR_WHITE   0x0FFF
#define COLOR_RED     0x0F00
#define COLOR_GREEN   0x00F0
#define COLOR_BLUE    0x000F
#define COLOR_YELLOW  0x0FF0
#define COLOR_CYAN    0x00FF
#define COLOR_MAGENTA 0x0F0F

static inline void hub75_draw_pixel(uint32_t layer, uint8_t x, uint8_t y,
                                    uint32_t color) {
  if (x >= 64 || y >= 64)
    return;
  uint32_t word = (layer << 30) | ((uint32_t)y << 24) | ((uint32_t)x << 18) | color;
  *(volatile uint32_t*)HUB75_BASE_ADDR = word;

}

static void fill_rect(uint32_t layer, int x0, int y0, int w, int h,
                      uint32_t color) {
  for (int y = y0; y < y0 + h; y++)
    for (int x = x0; x < x0 + w; x++)
      hub75_draw_pixel(layer, x, y, color);
}

void draw_asset(uint32_t layer, int x0, int y0, int w, int h, const uint16_t *asset) {
    int index = 0;
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint32_t px_x = x0 + x;
            uint32_t px_y = y0 + y;
            if (px_x < 64 && px_y < 64) {
              hub75_draw_pixel(layer, px_x, px_y, asset[y*w + x]);
            }
            index++;
        }
    }
}
