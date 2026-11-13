#include "HUB75.h"
#include "VfemtoRV32_bench.h"
#include "verilated.h"
#include <fenv.h>
#include <memory>
#include <xmmintrin.h>

int main(int argc, char **argv, char **env) {

  fesetround(FE_TOWARDZERO);

  _MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_ON);

  VfemtoRV32_bench top;

  HUB75 screen(
        top.r0, top.g0, top.b0, 
        top.r1, top.g1, top.b1, 
        top.addr, top.clk_out, top.latch, top.oe
    );

  top.pclk = 0;

  while (!Verilated::gotFinish()) {
    top.pclk = !top.pclk;
    top.eval();
    screen.eval();
    glfwPollEvents();
  }
  return 0;
}
