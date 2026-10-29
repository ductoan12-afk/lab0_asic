# D1 Directed Assembly Tests

Target: RV32I
Toolchain: riscv64-unknown-elf-gcc
Compile options: -march=rv32i -mabi=ilp32
Link address: 0x0
Entry symbol: _start

## Test files

- d1_alu_edges.S / .hex: ALU edge cases, signed/unsigned operations, shifts, x0.
- d1_branch_edges.S / .hex: conditional branches, JAL and JALR.
- d1_memory_edges.S / .hex: loads, stores, sign extension and byte lanes.
- d1_hazard_x0.S / .hex: data dependencies, load-use, forwarding and x0.

Results are not yet verified on CPU A, CPU B and CPU C.
The HEX files were checked for 32-bit word formatting.
