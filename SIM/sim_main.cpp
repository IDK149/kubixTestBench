#include "FPU_funcs.h"
#include "MAX7219.h"
#include "SSD1351.h"
#include "VfemtoRV32_bench.h"
#include "verilated.h"
#include <fenv.h>
#include <memory>
#include <xmmintrin.h>

#define SSD

int main(int argc, char **argv, char **env) {

  // simplest rounding = ignore LSBs
  fesetround(FE_TOWARDZERO);

  // for now, flush denormalized result to zero.
  _MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_ON);

  VfemtoRV32_bench top;

#ifdef MAX
  MAX7219 screen(top.ledmtx_DIN, top.ledmtx_CLK, top.ledmtx_CS);
#endif
#ifdef SSD
  SSD1351 screen(top.oled_DIN, top.oled_CLK, top.oled_CS, top.oled_DC,
                 top.oled_RST);
#endif

  top.pclk = 0;

  while (!Verilated::gotFinish()) {
    top.pclk = !top.pclk;
    top.eval();
    screen.eval();
    glfwPollEvents();
  }
  return 0;
}
