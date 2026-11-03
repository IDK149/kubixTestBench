#include "MAX7219.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

MAX7219::MAX7219(CData &DIN, CData &CLK, CData &CS)
    : DIN_(DIN), CLK_(CLK), CS_(CS), prev_CLK_(0), prev_CS_(1), shift_word_(0),
      bit_count_(0), rows_{}, scan_limit_(7), intensity_(8), shutdown_(true),
      display_test_(false), window_(nullptr) {
  if (!glfwInit()) {
    std::fprintf(stderr, "Could not initialize GLFW for MAX7219\n");
    std::exit(EXIT_FAILURE);
  }

  glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
  window_ = glfwCreateWindow(256, 256, "FemtoRV32 MAX7219", nullptr, nullptr);
  if (window_ == nullptr) {
    std::fprintf(stderr, "Could not create MAX7219 window\n");
    std::exit(EXIT_FAILURE);
  }
  redraw();
}

void MAX7219::eval() {
  // MAX7219 receives a word MSB first while chip select is low.
  if (prev_CS_ && !CS_) {
    shift_word_ = 0;
    bit_count_ = 0;
  }

  if (!CS_ && CLK_ && !prev_CLK_) {
    if (bit_count_ < 16) {
      shift_word_ = static_cast<uint16_t>((shift_word_ << 1) | (DIN_ & 1));
      ++bit_count_;
    }
  }

  // The RTL raises CS after the sixteenth clock; that edge latches the word.
  if (!prev_CS_ && CS_) {
    if (bit_count_ == 16) {
      latch_word();
    }
    bit_count_ = 0;
  }

  prev_CLK_ = CLK_;
  prev_CS_ = CS_;
}

void MAX7219::latch_word() {
  const uint8_t address = static_cast<uint8_t>((shift_word_ >> 8) & 0x0f);
  const uint8_t data = static_cast<uint8_t>(shift_word_ & 0xff);

  if (address >= 1 && address <= 8) {
    rows_[address - 1] = data;
    redraw();
  } else {
    switch (address) {
    case 0x0a: // Intensity register
      intensity_ = data & 0x0f;
      redraw();
      break;
    case 0x0b: // Scan limit register
      scan_limit_ = data & 0x07;
      redraw();
      break;
    case 0x0c: // Shutdown register (1 = normal operation)
      shutdown_ = (data & 1) == 0;
      redraw();
      break;
    case 0x0f: // Display test register
      display_test_ = (data & 1) != 0;
      redraw();
      break;
    default:
      // Decode mode and other control registers do not change this matrix view.
      break;
    }
  }
}

void MAX7219::redraw() {
  // Each source pixel is expanded to a 32x32 square for a clear 8x8 view.
  uint8_t pixels[8 * 8 * 3];
  const uint8_t green = static_cast<uint8_t>(32 + intensity_ * 14);

  for (unsigned int y = 0; y < 8; ++y) {
    for (unsigned int x = 0; x < 8; ++x) {
      const bool row_enabled = y <= scan_limit_;
      const bool on = !shutdown_ &&
                      (display_test_ || (row_enabled && ((rows_[y] >> x) & 1)));

      // OpenGL's first pixel row is at the bottom; invert y for top-down rows.
      const unsigned int offset = ((7 - y) * 8 + x) * 3;
      pixels[offset + 0] = on ? 24 : 0;
      pixels[offset + 1] = on ? green : 0;
      pixels[offset + 2] = on ? 48 : 0;
    }
  }

  glfwMakeContextCurrent(window_);
  glViewport(0, 0, 256, 256);
  glClearColor(0.f, 0.f, 0.f, 1.f);
  glClear(GL_COLOR_BUFFER_BIT);
  glRasterPos2f(-1.f, -1.f);
  glPixelZoom(32.f, 32.f);
  glDrawPixels(8, 8, GL_RGB, GL_UNSIGNED_BYTE, pixels);
  glfwSwapBuffers(window_);
}
