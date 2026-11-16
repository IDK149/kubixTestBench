// ColorLight 5A-75B / ECP5-25K board configuration.
// The board's 25 MHz oscillator is passed directly to the SoC clock.

`define NRV_IO_HUB75
`define NRV_IO_LED

`define NRV_FREQ 25
`define NRV_RAM 65536
`define NRV_RESET_ADDR 0
`define NRV_NEGATIVE_RESET
`define NRV_FEMTORV32_QUARK
`define NRV_IO_HARDWARE_CONFIG
`define NRV_CONFIGURED
`define PASSTHROUGH_PLL

