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
    # RAM test region
    li   t0, 0x83000700

    # Test 1: SW/LW full word
    li   t1, 0x80ff7f01
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    CHECK t2, 0x80ff7f01, 1

    # Test 2-7: LB/LBU byte values and sign extension
    lb   t2, 0(t0)
    CHECK t2, 1, 2

    lbu  t2, 0(t0)
    CHECK t2, 1, 3

    lb   t2, 1(t0)
    CHECK t2, 0x7f, 4

    lb   t2, 2(t0)
    CHECK t2, -1, 5

    lbu  t2, 2(t0)
    CHECK t2, 0xff, 6

    lb   t2, 3(t0)
    CHECK t2, 0xffffff80, 7

    lbu  t2, 3(t0)
    CHECK t2, 0x80, 8

    # Test 9-12: LH/LHU and sign extension
    lh   t2, 0(t0)
    CHECK t2, 0x7f01, 9

    lhu  t2, 0(t0)
    CHECK t2, 0x7f01, 10

    lh   t2, 2(t0)
    CHECK t2, 0xffff80ff, 11

    lhu  t2, 2(t0)
    CHECK t2, 0x80ff, 12

    # Test 13: SB changes only byte lane 1
    li   t1, 0xaa
    sb   t1, 1(t0)
    lw   t2, 0(t0)
    CHECK t2, 0x80ffaa01, 13

    # Test 14: SB changes only byte lane 0
    li   t1, 0x55
    sb   t1, 0(t0)
    lw   t2, 0(t0)
    CHECK t2, 0x80ffaa55, 14

    # Test 15: SH changes upper halfword
    li   t1, 0x1234
    sh   t1, 2(t0)
    lw   t2, 0(t0)
    CHECK t2, 0x1234aa55, 15

    # Test 16-18: SW/LW on a separate word
    li   t1, 0xdeadbeef
    sw   t1, 4(t0)
    lw   t2, 4(t0)
    CHECK t2, 0xdeadbeef, 16

    # Test 17: SB preserves other bytes of the word
    li   t1, 0xab
    sb   t1, 5(t0)
    lw   t2, 4(t0)
    CHECK t2, 0xdeadabef, 17

    # Test 18: SH preserves lower halfword
    li   t1, 0x1357
    sh   t1, 6(t0)
    lw   t2, 4(t0)
    CHECK t2, 0x1357abef, 18

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
