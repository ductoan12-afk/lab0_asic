#!/bin/bash
# Lặp qua các file assembly (.S) trong thư mục sw hoặc hiện tại
for file in *.S; do
    if [ -f "$file" ]; then
        name=$(basename "$file" .S)
        echo "Dang bien dich: $name"
        riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Tlink.ld "$file" -o "${name}.elf"
        riscv64-unknown-elf-objcopy -O verilog "${name}.elf" "${name}.hex"
    fi
done
echo "Bien dich hoan tat!"
