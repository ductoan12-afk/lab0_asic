.option norvc
.section .text
.globl _start
.type _start, @function

# CHECK: nhay den fail neu gia tri khong dung.
# t6 luu ma cua truong hop bi loi.
.macro CHECK reg, expected, id
    li   t5, \expected
    li   t6, \id
    bne  \reg, t5, fail
.endm

_start:
    # 1. x0 luon phai bang 0
    addi x0, x0, 1
    CHECK x0, 0, 1

    # 2. ADDI: ket qua vuot qua bien so co dau 32 bit
    li   t0, 0x7fffffff
    addi t1, t0, 1
    CHECK t1, 0x80000000, 2

    # 3. ADD: phep cong quay vong 32 bit
    li   t0, -1
    li   t1, 1
    add  t2, t0, t1
    CHECK t2, 0, 3

    # 4. SUB: 0 - 1 = 0xffffffff
    sub  t3, x0, t1
    CHECK t3, -1, 4

    # 5-8. So sanh co dau va khong dau
    slt  t2, t0, t1
    CHECK t2, 1, 5

    sltu t2, t0, t1
    CHECK t2, 0, 6

    slti t2, t0, 1
    CHECK t2, 1, 7

    sltiu t2, t0, 1
    CHECK t2, 0, 8

    # 9-11. AND, OR, XOR
    li   t0, 0x0f0f0f0f
    li   t1, 0x33333333

    and  t2, t0, t1
    CHECK t2, 0x03030303, 9

    or   t2, t0, t1
    CHECK t2, 0x3f3f3f3f, 10

    xor  t2, t0, t1
    CHECK t2, 0x3c3c3c3c, 11

    # 12-14. Phep logic immediate
    li   t0, 0x12345678

    andi t2, t0, 0x0ff
    CHECK t2, 0x78, 12

    ori  t2, x0, 0x135
    CHECK t2, 0x135, 13

    xori t2, t2, 0x0ff
    CHECK t2, 0x1ca, 14

    # 15-18. Dich trai: 0, 1, 31 va so bit dich bang 32
    li   t0, 1

    sll  t2, t0, x0
    CHECK t2, 1, 15

    slli t2, t0, 1
    CHECK t2, 2, 16

    slli t2, t0, 31
    CHECK t2, 0x80000000, 17

    li   t1, 32
    sll  t2, t0, t1
    CHECK t2, 1, 18

    # 19-22. Dich phai logic va so hoc
    li   t0, 0x80000000

    srli t2, t0, 31
    CHECK t2, 1, 19

    srai t2, t0, 31
    CHECK t2, -1, 20

    li   t1, 1

    srl  t2, t0, t1
    CHECK t2, 0x40000000, 21

    sra  t2, t0, t1
    CHECK t2, 0xc0000000, 22

    # 23-24. Bien immediate cua ADDI
    li   t0, 0x1000
    addi t2, t0, -2048
    CHECK t2, 0x800, 23

    li   t0, 0
    addi t2, t0, 2047
    CHECK t2, 2047, 24

    # PASS: ECALL, a7=93, a0=0
pass:
    li   gp, 1
    li   a0, 0
    li   a7, 93
    ecall

pass_loop:
    j pass_loop

fail:
    li   gp, 1
    # FAIL: a0 chua ma truong hop loi
    mv   a0, t6
    li   a7, 93
    ecall

fail_loop:
    j fail_loop
