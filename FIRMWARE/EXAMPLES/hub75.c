#include "../LIBFEMTORV32/femtorv32.h"
#include <stdint.h>
#include "hub75.h"

#define HUB75_BASE_ADDR (IO_BASE | IO_BIT_TO_OFFSET(IO_HUB75_bit))

#define LAYER_BG (0U << 15)
#define LAYER_SPRITE (1U << 15)
#define LAYER_TEXT (2U << 15)

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
  if (x >= 64 || y >= 64) {
    return;
  }

  uint32_t pixel_addr = ((uint32_t)y * 64U) + (uint32_t)x;

  uint32_t address_offset =
      ((pixel_addr & 0x00FFU) << 2) | ((pixel_addr & 0x0F00U) << 3);

  uint32_t data_to_write = color;

  volatile uint32_t *ptr =
      (volatile uint32_t *)(HUB75_BASE_ADDR | layer | address_offset);
  *ptr = data_to_write;
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
                uint32_t pixel_addr = (px_y * 64U) + px_x;
                uint32_t address_offset = ((pixel_addr & 0x00FFU) << 2) | ((pixel_addr & 0x0F00U) << 3);
                volatile uint32_t *ptr = (volatile uint32_t *)(HUB75_BASE_ADDR | layer | address_offset);
                *ptr = (uint32_t)asset[index];
            }
            index++;
        }
    }
}

void main(void) {
  while (1) {
    draw_asset(LAYER_BG, 0, 0, 64, 64, waitingScreen);
    delay(10);
    draw_asset(LAYER_BG, 0, 0, 64, 64, GameSelector2);
    delay(10);
    draw_asset(LAYER_BG, 0, 0, 64, 64, GameSelector);
    delay(10);
  }
}
