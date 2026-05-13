#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/sim/output"

mkdir -p "$OUT_DIR"
cd "$ROOT_DIR"

echo "=================================================="
echo "Running single-cycle CPU regression"

iverilog -g2012 -o "$OUT_DIR/tb_rv32i_single_cycle_cpu.out" \
  tb/tb_rv32i_single_cycle_cpu.sv \
  rtl/rv32i_single_cycle_cpu.v \
  rtl/rv32i_instruction_fetch.v \
  rtl/rv32i_instruction_decode.v \
  rtl/rv32i_register_file.v \
  rtl/rv32i_control_unit.v \
  rtl/rv32i_execute_memory.v

vvp "$OUT_DIR/tb_rv32i_single_cycle_cpu.out"

echo "=================================================="
echo "PASS: single-cycle CPU regression"
