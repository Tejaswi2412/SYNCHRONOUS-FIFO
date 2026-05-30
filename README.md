# Synchronous FIFO — Verilog Implementation

[![Language](https://img.shields.io/badge/Language-Verilog-blue)](https://img.shields.io/badge/Language-Verilog-blue) [![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-green)](https://img.shields.io/badge/Simulator-Icarus%20Verilog-green) [![Status](https://img.shields.io/badge/Status-Verified-brightgreen)](https://img.shields.io/badge/Status-Verified-brightgreen) [![Depth](https://img.shields.io/badge/Depth-8%20Slots-orange)](https://img.shields.io/badge/Depth-8%20Slots-orange) [![Width](https://img.shields.io/badge/Width-8%20Bits-purple)](https://img.shields.io/badge/Width-8%20Bits-purple)

A fully functional **Synchronous FIFO (First In First Out)** buffer implemented in Verilog HDL. The design includes a register-based memory array, FSM-free pointer-based control logic with full/empty flag generation, top-level integration module, and a five-case self-checking testbench. Verified using Icarus Verilog simulator with waveform analysis in GTKWave.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Module Description](#module-description)
- [Design Specifications](#design-specifications)
- [Key Design Decisions](#key-design-decisions)
- [Simulation Results](#simulation-results)
- [How to Run](#how-to-run)
- [Directory Structure](#directory-structure)
- [Tools Used](#tools-used)
- [Synthesis Results](#synthesis-results)
- [Future Improvements](#future-improvements)
- [Result](#result)

---

## Overview

A FIFO buffer is a fundamental digital design block used to decouple two subsystems operating at different speeds or in different clock domains. Data written first is always read out first — preserving ordering and preventing data loss between producer and consumer.

```
Producer                    FIFO                    Consumer
(writes data)  →  [D0][D1][D2][D3][D4][D5][D6][D7]  →  (reads data)
               ↑                                    ↑
           write port                           read port
           (wr_en, data_in)                  (rd_en, data_out)
```

- **full flag** — asserts HIGH when all 8 slots are occupied
- **empty flag** — asserts HIGH when no valid data exists
- **Overflow protection** — write enable gated with `!full`
- **Underflow protection** — read enable gated with `!empty`

---

## Architecture

```
                ┌─────────────────────────────────────────────┐
                │                fifo_top.v                   │
                │                                             │
clk    ────────→│──→ fifo_ctrl ──wr_addr[2:0]──→ fifo_mem ───│──→ data_out
reset  ────────→│         │                  ↑               │
wr_en  ────────→│         │    rd_addr[2:0]──┘               │
rd_en  ────────→│         │    wr_en_mem                     │
data_in────────→│         │    rd_en_mem                     │
                │         │                                  │
full   ←────────│←────────┘ (full, empty flags)              │
empty  ←────────│                                            │
                └─────────────────────────────────────────────┘
```

---

## Module Description

### 1. `fifo_mem.v` — Memory Array

Register-based storage: `reg [7:0] mem [0:7]` — 8 slots × 8 bits = 64 bits total.

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | input | 1 | System clock |
| `wr_en` | input | 1 | Write enable (gated) |
| `rd_en` | input | 1 | Read enable (gated) |
| `wr_addr` | input | 3 | Write address |
| `rd_addr` | input | 3 | Read address |
| `data_in` | input | 8 | Data to write |
| `data_out` | output | 8 | Data read out |

---

### 2. `fifo_ctrl.v` — Control Logic

4-bit pointer-based control. Brain of the FIFO.

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Synchronous reset |
| `wr_en` | input | 1 | Write request |
| `rd_en` | input | 1 | Read request |
| `full` | output | 1 | FIFO full flag |
| `empty` | output | 1 | FIFO empty flag |

**Flag logic:**
```
assign empty     = (wr_ptr == rd_ptr);
assign full      = (wr_ptr[2:0] == rd_ptr[2:0]) && (wr_ptr[3] != rd_ptr[3]);
assign wr_en_mem = wr_en && !full;
assign rd_en_mem = rd_en && !empty;
```

---

### 3. `fifo_top.v` — Top Level Integration

Instantiates and connects `fifo_mem` and `fifo_ctrl`. Contains no logic of its own.

---

### 4. `fifo_tb.v` — Testbench (5 test cases)

| Test | Scenario | What is verified |
| --- | --- | --- |
| Test 1 | Write one byte, read it back | Basic data path correctness |
| Test 2 | Write 8 bytes back to back | `full` flag asserts after 8th write |
| Test 3 | Read all 8 bytes | `empty` flag asserts after 8th read |
| Test 4 | Write and read same cycle | Both operations succeed simultaneously |
| Test 5 | Write 4, read 4, write 4 more | Pointer wrap-around correctness |

---

## Design Specifications

| Parameter | Value |
| --- | --- |
| Clock Frequency | 50 MHz |
| FIFO Depth | 8 slots |
| Data Width | 8 bits |
| Pointer Width | 4 bits (3 address + 1 lap bit) |
| Full Condition | `wr_ptr[2:0] == rd_ptr[2:0]` AND `wr_ptr[3] != rd_ptr[3]` |
| Empty Condition | `wr_ptr[3:0] == rd_ptr[3:0]` |
| Reset Type | Synchronous |
| HDL Standard | Verilog |

---

## Key Design Decisions

### Separated Memory and Control
Memory and control logic are intentionally kept in separate modules, mirroring real SoC design where SRAMs are separated from controllers.

### 4-Bit Pointer for Full/Empty Disambiguation
```
EMPTY:  wr_ptr = 0000,  rd_ptr = 0000  →  all 4 bits equal
FULL:   wr_ptr = 1000,  rd_ptr = 0000  →  lower 3 bits equal, MSB differs
```

### Continuous Assign for Flags
Flags use `assign` statements outside `always` block — update instantly without clock edge dependency.

### Gated Write and Read Enable
Raw enables are never sent directly to memory. Always gated: `wr_en_mem = wr_en && !full`.

---

## Simulation Results

```
Test 1 — Write / Read
  Written  : 8'b10100011 (0xA3)
  Read out : 8'b10100011 (0xA3)  ✅ MATCH

Test 2 — Fill completely
  After 8 writes: full = 1       ✅ ASSERTED correctly

Test 3 — Drain completely
  After 8 reads:  empty = 1      ✅ ASSERTED correctly

Test 4 — Simultaneous read + write
  Both operations succeeded       ✅ FIFO depth unchanged

Test 5 — Wrap around
  All data read back correctly    ✅ POINTER WRAP VERIFIED
```

---

## How to Run

### Compile
```
iverilog -o fifo_tb fifo_tb.v fifo_top.v fifo_ctrl.v fifo_mem.v
```

### Simulate
```
vvp fifo_tb
```

### View Waveforms
```
gtkwave fifo_tb.vcd
```

---

## Directory Structure

```
fifo_project/
├── fifo_mem.v     # Register-based memory array (8x8 bits)
├── fifo_ctrl.v    # Pointer logic, full/empty flag generation
├── fifo_top.v     # Top-level integration module
├── fifo_tb.v      # Five-case self-checking testbench
└── README.md      # This file
```

---

## Tools Used

| Tool | Version | Purpose |
| --- | --- | --- |
| Icarus Verilog | 12.0 | HDL compilation and simulation |
| GTKWave | 3.3.108 | Waveform visualization |
| VS Code | Latest | Code editor |

---

## Synthesis Results

**Target Device:** Xilinx Artix-7 `xc7a35tcpg236-1` | **Tool:** Vivado 2025.1

| Resource | Used | Available | Utilization |
| --- | --- | --- | --- |
| Slice LUTs | 16 | 20800 | <1% |
| Slice Registers (FFs) | 16 | 41600 | <1% |
| Bonded IOB | 22 | 106 | <1% |
| BUFGCTRL | 1 | 32 | <1% |

**Timing Summary**
- Failing Endpoints: **0**
- Total Negative Slack (TNS): 0.000 ns
- Worst Negative Slack (WNS): inf

### Schematic
<img width="1920" height="1015" alt="fifo_schematic" src="https://github.com/user-attachments/assets/90fe9dad-51c7-4852-aaae-d3ba023250d3" />


### Utilization Report
<img width="1920" height="1017" alt="fifo_utilization" src="https://github.com/user-attachments/assets/efdd103a-64ae-4b0b-a2a1-0bd7f7e2c15d" />


### Timing Report
<img width="1920" height="1022" alt="fifo_timing" src="https://github.com/user-attachments/assets/88a13c34-52b3-4481-89e9-cab7c4c6565a" />


---

## Future Improvements

- [ ] Parameterize depth and width (`parameter DEPTH=8, WIDTH=8`)
- [ ] Add `almost_full` and `almost_empty` flags for flow control
- [ ] Implement asynchronous FIFO with Gray code pointers for CDC
- [ ] Add FIFO occupancy counter output
- [ ] Integrate as TX buffer between data source and UART transmitter
- [ ] Synthesize and test on Basys3/Nexys4 FPGA board
- [ ] Upgrade testbench to SystemVerilog with assertions and coverage

---

## Result

![FIFO RESULT](FIFO%20RESULT.png)

---

## Author

**Tejaswi** ECE Student | Hardware Design Enthusiast  
Building skills in VLSI, FPGA, and SoC design

---

*Built from scratch as a learning project — every module written, debugged, and verified independently.*
