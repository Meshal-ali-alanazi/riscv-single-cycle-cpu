# Repository Connection

This repository contains the CPU-side RTL for a RISC-V edge-AI project.

The companion AI repository is:

```text
https://github.com/riscv-edge-ai/catdog-riscv-edge-ai
```

## CPU Repository

This repository provides:

- Custom RV32I single-cycle CPU RTL
- Instruction fetch, decode, register file, control, execute, and memory logic
- Self-checking SystemVerilog CPU testbench
- Simulation scripts for CPU verification

The CPU is currently a standalone educational RV32I core. It is not yet a
complete SoC.

## AI Repository

The AI repository provides:

- Cat/dog image-classification model
- Quantized firmware for a RISC-V target
- Renode platform model
- Memory-mapped accelerator model
- Benchmark and export scripts
- Evaluation results

## Interface Between Repositories

The long-term connection point is a memory-mapped RISC-V SoC.

The CPU side supplies the processor that executes firmware instructions.
The AI side supplies firmware and accelerator-facing software that expects
memory-mapped peripherals.

The AI firmware uses this platform-style memory map:

```text
0x00000000  instruction memory
0x00040000  data memory
0x000C0000  AI accelerator registers
0x000E0000  UART
0x00100000  SRAM / image data
0x02000000  timer / cycle counter
```

The accelerator register window begins at:

```text
ACCEL_BASE = 0x000C0000
```

## Current Compatibility Status

The repositories are connected at the project architecture level, but this CPU
RTL is not yet a drop-in hardware replacement for the AI repository's Renode
CPU platform.

Current CPU repository status:

```text
RV32I CPU core: implemented
CPU testbench: implemented
CPU regression: passing
Memory-mapped SoC wrapper: not yet implemented
UART peripheral: not yet implemented
timer / CLINT block: not yet implemented
AI accelerator hardware connection: not yet implemented
RV32M multiply/divide extension: not yet implemented
```

## Planned Integration Path

To run the AI firmware directly on this CPU RTL, the CPU repository needs these
hardware additions:

1. Expose load/store memory bus signals from the CPU.
2. Add an address decoder for memory and peripherals.
3. Add instruction/data/SRAM memory regions matching the AI firmware map.
4. Add a UART peripheral at `0x000E0000`.
5. Add a timer or cycle counter at `0x02000000`.
6. Connect an AI accelerator register window at `0x000C0000`.
7. Either add RV32M support or compile the firmware for RV32I-only execution.

After those steps, the CPU RTL can become the hardware CPU side of the same
system currently modeled in Renode by the AI repository.
