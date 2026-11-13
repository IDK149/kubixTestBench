/*
 * testbench for femtosoc/femtorv32
 *
 * 1. select one of the processors by uncommenting one of the
 *    lines NRV_FEMTORV32_XXX
 *
 * 2. edit FIRMWARE/config.mk and make sure ARCH corresponds to
 *    selected processor.
 *
 * $ cd FIRMWARE/EXAMPLES
 * $ make hello.hex
 * $ cd ../..
 * $ make testbench
 *
 * Uncomment VERBOSE for extensive information (states ...)
 */

`timescale 1ns/1ns

//`include "femtosoc_config.v"
//
//`ifndef BENCH
//`define BENCH
//`endif

`define VERBOSE // Uncomment to have detailed log traces of all states
`include "femtosoc.v"

`ifdef VERILATOR
module femtoRV32_bench(
    input pclk,
    output TXD,
    output r0, g0, b0, r1, g1, b1, clk_out, latch, oe,
    output [4:0] addr
);
`else
module femtoRV32_bench();
   reg pclk;
   wire TXD;
   wire r0, g0, b0, r1, g1, b1, clk_out, latch, oe;
   wire [4:0] addr;
`endif

   femtosoc uut(
      .pclk(pclk),
      .TXD(TXD),
      .RXD(1'b0),
      .RESET(1'b0),
      .r0(r0),
      .g0(g0),
      .b0(b0),
      .r1(r1),
      .g1(g1),
      .b1(b1),
      .clk_out(clk_out),
      .latch(latch),
      .oe(oe),
      .addr(addr)
   );

`ifndef VERILATOR
   initial begin
      pclk = 0;
      forever begin
         #1 pclk = ~pclk;
      end
   end
`endif

endmodule
