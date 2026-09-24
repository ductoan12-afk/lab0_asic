OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY {
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}
SECTIONS {
    .text : { *(.text*) } > RAM
    .data : { *(.data*) *(.rodata*) } > RAM
    .bss : { *(.bss*) *(COMMON) } > RAM
}
