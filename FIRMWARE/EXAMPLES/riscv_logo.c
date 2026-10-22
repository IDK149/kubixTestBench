/*
 * FEMTORV32 - FEMTOSOC demo program:
 * Display a static RISC-V logo.
 */

#include "../LIBFEMTOGL/femtoGL.h"

/* Each entry is a palette index, not a direct RGB pixel. */
static const uint8_t logo[16][16] = {
   {7,7,7,7,7,7,5,3,3,3,3,3,3,3,3,7},
   {7,7,7,7,7,7,7,5,3,3,3,3,3,3,3,7},
   {1,1,1,1,2,7,7,7,3,3,3,3,3,3,3,7},
   {0,0,0,0,0,1,7,7,5,3,3,3,3,3,3,7},
   {0,0,0,0,0,0,7,7,6,3,3,3,3,3,6,7},
   {0,0,0,0,0,0,7,7,5,3,3,3,3,4,7,7},
   {0,0,0,0,0,2,7,7,4,3,3,3,3,7,7,7},
   {0,2,2,2,7,7,7,6,3,3,3,3,6,7,7,7},
   {0,7,7,7,7,7,6,3,3,3,3,5,7,7,2,7},
   {0,1,7,7,7,4,3,3,3,3,3,7,7,7,0,7},
   {0,0,2,7,7,6,3,3,3,3,6,7,7,1,0,7},
   {0,0,0,2,7,7,5,3,3,5,7,7,2,0,0,7},
   {0,0,0,0,7,7,7,5,4,7,7,2,0,0,0,7},
   {0,0,0,0,0,7,7,7,7,7,7,0,0,0,0,7},
   {0,0,0,0,0,1,7,7,7,7,1,0,0,0,0,7},
   {7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7}
};

/* RGB565 colors corresponding to the eight indexes above. */
static const uint16_t cmap[8] = {
   GL_RGB(0x28,0x33,0x74),
   GL_RGB(0x7B,0x80,0x9B),
   GL_RGB(0xAA,0xAC,0xBC),
   GL_RGB(0xF9,0xB1,0x15),
   GL_RGB(0xF9,0xBE,0x65),
   GL_RGB(0xF9,0xC7,0x82),
   GL_RGB(0xFC,0xD8,0xB0),
   GL_RGB(0xFA,0xFB,0xF8)
};

void main() RV32_FASTCODE;

void main() {
    GL_init(GL_MODE_CHOOSE_RGB);
    GL_clear();

    /* Center a square image, preserving its aspect ratio on any screen. */
    uint16_t side = GL_width < GL_height ? GL_width : GL_height;
    uint16_t x0 = (GL_width - side) / 2;
    uint16_t y0 = (GL_height - side) / 2;
    GL_write_window(x0, y0, x0 + side - 1, y0 + side - 1);

    /* Nearest-neighbor enlargement from 16x16 to the centered screen area. */
    for(uint16_t y = 0; y < side; ++y) {
        uint16_t source_y = (uint32_t)y * 16 / side;
        for(uint16_t x = 0; x < side; ++x) {
            uint16_t source_x = (uint32_t)x * 16 / side;
            GL_WRITE_DATA_UINT16(cmap[logo[source_y][source_x]]);
        }
    }

    /* The display retains the pixels, so no animation/redraw loop is needed. */
    for(;;) { }
}
