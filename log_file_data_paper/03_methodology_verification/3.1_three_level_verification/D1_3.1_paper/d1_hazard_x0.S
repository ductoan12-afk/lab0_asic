.option norvc
.section .text
.globl _start
.type _start, @function

.macro CHECK reg, expected, id
    li   t5, \expected
    li   t6, \id
    bne  \reg, t5, fail
.endm

_start:
    # 1. x0 khong duoc thay doi
    addi x0, x0, 123
    CHECK x0, 0, 1

    # 2. RAW dependency: forward rs1
    li   t0, 5
    addi t0, t0, 3
    addi t1, t0, 2
    CHECK t1, 10, 2

    # 3. RAW dependency: forward rs2
    li   s0, 7
    li   s1, 9
    add  s2, s0, s1
    sub  s3, s0, s2
    CHECK s3, -9, 3

    # 4. Chuoi ALU lien tiep
    addi s0, x0, 10
    addi s1, s0, 20
    addi s2, s1, 30
    CHECK s2, 60, 4

    # 5. Load-use: lw ngay truoc addi
    li   t0, 0x83000700
    li   t1, 0x12345678
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    addi t3, t2, 1
    CHECK t3, 0x12345679, 5

    # 6. Store-data forwarding
    addi t1, x0, 0x55
    sw   t1, 4(t0)
    lw   t2, 4(t0)
    CHECK t2, 0x55, 6

    # 7. Branch phu thuoc ket qua ALU vua tao
    addi s0, x0, 4
    addi s0, s0, -4
    beq  s0, x0, branch_taken
    li   t6, 7
    j    fail

branch_taken:
    # 8. Xac nhan branch khong duoc lay khi dieu kien sai
    bne  s0, x0, branch_error
    j    branch_ok

branch_error:
    li   t6, 8
    j    fail

branch_ok:
    # 9. Forward ket qua ALU vao toan hang branch
    addi s1, x0, 10
    addi s2, s1, -10
    beq  s2, x0, branch2_taken
    li   t6, 9
    j    fail

branch2_taken:
    # 10. x0 van bang 0 sau nhieu lenh
    CHECK x0, 0, 10

    # PASS: D2-compatible ECALL protocol
pass:
    li   gp, 1
    li   a0, 0
    li   a7, 93
    ecall

pass_loop:
    j pass_loop

fail:
    li   gp, 1
    mv   a0, t6
    li   a7, 93
    ecall

fail_loop:
    j fail_loop
