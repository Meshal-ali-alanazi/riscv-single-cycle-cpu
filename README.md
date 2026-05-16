# RISC-V Single-Cycle CPU

## Portfolio Summary

Designed and verified a custom single-cycle RV32I CPU in Verilog with a
self-checking SystemVerilog testbench covering ALU, branch, jump, load, and
store instructions. Prepared the CPU as a companion hardware repository for a
RISC-V edge-AI firmware/Renode project, with a documented SoC integration path.

This repository contains the CPU-side hardware for a small RISC-V edge-AI
project. It is intended as the companion CPU repository for the AI/firmware
repository:

```text
https://github.com/riscv-edge-ai/catdog-riscv-edge-ai
```

The AI repository contains the model training, quantized firmware, Renode
platform, benchmark scripts, and results. This repository contains the Verilog
CPU core used as the hardware-learning side of the project.

## My Contribution

This repository is part of a collaborative computer engineering project.

My main contributions include:

- RV32I single-cycle CPU design and documentation
- Verilog/SystemVerilog testbench review and project cleanup
- ALU, branch, jump, load, and store instruction verification
- Simulation scripts and portfolio-focused technical presentation

## What Is Included

- `rtl/rv32i_single_cycle_cpu.v` top-level CPU wrapper
- `rtl/rv32i_instruction_fetch.v` program counter and instruction memory
- `rtl/rv32i_instruction_decode.v` field extraction and immediate generation
- `rtl/rv32i_register_file.v` 32-register integer register file
- `rtl/rv32i_control_unit.v` RV32I control decode
- `rtl/rv32i_execute_memory.v` ALU, branch, jump, load/store, and data memory
- `tb/tb_rv32i_single_cycle_cpu.sv` self-checking SystemVerilog testbench
- `sim/` scripts for compiling and running the CPU regression
- `REPOSITORY_CONNECTION.md` relationship between this CPU repository and the
  companion AI repository

## CPU Type

This CPU is a custom educational core:

```text
ISA: RV32I
Datapath: single-cycle style
Pipeline: no
RV32M multiply/divide: no
PicoRV32: no
```

The paper/AI-side platform uses an RV32IM-style RISC-V target in Renode. This
CPU repository is a simpler CPU-side hardware implementation, not a drop-in
PicoRV32 replacement yet.

## Supported Instruction Groups

The current testbench covers these RV32I groups:

- R-type ALU: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`,
  `AND`
- I-type ALU: `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`,
  `ANDI`
- Upper immediate: `LUI`, `AUIPC`
- Branches: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- Jumps: `JAL`, `JALR`
- Loads: `LB`, `LH`, `LW`, `LBU`, `LHU`
- Stores: `SB`, `SH`, `SW`

## Requirements

- Icarus Verilog, available as `iverilog` and `vvp`
- Verilator, only needed for `sim/lint.sh`
- Bash

## Run The CPU Test

From the repository root:

```bash
./sim/run_all.sh
```

Expected result:

```text
Single-cycle summary
Total checks: 20
Passed: 20
Failed: 0
PASS: single-cycle CPU regression
```

Run the dedicated testbench directly:

```bash
./sim/run_rv32i_single_cycle_cpu.sh
```

Run compile/lint checks:

```bash
./sim/lint.sh
```

## Repository Notes

Generated simulation outputs are written to `sim/output/` and ignored by Git.
The source files, testbench, scripts, and documentation are the files intended
for upload.
