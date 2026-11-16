module hub75 #(
    parameter COLOR_BITS = 4
) (
    input wire clk,
    input wire rst,

    // CPU
    input wire sel_hub75,
    input wire wstrb,
    input wire [31:0] wdata,

    output wire r0,
    g0,
    b0,
    output wire r1,
    g1,
    b1,
    output wire [4:0] addr,
    output wire clk_out,
    output wire latch,
    output wire oe
);


  wire wr_en = sel_hub75 && wstrb; // Selection hub75
  wire [1:0] wr_sel = wdata[31:30]; // Layer Selection 0 = GB, 1 SPRITE, 2 TEXT
  wire [11:0] wr_addr = {wdata[29:18]}; // {x, y}
  wire [(3*COLOR_BITS)-1:0] wr_data = wdata[(3*COLOR_BITS)-1:0]; // Color

  wire [5:0] col;
  wire [4:0] scan_row;
  wire [4:0] display_row;
  wire [5:0] row_top;
  wire [5:0] row_bottom;
  wire [4:0] pwm_level;
  assign addr = display_row;

  scan_counter SC (
      .clk(clk),
      .rst(rst),
      .col(col),
      .scan_row(scan_row),
      .addr_out(display_row),
      .pwm_level(pwm_level),
      .row_top(row_top),
      .row_bottom(row_bottom)
  );

  wire [5:0] col_rd = col - 6'd1;
  wire [11:0] addr_top = {row_top, col_rd};
  wire [11:0] addr_bottom = {row_bottom, col_rd};

  wire [(3*COLOR_BITS)-1:0] pix_top;
  wire [(3*COLOR_BITS)-1:0] pix_bottom;

  panel_memory #(
      .COLOR_BITS(COLOR_BITS)
  ) MEM (
      .clk(clk),
      .addr_top(addr_top),
      .addr_bottom(addr_bottom),
      .pix_top(pix_top),
      .pix_bottom(pix_bottom),

      .wr_clk (clk),
      .wr_en  (wr_en),
      .wr_sel (wr_sel),
      .wr_addr(wr_addr),
      .wr_data(wr_data)
  );

`ifdef PWM
  panel_pwm PWM (
      .pix_top(pix_top),
      .pix_bottom(pix_bottom),
      .pwm_level(pwm_level),
      .r0(r0),
      .g0(g0),
      .b0(b0),
      .r1(r1),
      .g1(g1),
      .b1(b1)
  );
`else
  assign r0 = pix_top[3*COLOR_BITS-1];
  assign g0 = pix_top[2*COLOR_BITS-1];
  assign b0 = pix_top[COLOR_BITS-1];
  assign r1 = pix_bottom[3*COLOR_BITS-1];
  assign g1 = pix_bottom[2*COLOR_BITS-1];
  assign b1 = pix_bottom[COLOR_BITS-1];
`endif

  delay_unit DU (
      .clk(clk),
      .rst(rst),
      .col(col),
      .clk_out(clk_out),
      .latch(latch),
      .oe(oe)
  );

endmodule

