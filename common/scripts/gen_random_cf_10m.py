#!/usr/bin/env python3

import random
import sys
from pathlib import Path

SEED = 0x20260929

# 400,000 loop iterations give >10M dynamic instructions.
DEFAULT_LOOPS = 400_000

# Each selected block contains 12 random instructions.
BLOCK_RAND = 12
BLOCKS = 8

# Reserved registers:
# x0        = constant zero
# x1..x7    = branch-dispatch constants 1..7
# x20       = data-memory base 0x83000000
# x27       = reserved
# x28       = selector
# x29       = loop counter
# x30/x31   = signature accumulators
CONTROL_REGS = (
    set(range(0, 8))
    | {20, 27, 28, 29, 30, 31}
)

RANDOM_REGS = [
    r for r in range(1, 32)
    if r not in CONTROL_REGS
]


def rand_reg(rng):
    return rng.choice(RANDOM_REGS)


def rand_alu(rng):
    rd = rand_reg(rng)
    rs1 = rand_reg(rng)
    rs2 = rand_reg(rng)

    k = rng.randrange(17)

    if k == 0:
        return f"add x{rd},x{rs1},x{rs2}"

    if k == 1:
        return f"sub x{rd},x{rs1},x{rs2}"

    if k == 2:
        return f"and x{rd},x{rs1},x{rs2}"

    if k == 3:
        return f"or x{rd},x{rs1},x{rs2}"

    if k == 4:
        return f"xor x{rd},x{rs1},x{rs2}"

    if k == 5:
        return f"sll x{rd},x{rs1},x{rs2}"

    if k == 6:
        return f"srl x{rd},x{rs1},x{rs2}"

    if k == 7:
        return f"sra x{rd},x{rs1},x{rs2}"

    if k == 8:
        return f"slt x{rd},x{rs1},x{rs2}"

    if k == 9:
        return f"sltu x{rd},x{rs1},x{rs2}"

    if k == 10:
        imm = rng.randint(-2048, 2047)
        return f"addi x{rd},x{rs1},{imm}"

    if k == 11:
        imm = rng.randint(-2048, 2047)
        return f"andi x{rd},x{rs1},{imm}"

    if k == 12:
        imm = rng.randint(-2048, 2047)
        return f"ori x{rd},x{rs1},{imm}"

    if k == 13:
        imm = rng.randint(-2048, 2047)
        return f"xori x{rd},x{rs1},{imm}"

    if k == 14:
        imm = rng.randint(-2048, 2047)
        return f"slti x{rd},x{rs1},{imm}"

    if k == 15:
        imm = rng.randint(-2048, 2047)
        return f"sltiu x{rd},x{rs1},{imm}"

    shamt = rng.randrange(32)
    op = rng.choice(["slli", "srli", "srai"])
    return f"{op} x{rd},x{rs1},{shamt}"


def rand_mem(rng):
    rd = rand_reg(rng)
    rs2 = rand_reg(rng)

    k = rng.randrange(8)

    if k == 0:
        off = rng.randrange(64) * 4
        return f"lw x{rd},{off}(x20)"

    if k == 1:
        off = rng.randrange(128) * 2
        return f"lh x{rd},{off}(x20)"

    if k == 2:
        off = rng.randrange(128) * 2
        return f"lhu x{rd},{off}(x20)"

    if k == 3:
        off = rng.randrange(256)
        return f"lb x{rd},{off}(x20)"

    if k == 4:
        off = rng.randrange(256)
        return f"lbu x{rd},{off}(x20)"

    if k == 5:
        off = rng.randrange(256)
        return f"sb x{rs2},{off}(x20)"

    if k == 6:
        off = rng.randrange(128) * 2
        return f"sh x{rs2},{off}(x20)"

    off = rng.randrange(64) * 4
    return f"sw x{rs2},{off}(x20)"


def emit_branch_stress(out, block_id):
    # All six RV32I conditional branch types execute.
    # Targets are the next instruction, so the branch does not
    # destroy the control-flow structure of the block.

    labels = [
        f".LBR{block_id}_{i}"
        for i in range(6)
    ]

    out.append(f"  beq  x1,x1,{labels[0]}")    # taken
    out.append(f"{labels[0]}:")

    out.append(f"  bne  x1,x1,{labels[1]}")    # not taken
    out.append(f"{labels[1]}:")

    out.append(f"  blt  x0,x1,{labels[2]}")    # taken
    out.append(f"{labels[2]}:")

    out.append(f"  bge  x1,x0,{labels[3]}")    # taken
    out.append(f"{labels[3]}:")

    out.append(f"  bltu x0,x1,{labels[4]}")    # taken
    out.append(f"{labels[4]}:")

    out.append(f"  bgeu x1,x0,{labels[5]}")    # taken
    out.append(f"{labels[5]}:")


