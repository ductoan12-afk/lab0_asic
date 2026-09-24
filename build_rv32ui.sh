#!/bin/bash
set -e

ISA_DIR="$HOME/lab0_asic/riscv-tests/isa"
OUT_DIR="$HOME/lab0_asic/sw/rv32ui"
GCC="riscv64-unknown-elf-gcc"
OBJCOPY="riscv64-unknown-elf-objcopy"

mkdir -p "$OUT_DIR"

CFLAGS="-march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles"
INCLUDES="-I$ISA_DIR/../env/p -I$ISA_DIR/macros/scalar"
LINKER="-T$ISA_DIR/../env/p/link.ld"

tests=(
simple
add addi
and andi
auipc
beq bge bgeu blt bltu bne
fence_i
jal jalr
lb lbu lh lhu lw ld_st
lui
ma_data
or ori
sb sh sw st_ld
sll slli
slt slti sltiu sltu
sra srai
srl srli
sub
xor xori
)

for test in "${tests[@]}"; do
    echo "=== BUILD rv32ui-p-$test ==="

    "$GCC" $CFLAGS $INCLUDES $LINKER \
        "$ISA_DIR/rv32ui/$test.S" \
        -o "$OUT_DIR/rv32ui-p-$test"

    "$OBJCOPY" -O verilog "$OUT_DIR/rv32ui-p-$test" \
        "$OUT_DIR/rv32ui-p-$test.hex"

    echo "OK: rv32ui-p-$test"
done

echo
echo "===== DONE ====="
ls -lh "$OUT_DIR"/rv32ui-p-*.hex
