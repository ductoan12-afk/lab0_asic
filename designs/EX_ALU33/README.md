# EX_ALU33

Pipelined RV32I processor using a unified 33-bit ALU architecture in the EX stage.

## Verification status

- RV32UI official tests: 38/38 PASS
- Functional coverage: 22/22 bins (100%)
- Assertion verification: PASS
- Random 10M-instruction verification: supported

## Structure

- `rtl/` — RTL source
- `tb/` — testbenches
- `sw/` — test programs and HEX images
- `run/` — verification scripts
