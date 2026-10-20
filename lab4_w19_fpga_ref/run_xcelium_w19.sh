#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

mkdir -p work/sim

for RATE in 5 10 15 20; do
    echo "========== W19 ${RATE}% =========="

    xrun -64bit -sv -access +rwc \
        rtl/*.sv \
        sim/clk_wiz_0_sim.sv \
        sim/blk_mem_instruction_mmio_sim.sv \
        sim/tb_fpga_w19_10m.sv \
        -top tb_fpga_w19_10m \
        "+HEX=sw/branch_${RATE}.hex" \
        -l "work/sim/fpga_top_branch_${RATE}.log"
done
