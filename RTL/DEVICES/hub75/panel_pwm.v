module panel_pwm(
    input  wire [23:0] pix_top,
    input  wire [23:0] pix_bottom,
    input  wire [4:0]  pwm_level,
    output wire r0, g0, b0,
    output wire r1, g1, b1
);

    wire [4:0] top_red    = pix_top[23:19];
    wire [4:0] top_green  = pix_top[15:11];
    wire [4:0] top_blue   = pix_top[7:3];
    wire [4:0] bottom_red   = pix_bottom[23:19];
    wire [4:0] bottom_green = pix_bottom[15:11];
    wire [4:0] bottom_blue  = pix_bottom[7:3];

    assign r0 = (top_red > pwm_level);
    assign g0 = (top_green > pwm_level);
    assign b0 = (top_blue > pwm_level);
    assign r1 = (bottom_red > pwm_level);
    assign g1 = (bottom_green > pwm_level);
    assign b1 = (bottom_blue > pwm_level);

endmodule
