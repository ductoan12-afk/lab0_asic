# RV32I ALU Architecture Study

Repository for RTL implementations and verification of a pipelined RV32I processor with different ALU organizations.

## Designs

- `designs/EX_ALU33/` — unified 33-bit ALU in the EX stage
- `designs/EX_ALU_Traditional/` — traditional EX-stage ALU
- `designs/ID_ALU33/` — 33-bit ALU architecture evaluated in the ID stage

## Verification

The designs are verified with RISC-V instruction tests, assertions, functional coverage, and long random-instruction simulations.

## Repository structure

- `designs/` — processor implementations
- `common/` — shared scripts and documentation
- `verification/` — shared verification infrastructure
- `pdk/` — technology files
- `riscv-tests/` — RISC-V test suite
- `riscv-test-env/` — RISC-V test environment