def make_program(loops):
    rng = random.Random(SEED)

    out = []

    # ------------------------------------------------------------
    # Initialization
    # ------------------------------------------------------------

    out += [
        ".option norelax",
        ".section .text",
        ".globl _start",
        "_start:",
        "  lui x20,0x83000",
    ]

    # x1..x19 = known constants
    for r in range(1, 20):
        out.append(f"  addi x{r},x0,{r}")

    # x21..x26 = known constants
    for r in range(21, 27):
        out.append(f"  addi x{r},x0,{r}")

    # Seed data memory
    for i, r in enumerate(range(8, 16)):
        out.append(f"  sw x{r},{i * 4}(x20)")

    # x29 = loop count
    hi = (loops + 0x800) >> 12
    lo = loops - (hi << 12)

    out += [
        f"  lui x29,0x{hi:x}",
        f"  addi x29,x29,{lo}",
        "  addi x30,x0,0",
        "  addi x31,x0,0",
        "",
        ".Lloop:",
        "  addi x29,x29,-1",
        "  beq x29,x0,.Lfinish",
        "  andi x28,x29,7",

        # Dispatch 8 ways.
        "  beq x28,x0,.LB0",
        "  beq x28,x1,.LB1",
        "  beq x28,x2,.LB2",
        "  beq x28,x3,.LB3",
        "  beq x28,x4,.LB4",
        "  beq x28,x5,.LB5",
        "  beq x28,x6,.LB6",
        "  jal x0,.LB7",
        "",
    ]

    # ------------------------------------------------------------
    # Eight random basic blocks
    # ------------------------------------------------------------

    for b in range(BLOCKS):
        out.append(f".LB{b}:")

        for _ in range(BLOCK_RAND):
            if rng.randrange(4) == 0:
                out.append("  " + rand_mem(rng))
            else:
                out.append("  " + rand_alu(rng))

        emit_branch_stress(out, b)

        # Real jump back to loop.
        out.append("  jal x0,.Lloop")
        out.append("")

    # ------------------------------------------------------------
    # Final signature
    # ------------------------------------------------------------

    out += [
        ".Lfinish:",
        "  add x31,x1,x0",
        "  add x30,x2,x0",
    ]

    # Mix final architectural register state.
    sources = list(range(1, 20)) + list(range(21, 30))

    for r in sources[1:]:
        out.append("  slli x31,x31,5")
        out.append(f"  xor x31,x31,x{r}")
        out.append("  slli x30,x30,7")
        out.append(f"  xor x30,x30,x{r}")

    # Signature stores.
    out += [
        "  sw x31,1792(x20)",   # 0x83000700
        "  sw x30,1796(x20)",   # 0x83000704
        ".Lhalt:",
        "  jal x0,.Lhalt",
        "",
    ]

    return "\n".join(out)


def expected_dynamic(loops):
    # For non-final iterations:
    #
    #   addi counter       = 1
    #   beq finish         = 1
    #   andi selector      = 1
    #   dispatch branches  = 1..8, average 4.5
    #   selected block     = 12 random + 6 branches + 1 JAL = 19
    #
    # selector cycles over 0..7 because x29 is decremented by one
    # every iteration.

    dispatch = 0

    for value in range(1, loops):
        selector = value & 7

        if selector <= 6:
            dispatch += selector + 1
        else:
            dispatch += 8

    init = 38

    full_iterations = (loops - 1) * 22 + dispatch

    final_iteration = 2

    # Signature:
    #   add x31,x1,x0
    #   add x30,x2,x0
    #   24 * 4 hash instructions
    #   2 stores
    #   1 halt JAL
    signature = 2 + 24 * 4 + 2 + 1

    return init + full_iterations + final_iteration + signature


def main():
    loops = (
        int(sys.argv[1])
        if len(sys.argv) > 1
        else DEFAULT_LOOPS
    )

    out = (
        sys.argv[2]
        if len(sys.argv) > 2
        else "sw/random_cf_10m.S"
    )

    Path(out).write_text(make_program(loops))

    dynamic = expected_dynamic(loops)

    print(f"Seed                 : 0x{SEED:08x}")
    print(f"Loop iterations      : {loops}")
    print(f"Expected dynamic     : {dynamic}")
    print(f"Assembly             : {out}")
    print("Data base             : 0x83000000")
    print("Signature             : 0x83000700 / 0x83000704")


if __name__ == "__main__":
    main()
