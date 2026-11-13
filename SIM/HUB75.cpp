#include "HUB75.h"
#include <algorithm>
#include <cstdio>
#include <cstdlib>

HUB75::HUB75(CData &r0, CData &g0, CData &b0, CData &r1, CData &g1, CData &b1,
             CData &addr, CData &clk_out, CData &latch, CData &oe)
    : r0_(r0), g0_(g0), b0_(b0), r1_(r1), g1_(g1), b1_(b1), addr_(addr),
      clk_out_(clk_out), latch_(latch), oe_(oe), prev_clk_(0), prev_latch_(0),
      latched_addr_(0), max_brightness_(1), cycle_counter_(0),
      refresh_interval_(50000) {
  shift_reg_.resize(WIDTH, {0, 0, 0, 0, 0, 0});
  latched_row_.resize(WIDTH, {0, 0, 0, 0, 0, 0});

  acc_r_.resize(WIDTH * HEIGHT, 0);
  acc_g_.resize(WIDTH * HEIGHT, 0);
  acc_b_.resize(WIDTH * HEIGHT, 0);
  framebuffer_.resize(WIDTH * HEIGHT * 3, 0);

  if (!glfwInit()) {
    fprintf(stderr, "HUB75: Could not initialize GLFW\n");
    exit(-1);
  }

  glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
  // Scale the 64x64 matrix by 8 so it's visible on modern screens (512x512)
  window_ = glfwCreateWindow(WIDTH * 8, HEIGHT * 8, "FemtoRV32 HUB75 Matrix",
                             nullptr, nullptr);
  if (!window_) {
    fprintf(stderr, "HUB75: Could not create GLFW window\n");
    exit(-1);
  }

  glfwMakeContextCurrent(window_);
  glfwSwapInterval(0); 
  glPixelZoom(8.0f, 8.0f);
}

HUB75::~HUB75() {
  if (window_) {
    glfwDestroyWindow(window_);
  }
}

void HUB75::flush_pending() {
    if (!pending_cycles_) return;

    int row0 = latched_addr_;
    int row1 = row0 + HALF_H;

    if (row0 < HALF_H && row1 < HEIGHT) {
        for (int x = 0; x < WIDTH; ++x) {
            const PixelBit& p = latched_row_[(WIDTH - 1) - x];
            int i0 = row0 * WIDTH + x;
            int i1 = row1 * WIDTH + x;

            acc_r_[i0] += p.r0 * pending_cycles_;
            acc_g_[i0] += p.g0 * pending_cycles_;
            acc_b_[i0] += p.b0 * pending_cycles_;

            acc_r_[i1] += p.r1 * pending_cycles_;
            acc_g_[i1] += p.g1 * pending_cycles_;
            acc_b_[i1] += p.b1 * pending_cycles_;
        }
        max_brightness_ += pending_cycles_;
    }
    pending_cycles_ = 0;
}

void HUB75::eval() {
    if (!prev_clk_ && clk_out_) {
        for (int i = WIDTH - 1; i > 0; --i) {
            shift_reg_[i] = shift_reg_[i - 1];
        }
        shift_reg_[0] = {r0_, g0_, b0_, r1_, g1_, b1_};
    }
    prev_clk_ = clk_out_;

    if (!prev_latch_ && latch_) {
        flush_pending();                 
        latched_row_  = shift_reg_;
        latched_addr_ = addr_;

        static int latch_count = 0;
        if (latch_count++ % 1000 == 0)
            printf("HUB75: Received 1000 latch pulses. Driver is running\n");
    }
    prev_latch_ = latch_;

    if (!oe_) pending_cycles_++;

    cycle_counter_++;
    if (cycle_counter_ >= refresh_interval_) {
        redraw();
        cycle_counter_ = 0;
    }
}

void HUB75::redraw() {
    flush_pending();                     

    if (max_brightness_ == 0) max_brightness_ = 1;

    for (int y = 0; y < HEIGHT; ++y) {
        for (int x = 0; x < WIDTH; ++x) {
            int fb_idx  = ((HEIGHT - 1 - y) * WIDTH + x) * 3;
            int acc_idx = y * WIDTH + x;

            uint64_t r = ((uint64_t)acc_r_[acc_idx] * 255 * HALF_H) / max_brightness_;
            uint64_t g = ((uint64_t)acc_g_[acc_idx] * 255 * HALF_H) / max_brightness_;
            uint64_t b = ((uint64_t)acc_b_[acc_idx] * 255 * HALF_H) / max_brightness_;

            framebuffer_[fb_idx + 0] = (uint8_t)std::min<uint64_t>(r, 255);
            framebuffer_[fb_idx + 1] = (uint8_t)std::min<uint64_t>(g, 255);
            framebuffer_[fb_idx + 2] = (uint8_t)std::min<uint64_t>(b, 255);

            acc_r_[acc_idx] = 0;
            acc_g_[acc_idx] = 0;
            acc_b_[acc_idx] = 0;
        }
    }

    max_brightness_ = 1;

    glfwPollEvents();
    glClear(GL_COLOR_BUFFER_BIT);
    glRasterPos2f(-1.0f, -1.0f);
    glDrawPixels(WIDTH, HEIGHT, GL_RGB, GL_UNSIGNED_BYTE, framebuffer_.data());
    glfwSwapBuffers(window_);
}
