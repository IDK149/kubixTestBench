#ifndef FEMTORV32_SIM_MAX7219_H
#define FEMTORV32_SIM_MAX7219_H

#include "verilated.h"
#include <GLFW/glfw3.h>
#include <cstdint>

// Visual model of the MAX7219 serial interface and its 8x8 LED matrix.
class MAX7219 {
public:
    MAX7219(CData& DIN, CData& CLK, CData& CS);
    void eval();

private:
    void redraw();
    void latch_word();

    CData& DIN_;
    CData& CLK_;
    CData& CS_;
    CData prev_CLK_;
    CData prev_CS_;
    uint16_t shift_word_;
    unsigned int bit_count_;
    uint8_t rows_[8];
    uint8_t scan_limit_;
    uint8_t intensity_;
    bool shutdown_;
    bool display_test_;
    GLFWwindow* window_;
};

#endif
