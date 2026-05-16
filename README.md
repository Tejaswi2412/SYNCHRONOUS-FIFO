# SYNCHRONOUS-FIFO
Synchronous FIFO buffer in Verilog HDL. 8-slot  8-bit depth with pointer-based control logic,  full/empty flag generation using 4-bit pointers,  overflow/underflow protection, and 5-case  self-checking testbench. Verified using Icarus  Verilog and GTKWave.
# Synchronous FIFO — Verilog Implementation

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-green)
![Status](https://img.shields.io/badge/Status-Verified-brightgreen)
![Depth](https://img.shields.io/badge/Depth-8%20Slots-orange)
![Width](https://img.shields.io/badge/Width-8%20Bits-purple)

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
- [Future Improvements](#future-improvements)
- [Result](#result).

---

## Overview

A FIFO buffer is a fundamental digital design block used to decouple two subsystems operating at different speeds or in different clock domains. Data written first is always read out first — preserving ordering and preventing data loss between producer and consumer.

This implementation follows the standard synchronous FIFO design:

```
Producer                    FIFO                    Consumer
(writes data)  →  [D0][D1][D2][D3][D4][D5][D6][D7]  →  (reads data)
               ↑                                    ↑
           write port                           read port
           (wr_en, data_in)                  (rd_en, data_out)
```

- **full flag** — asserts HIGH when all 8 slots are occupied. Blocks further writes.
- **empty flag** — asserts HIGH when no valid data exists. Blocks further reads.
- **Overflow protection** — write enable gated with `!full` before reaching memory
- **Underflow protection** — read enable gated with `!empty` before reaching memory

---

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │                fifo_top.v                    │
                    │                                              │
    clk    ────────→│──→ fifo_ctrl ──wr_addr[2:0]──→ fifo_mem ───│──→ data_out
    reset  ────────→│         │                  ↑               │
    wr_en  ────────→│         │    rd_addr[2:0]──┘               │
    rd_en  ────────→│         │    wr_en_mem                      │
    data_in────────→│         │    rd_en_mem                      │
                    │         │                                    │
    full   ←────────│←────────┘ (full, empty flags)               │
    empty  ←────────│                                              │
                    └─────────────────────────────────────────────┘
```

**Key design choice:** Control logic and memory are separated into two independent modules. `fifo_ctrl` owns all pointer arithmetic and flag generation. `fifo_mem` is a dumb storage array that only responds to address and enable signals — it has no knowledge of full or empty conditions.

---

## Module Description

### 1. `fifo_mem.v` — Memory Array

Register-based storage array. Handles only read and write operations. No knowledge of FIFO state.

```
Internal storage:
  reg [7:0] mem [0:7]   →   8 slots × 8 bits = 64 bits total
```

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `wr_en` | input | 1 | Write enable (gated, safe signal from fifo_ctrl) |
| `rd_en` | input | 1 | Read enable (gated, safe signal from fifo_ctrl) |
| `wr_addr` | input | 3 | Write address — bottom 3 bits of wr_ptr |
| `rd_addr` | input | 3 | Read address — bottom 3 bits of rd_ptr |
| `data_in` | input | 8 | Data to write into memory |
| `data_out` | output | 8 | Data read from memory |

**Behaviour:**
```
On posedge clk:
  if wr_en → mem[wr_addr] <= data_in
  if rd_en → data_out <= mem[rd_addr]

No else needed:
  memory holds value naturally when not writing
  data_out holds last value naturally when not reading
```

---

### 2. `fifo_ctrl.v` — Control Logic

Pointer management and flag generation. The brain of the FIFO. Uses 4-bit pointers to distinguish full from empty without ambiguity.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Synchronous reset — clears all pointers |
| `wr_en` | input | 1 | Write request from outside world |
| `rd_en` | input | 1 | Read request from outside world |
| `wr_addr` | output | 3 | Bottom 3 bits of wr_ptr → sent to fifo_mem |
| `rd_addr` | output | 3 | Bottom 3 bits of rd_ptr → sent to fifo_mem |
| `wr_en_mem` | output | 1 | Gated write enable → sent to fifo_mem |
| `rd_en_mem` | output | 1 | Gated read enable → sent to fifo_mem |
| `full` | output | 1 | HIGH when FIFO cannot accept more data |
| `empty` | output | 1 | HIGH when FIFO has no valid data |

**Internal registers:**
```
reg [3:0] wr_ptr   →   4-bit write pointer
reg [3:0] rd_ptr   →   4-bit read pointer

Bit [2:0]  →  slot address  (sent to fifo_mem as wr_addr / rd_addr)
Bit [3]    →  lap bit / MSB (used only for full/empty detection)
```

**Flag logic (continuous assign — not clocked):**
```
assign empty     = (wr_ptr == rd_ptr);
assign full      = (wr_ptr[2:0] == rd_ptr[2:0]) && (wr_ptr[3] != rd_ptr[3]);
assign wr_addr   = wr_ptr[2:0];
assign rd_addr   = rd_ptr[2:0];
assign wr_en_mem = wr_en && !full;
assign rd_en_mem = rd_en && !empty;
```

**Pointer update logic (clocked):**
```
On posedge clk:
  if (reset)        → wr_ptr = 0, rd_ptr = 0
  else:
    if (wr_en && !full)   → wr_ptr <= wr_ptr + 1
    if (rd_en && !empty)  → rd_ptr <= rd_ptr + 1
```

---

### 3. `fifo_top.v` — Top Level Integration

Instantiates and connects `fifo_mem` and `fifo_ctrl`. Contains no logic of its own.

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `reset` | input | 1 | Synchronous reset |
| `wr_en` | input | 1 | Write request |
| `rd_en` | input | 1 | Read request |
| `data_in` | input | 8 | Data to write |
| `data_out` | output | 8 | Data being read |
| `full` | output | 1 | Full flag to outside world |
| `empty` | output | 1 | Empty flag to outside world |

**Internal wires:**
```
wire [2:0] wr_addr    →   connects fifo_ctrl output to fifo_mem input
wire [2:0] rd_addr    →   connects fifo_ctrl output to fifo_mem input
wire       wr_en_mem  →   gated write enable: fifo_ctrl → fifo_mem
wire       rd_en_mem  →   gated read enable:  fifo_ctrl → fifo_mem
```

---

### 4. `fifo_tb.v` — Testbench

Five-case testbench covering all critical FIFO scenarios including corner cases.

| Test | Scenario | What is verified |
|------|----------|-----------------|
| Test 1 | Write one byte, read it back | Basic data path and read/write correctness |
| Test 2 | Write 8 bytes back to back | `full` flag asserts after 8th write |
| Test 3 | Read all 8 bytes | `empty` flag asserts after 8th read |
| Test 4 | Write and read same clock cycle | Both operations succeed simultaneously |
| Test 5 | Write 4, read 4, write 4 more | Pointer wrap-around correctness |

**Testbench timing rules:**
```
#10  →  half clock cycle  →  back to back operations, data changes
#20  →  one full cycle    →  single operation, pulse high then low
#30  →  one and half      →  settling time after reset release
#100 →  five full cycles  →  final drain before $finish
```

---

## Design Specifications

| Parameter | Value |
|-----------|-------|
| Clock Frequency | 50 MHz |
| FIFO Depth | 8 slots |
| Data Width | 8 bits |
| Total Storage | 64 bits |
| Pointer Width | 4 bits (3 address + 1 lap bit) |
| Full Condition | `wr_ptr[2:0] == rd_ptr[2:0]` AND `wr_ptr[3] != rd_ptr[3]` |
| Empty Condition | `wr_ptr[3:0] == rd_ptr[3:0]` |
| Reset Type | Synchronous |
| HDL Standard | Verilog |

---

## Key Design Decisions

### Separated Memory and Control

Memory (`fifo_mem`) and control logic (`fifo_ctrl`) are intentionally kept in separate modules. This mirrors how real SRAMs are separated from their controllers in SoC design. `fifo_mem` is a dumb storage array — it follows orders without questioning state. `fifo_ctrl` is the intelligent manager that decides when those orders should be issued.

### 4-Bit Pointer for Full/Empty Disambiguation

A FIFO of depth 8 requires only 3-bit addresses. However, when both pointers reach the same slot, it is impossible to distinguish full from empty using address bits alone.

The solution: extend each pointer to 4 bits. The MSB (bit 3) acts as a lap indicator.

```
EMPTY:  wr_ptr = 0000,  rd_ptr = 0000  →  all 4 bits equal
FULL:   wr_ptr = 1000,  rd_ptr = 0000  →  lower 3 bits equal, MSB differs

Cost: 2 extra flip flops only. Memory array unchanged.
```

This cleanly resolves the ambiguity with minimal overhead.

### Continuous Assign for Flags

Full, empty, wr_addr, rd_addr, wr_en_mem, and rd_en_mem are all driven by `assign` statements outside the `always` block. This ensures they update instantly whenever pointer values change — no clock edge dependency, no one-cycle delay.

If placed inside the `always @(posedge clk)` block, these signals would update one cycle late due to non-blocking assignment scheduling, causing the `if (wr_en && !full)` condition to read stale flag values.

### Gated Write and Read Enable

Raw `wr_en` and `rd_en` from the outside world are never sent directly to `fifo_mem`. Instead, `fifo_ctrl` gates them:

```
wr_en_mem = wr_en && !full
rd_en_mem = rd_en && !empty
```

`fifo_mem` is a dumb storage block — it will write or read blindly if given an enable signal. Gating ensures overflow and underflow are impossible at the hardware level, not just at the software level.

### Non-Blocking Assignments

All sequential logic inside `always @(posedge clk)` uses `<=` (non-blocking assignments), correctly modelling flip-flop behaviour and preventing race conditions between pointer updates.

### Reset Checked First

Inside the `always` block, `reset` is checked before all other conditions using an `if-else` structure. This guarantees that when reset is asserted, pointer clearing takes priority over any simultaneous write or read requests.

---

## Simulation Results

**Five test cases — all passed:**

```
Test 1 — Write / Read
  Written  : 8'b10100011 (0xA3)
  Read out : 8'b10100011 (0xA3)  ✅ MATCH

Test 2 — Fill completely
  After 8 writes: full = 1       ✅ ASSERTED correctly

Test 3 — Drain completely
  After 8 reads:  empty = 1      ✅ ASSERTED correctly

Test 4 — Simultaneous read + write
  wr_en = 1 and rd_en = 1 same cycle
  Both operations succeeded       ✅ FIFO depth unchanged

Test 5 — Wrap around
  Write 4 → Read 4 → Write 4 more → Read 4 more
  All data read back correctly    ✅ POINTER WRAP VERIFIED
```

**GTKWave waveforms confirm:**
- Clock toggling continuously at 50MHz
- Reset asserting at t=0, releasing at t=20ns
- `wr_en` pulsing correctly for each write group
- `rd_en` pulsing correctly for each read
- `data_out` matching `data_in` with one clock cycle delay
- `full` asserting after 8th write in Test 2
- `empty` asserting after 8th read in Test 3
- Pointer wrap-around completing without data loss in Test 5

---

## How to Run

### Prerequisites
- [Icarus Verilog](http://iverilog.icarus.com/) — HDL simulator
- [GTKWave](http://gtkwave.sourceforge.net/) — Waveform viewer

### Compile
```bash
iverilog -o fifo_tb fifo_tb.v fifo_top.v fifo_ctrl.v fifo_mem.v
```

### Simulate
```bash
vvp fifo_tb
```

### View Waveforms
```bash
gtkwave fifo_tb.vcd
```

### Expected Output
```
VCD info: dumpfile fifo_tb.vcd opened for output.
t=0    wr_en=0 rd_en=0 data_in=xxxxxxxx data_out=xxxxxxxx full=0 empty=1
t=50   wr_en=1 rd_en=0 data_in=10100011 data_out=xxxxxxxx full=0 empty=0
t=70   wr_en=0 rd_en=0 data_in=10100011 data_out=10100011 full=0 empty=0
...
$finish called at time
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
|------|---------|---------|
| Icarus Verilog | 12.0 | HDL compilation and simulation |
| GTKWave | 3.3.108 | Waveform visualization |
| VS Code | Latest | Code editor |

---

## Future Improvements

- [ ] Parameterize depth and width (`parameter DEPTH=8, WIDTH=8`)
- [ ] Add `almost_full` and `almost_empty` flags for flow control
- [ ] Implement asynchronous FIFO with Gray code pointers for CDC
- [ ] Add FIFO occupancy counter output
- [ ] Integrate as TX buffer between data source and UART transmitter
- [ ] Add reset to `fifo_mem` to clear stale data on reset
- [ ] Synthesize and test on Basys3/Nexys4 FPGA board
- [ ] Upgrade testbench to SystemVerilog with assertions and coverage

---

## Result 

<img width="1920" height="1080" alt="FIFO RESULT" src="https://github.com/user-attachments/assets/c8884ecd-fc71-42c2-a887-ca078c7dd116" />


## Author

**Tejaswi**
ECE Student | Hardware Design Enthusiast
Building skills in VLSI, FPGA, and SoC design

---

*Built from scratch as a learning project — every module written, debugged, and verified independently.*
