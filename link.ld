OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x80000000;
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
  
  /* Đặt vùng nhớ cho tín hiệu tohost kiểm tra kết quả */
  .tohost : { *(.tohost) }
}
