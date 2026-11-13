#include "assets.h"
#include "include/hub75.h"

int main(void) {
  hub75_draw_pixel(LAYER_SPRITE, 32, 32, COLOR_RED);
  while (1) {
    draw_asset(LAYER_BG, 0, 0, 64, 64, waitingScreen);
    delay(10);
  }
  return 0;
}
