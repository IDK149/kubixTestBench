// This is a good example on how to connect to the CPU.
module leds (
    input clk,
    input rstrb,
    input wstrb,
    input sel,
    input [31:0] wdata,
    output [31:0] rdata,
    output wire LED
);
  reg led_state = 1'b0;
  assign LED   = led_state;
  assign rdata = (sel ? {31'b0, led_state} : 32'b0);

  always @(posedge clk) begin
    if (sel && wstrb) begin
      led_state <= wdata[0];
    end
  end
endmodule
