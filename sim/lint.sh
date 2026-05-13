#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/2] Single-cycle compile check"
iverilog -g2012 -t null \
  tb/tb_rv32i_single_cycle_cpu.sv \
  rtl/rv32i_single_cycle_cpu.v \
  rtl/rv32i_instruction_fetch.v \
  rtl/rv32i_instruction_decode.v \
  rtl/rv32i_register_file.v \
  rtl/rv32i_control_unit.v \
  rtl/rv32i_execute_memory.v

echo "[2/2] Verilator lint: rv32i_single_cycle_cpu"
verilator --lint-only --top-module rv32i_single_cycle_cpu \
  tb/tb_rv32i_single_cycle_cpu.sv \
  rtl/rv32i_single_cycle_cpu.v \
  rtl/rv32i_instruction_fetch.v \
  rtl/rv32i_instruction_decode.v \
  rtl/rv32i_register_file.v \
  rtl/rv32i_control_unit.v \
  rtl/rv32i_execute_memory.v

echo "Lint checks passed."
