# FemtoRV Generic FPGA Simulation & Hardware Targets

This repository provides a framework for simulating and running a hardware design based on the **FemtoRV** processor targeted for generic FPGAs and specific boards. Using **Verilator**, the design translates Verilog HDL into C++ code to run high-performance cycle-accurate simulations that model real-world hardware as closely as possible.

---

## Dependencies & Prerequisites

To build and run the hardware simulation, you will need a set of open-source EDA tools (specifically `verilator`, `make`, and C++ compilers).

### Recommended Toolchain: oss-cad-suite
The easiest way to set up the complete toolchain environment is by using the **[oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build)**.

1. Download the latest release for your OS from the [oss-cad-suite releases page](https://github.com/YosysHQ/oss-cad-suite-build/releases).
2. Extract the archive to your preferred directory.
3. Activate the environment in your terminal session before building:

```bash
# On Linux/macOS
source /path/to/oss-cad-suite/environment

# On Windows (PowerShell)
\path\to\oss-cad-suite\environment.ps1
```

---

## How to Run the Simulation & Targets
Follow these steps to compile the firmware and launch either the standard simulation or the Colorlight target.

### Step 1: Compile the Firmware

Before starting the simulation or targeting hardware, you must generate a `.hex` firmware binary file that the processor will load into memory.

1. Configure the firmware build depending on your chosen target:

   * **Option A: Generic Simulation (Default)**
     ```bash
     make BENCH.firmware_config
     ```

   * **Option B: Colorlight Target (Optional)**
     ```bash
     make COLORLIGHT.firmware_config

2. Navigate to the firmware PROGRAMS directory:
   ```bash
   cd firmware/PROGRAMS
   ```

3. Build the main target to output a `.hex` file under firmware:
   ```bash
   make main.hex
   ```

### Step 2: Build and Launch

Return to the root directory of the repository and execute the corresponding `make` command to compile and run:

* **For Generic Simulation:**
  ```bash
  # Return to repository root
  cd ../..

  # Build and run everything
  make BENCH
  ```

* **For Colorlight Target:**
  ```bash
  # Return to repository root
  cd ../..

  # Build and run for Colorlight
  make COLORLIGHT
  ```
---

> [!NOTE]
> **Project Status:** This project is currently a work in progress (WIP). 
