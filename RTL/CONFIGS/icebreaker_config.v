// Default femtosoc configuration file for IceStick

`define NRV_NEGATIVE_RESET
/************************* Devices **********************************************************************************/

`define NRV_IO_HUB75
`define NRV_IO_LED

/************************* Processor configuration ******************************************************************/

`define NRV_FEMTORV32_QUARK // RV32I 
// `define NRV_FEMTORV32_ELECTRON      // RV32IM
//`define NRV_FEMTORV32_INTERMISSUM   // RV32IM  + IRQ
//`define NRV_FEMTORV32_GRACILIS      // RV32IMC + IRQ
//`define NRV_FEMTORV32_PETITBATEAU     // RV32IMFC + IRQ, does not fit on IceBreaker

`define NRV_FREQ 20                 // Frequency in MHz. Recomm: 15 MHz   Overclocking: 20-25 MHz
// `define NRV_RESET_ADDR 32'h00820000 // Jump execution to SPI Flash (800000h, +128k(20000h) for FPGA bitstream)
// tinyraytracer: 30 MHz RV32IM  electron 3:12
//                20 MHz RV32IM  gracilis 3:44
//                20 MHz RV32IMC gracilis 3:32
//                25 MHz RV32IMC gracilis 2:49

/************************* RAM (in bytes, needs to be a multiple of 4)***********************************************/

// Using the 128 kbytes of single-ported RAM of the ice40-up5k
// Note: cannot initialize it from .hex file, need to run from SPI Flash

`define ICE40UP5K_SPRAM
// `define NRV_RAM 131072 

// (other option, the 12 kbytes of BRAM, this one can be initialized from .hex file).
`define NRV_RAM 12288

/************************* Advanced devices configuration *********************************************************/

// `define NRV_RUN_FROM_SPI_FLASH // Do not 'readmemh()' firmware from '.hex' file
`define NRV_IO_HARDWARE_CONFIG // Comment-out to disable hardware config registers mapped in IO-Space
                               // (only if you use your own firmware, libfemtorv32 depends on it)

/******************************************************************************************************************/

`define NRV_CONFIGURED
