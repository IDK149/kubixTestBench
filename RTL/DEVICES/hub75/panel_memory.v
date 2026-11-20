module panel_memory #(
    parameter COLOR_BITS = 4
) (
    input  wire        clk,
    input  wire [11:0] addr_top,
    input  wire [11:0] addr_bottom,

    output reg  [(3*COLOR_BITS)-1:0] pix_top,
    output reg  [(3*COLOR_BITS)-1:0] pix_bottom,

    // CPU connection
    input wire wr_clk,
    input wire wr_en,
    input wire [1:0] wr_sel,
    input wire [11:0] wr_addr,
    input wire [(3*COLOR_BITS)-1:0] wr_data
);

  reg [(3*COLOR_BITS)-1:0] BACKGROUND_MEM    [4095];
  reg [(3*COLOR_BITS)-1:0] SPRITE_MEM        [4095];

  reg [(3*COLOR_BITS)-1:0] background_top, background_bottom;
  reg [(3*COLOR_BITS)-1:0] sprite_top, sprite_bottom;

  // Preload the background image into FPGA memory during bitstream synthesis.
  // The file should contain 4096 RGB444 words, in row-major (y * 64 + x) order.
  initial begin
    $readmemh("RTL/DEVICES/hub75/background.hex", SPRITE_MEM);
  end

  always @(posedge clk) begin
    if (wr_en) begin
      case (wr_sel)
        2'b00:   BACKGROUND_MEM[wr_addr] <= wr_data;
        2'b01:   SPRITE_MEM[wr_addr] <= wr_data;
        default: ;
      endcase
    end
  end

  always @(posedge clk) begin
    background_top    <= BACKGROUND_MEM[addr_top];
    background_bottom <= BACKGROUND_MEM[addr_bottom];
    sprite_top        <= SPRITE_MEM[addr_top];
    sprite_bottom     <= SPRITE_MEM[addr_bottom];
  end

  // Priority conditions
  always @* begin
    pix_top    = (sprite_top    != {(3*COLOR_BITS){1'b0}}) ? sprite_top    : background_top;
    pix_bottom = (sprite_bottom != {(3*COLOR_BITS){1'b0}}) ? sprite_bottom : background_bottom;
  end
endmodule

