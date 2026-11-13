#ifndef HUB75_H
#define HUB75_H

#include <verilated.h>
#include <GLFW/glfw3.h>
#include <vector>
#include <cstdint>

class HUB75 {
public:
    // Panel dimensions (Set to 64x64 for standard square panels)
    static constexpr int WIDTH  = 64;
    static constexpr int HEIGHT = 64;
    static constexpr int HALF_H = HEIGHT / 2;

    HUB75(
        CData& r0, CData& g0, CData& b0,
        CData& r1, CData& g1, CData& b1,
        CData& addr,
        CData& clk_out,
        CData& latch,
        CData& oe
    );
    ~HUB75();

    void eval();
    void redraw();

private:
    uint32_t pending_cycles_ = 0;
    void flush_pending();
    // Verilator signal references
    CData& r0_; CData& g0_; CData& b0_;
    CData& r1_; CData& g1_; CData& b1_;
    CData& addr_;
    CData& clk_out_;
    CData& latch_;
    CData& oe_;

    // Edge detection
    uint8_t prev_clk_;
    uint8_t prev_latch_;

    // Shift registers for pixel data
    struct PixelBit {
        uint8_t r0, g0, b0;
        uint8_t r1, g1, b1;
    };
    std::vector<PixelBit> shift_reg_;
    std::vector<PixelBit> latched_row_;
    uint8_t latched_addr_;

    // Accumulators for PWM/BCM simulation
    std::vector<uint32_t> acc_r_, acc_g_, acc_b_;
    uint32_t max_brightness_;
    
    // OpenGL state
    std::vector<uint8_t> framebuffer_;
    GLFWwindow* window_;

    uint64_t cycle_counter_;
    uint64_t refresh_interval_;
};

#endif
