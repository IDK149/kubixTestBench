#include <stdint.h>
#include "femtorv32.h"
#define HUB75_RGB444

#define HUB75_BASE_ADDR   (IO_BASE | IO_BIT_TO_OFFSET(IO_HUB75_bit))

#define LAYER_BG          (0U << 15)
#define LAYER_SPRITE      (1U << 15)
#define LAYER_TEXT        (2U << 15)

static inline uint32_t rgb888_to_rgb444(uint32_t color_24bit) {
    uint32_t r = (color_24bit >> 16) & 0xFF;
    uint32_t g = (color_24bit >> 8)  & 0xFF;
    uint32_t b = (color_24bit)       & 0xFF;

    return (((r >> 4) & 0x0F) << 8) |
           (((g >> 4) & 0x0F) << 4) |
            ((b >> 4) & 0x0F);
}

static inline void hub75_draw_pixel(uint32_t layer, uint8_t x, uint8_t y, uint32_t color_24bit) {
    if (x >= 64 || y >= 64) {
        return;
    }

    uint32_t pixel_addr = ((uint32_t)y * 64U) + (uint32_t)x;

    uint32_t address_offset = ((pixel_addr & 0x00FFU) << 2) | ((pixel_addr & 0x0F00U) << 3);

#if defined(HUB75_RGB444)
    uint32_t data_to_write = rgb888_to_rgb444(color_24bit);
#else
    uint32_t data_to_write = color_24bit;
#endif

    volatile uint32_t* ptr = (volatile uint32_t*)(HUB75_BASE_ADDR | layer | address_offset);
    *ptr = data_to_write;
}

static void fill_rect(uint32_t layer, int x0, int y0, int w, int h, uint32_t c) {
    for (int y = y0; y < y0 + h; y++)
        for (int x = x0; x < x0 + w; x++)
            hub75_draw_pixel(layer, x, y, c);
}

void main(void) {
    fill_rect(LAYER_BG, 0, 0, 64, 64, 0x000000);      // memory isn't guaranteed zero at boot

    for (int i = 0; i < 64; i++) {                     // white border
        hub75_draw_pixel(LAYER_BG, i, 0,  0xFFFFFF);
        hub75_draw_pixel(LAYER_BG, i, 63, 0xFFFFFF);
        hub75_draw_pixel(LAYER_BG, 0,  i, 0xFFFFFF);
        hub75_draw_pixel(LAYER_BG, 63, i, 0xFFFFFF);
    }

    fill_rect(LAYER_BG, 4,  4, 8, 8, 0xFF0000);        // red, green, blue squares
    fill_rect(LAYER_BG, 16, 4, 8, 8, 0x00FF00);
    fill_rect(LAYER_BG, 28, 4, 8, 8, 0x0000FF);

    for (int i = 0; i < 64; i++)                       // yellow diagonal on sprite layer
        hub75_draw_pixel(LAYER_SPRITE, i, i, 0xFFFF00);

    hub75_draw_pixel(LAYER_TEXT, 10, 5, 0xFFFFFF);     // text layer on top

    while (1) {}
}
