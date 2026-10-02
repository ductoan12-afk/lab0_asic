.section .text
.globl _start

# Macro kiểm tra giá trị thanh ghi với kỳ vọng và mã ID của test
.macro CHECK reg, expected, id
    li   t5, \expected
    li   t6, \id
    bne  \reg, t5, fail
.endm

_start:
    # ---- Test 1: ADDI ----
    li   x1, 0
    addi x1, x1, 100
    CHECK x1, 100, 1

    # ---- Test 2: ADD / SUB ----
    li   x2, 30
    add  x3, x1, x2
    CHECK x3, 130, 2
    sub  x4, x1, x2
    CHECK x4, 70, 3

    # ---- Test 3: Dịch bit (Shift) ----
    li   x5, 1
    slli x6, x5, 31
    CHECK x6, 0x80000000, 4
    srli x7, x6, 31
    CHECK x7, 1, 5

    # ---- Test 4: Phép toán Logic (AND, OR, XOR) ----
    li   x8, 0x0F0F0F0F
    li   x9, 0x33333333
    and  x10, x8, x9
    CHECK x10, 0x03030303, 6
    or   x11, x8, x9
    CHECK x11, 0x3F3F3F3F, 7
    xor  x12, x8, x9
    CHECK x12, 0x3C3C3C3C, 8

    # ---- Kết thúc: Nếu chạy qua hết không lỗi -> Ghi mã PASS (1) vào ToHost ----
    li   t0, 0x00001000
    li   t1, 1
    sw   t1, 0(t0)
    j    end_program

fail:
    # ---- Xử lý khi lỗi: Ghi mã lỗi vào ToHost ----
    li   t0, 0x00001000
    slli t2, t6, 1
    sw   t2, 0(t0)

end_program:
    j end_program

