.option norvc
.section .text
.globl _start
.type _start, @function

# Kiem tra branch phai duoc lay
.macro CHECK_TAKEN branch, rs1, rs2, id
    \branch \rs1, \rs2, 1f
    li   t6, \id
    j    fail
1:
.endm

# Kiem tra branch khong duoc lay
.macro CHECK_NOT_TAKEN branch, rs1, rs2, id
    \branch \rs1, \rs2, 1f
    j    2f
1:
    li   t6, \id
    j    fail
2:
.endm

_start:
    # BEQ: bang nhau / khong bang nhau
    li   t0, 0
    li   t1, 0
    CHECK_TAKEN     beq, t0, t1, 1

    li   t1, 1
    CHECK_NOT_TAKEN beq, t0, t1, 2

    # BNE: khac nhau / bang nhau
    CHECK_TAKEN     bne, t0, t1, 3
    CHECK_NOT_TAKEN bne, t0, t0, 4

    # BLT signed: -1 < 1, nhung 1 khong < -1
    li   t2, -1
    li   t3, 1
    CHECK_TAKEN     blt, t2, t3, 5
    CHECK_NOT_TAKEN blt, t3, t2, 6

    # BGE signed: 1 >= -1, nhung -1 khong >= 1
    CHECK_TAKEN     bge, t3, t2, 7
    CHECK_NOT_TAKEN bge, t2, t3, 8

    # BLTU unsigned: 1 < 0xffffffff
    CHECK_TAKEN     bltu, t3, t2, 9
    CHECK_NOT_TAKEN bltu, t2, t3, 10

    # BGEU unsigned: 0xffffffff >= 1
    CHECK_TAKEN     bgeu, t2, t3, 11
    CHECK_NOT_TAKEN bgeu, t3, t2, 12

    # JAL: nhay toi target va tro ve dung dia chi lien ket
    j    jal_target_skip
jal_target:
    jalr x0, t0, 0

jal_target_skip:
    jal  t0, jal_target
jal_after:
    la   t1, jal_after
    li   t6, 13
    bne  t0, t1, fail

    # JALR: bit 0 cua dia chi dich phai bi xoa
    j    jalr_target_skip
jalr_target:
    jalr x0, t3, 0

jalr_target_skip:
    la   t3, jalr_after
    la   t0, jalr_target
    ori  t0, t0, 1
    jalr t2, t0, 0
jalr_after:
    la   t1, jalr_after
    li   t6, 14
    bne  t2, t1, fail

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
