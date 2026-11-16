// femtorv32, a minimalistic RISC-V RV32I core
//       Bruno Levy, 2020-2021
//
// This file: memory-mapped constants to query
//   hardware config.

module HardwareConfig(
    input wire clk,
    input wire sel_memory,  // available RAM
    input wire sel_devices, // configured devices
    input wire         sel_cpuinfo, // CPU information
    output wire [31:0] rdata        // read data
);

`include "HardwareConfig_bits.v"

`ifdef NRV_COUNTER_WIDTH
   localparam counter_width = `NRV_COUNTER_WIDTH;
`else
   localparam counter_width = 32;
`endif


// configured devices
localparam NRV_DEVICES = 0
`ifdef NRV_IO_HUB75
   | (1 << IO_HUB75_bit)
`endif
`ifdef NRV_IO_LEDS
   | (1 << IO_LED_bit)
`endif
;

   assign rdata = sel_memory  ? `NRV_RAM  :
     sel_devices ?  NRV_DEVICES :
                  sel_cpuinfo ? (`NRV_FREQ << 16) | counter_width : 32'b0;

endmodule
