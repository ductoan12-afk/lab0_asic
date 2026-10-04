#!/usr/bin/env python3

import random
import sys
from pathlib import Path

SEED = 0x20260929
TARGET = 10_000_000

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


BRANCH_TYPES = [
    ("beq",  "x1", "x1"),
    ("bne",  "x1", "x1"),
    ("blt",  "x0", "x1"),
    ("bge",  "x1", "x0"),
    ("bltu", "x0", "x1"),
    ("bgeu", "x1", "x0"),
]


def emit_next_branch(out, branch_id, branch_type):
    op, rs1, rs2 = BRANCH_TYPES[branch_type % len(BRANCH_TYPES)]
    label = f".LPRE_{branch_id}"
    out.append(f"  {op} {rs1},{rs2},{label}")
    out.append(f"{label}:")


def emit_side_branch(out, branch_id, branch_type):
    op, rs1, rs2 = BRANCH_TYPES[branch_type % len(BRANCH_TYPES)]
    label = f".LBRA_{branch_id}"
    out.append(f"  {op} {rs1},{rs2},{label}")
    out.append(f"{label}:")


def make_program(ratio):
    if ratio not in (5, 10, 15, 20):
        raise ValueError("ratio must be one of: 5, 10, 15, 20")

    # Body sizes and branch counts.
    # The loop body contains exactly B retired instructions,
    # including b conditional branches.
    config = {
        5:  {"body": 20, "branches": 1},
        10: {"body": 10, "branches": 1},
        15: {"body": 20, "branches": 3},
        20: {"body": 5, "branches": 1},
    }

    body = config[ratio]["body"]
    branches_per_body = config[ratio]["branches"]

    # Prelude = exactly 40 retired instructions.
    # It contains q branches so that TOTAL branch count over
    # the first 10,000,000 retired instructions is exact.
    loops = (TARGET - 40) // body
    required_branches = TARGET * ratio // 100
    prelude_branches = required_branches - loops * branches_per_body

    assert 40 + loops * body == TARGET
    assert prelude_branches >= 0
    assert prelude_branches <= 10
    assert prelude_branches + loops * branches_per_body == required_branches

    rng = random.Random(SEED)

    out = []

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

    # Loop counter
    hi = (loops + 0x800) >> 12
    lo = loops - (hi << 12)

    out += [
        f"  lui x29,0x{hi:x}",
        f"  addi x29,x29,{lo}",
        "  addi x30,x0,0",
        "  addi x31,x0,0",
    ]

    # We currently have exactly 30 prelude instructions.
    # Add 10 more: exactly prelude_branches branches + NOPs.
    for i in range(prelude_branches):
        emit_next_branch(out, i, i)

    for _ in range(10 - prelude_branches):
        out.append("  addi x0,x0,0")

    out.append("")
    out.append(".Lloop:")

    # One non-branch is the loop-counter decrement.
    out.append("  addi x29,x29,-1")

    remaining_nonbranch = body - branches_per_body - 1

    for _ in range(remaining_nonbranch):
        if rng.randrange(4) == 0:
            out.append("  " + rand_mem(rng))
        else:
            out.append("  " + rand_alu(rng))

    # For 15%, add 2 side branches plus the loop branch.
    # For the other ratios, only the loop branch is present.
    side_branches = branches_per_body - 1

    for i in range(side_branches):
        emit_side_branch(
            out,
            ratio * 1000 + i,
            i + prelude_branches,
        )

    # Main loop-control branch.
    # Taken on every non-final iteration, not taken on the final one.
    out.append("  bne x29,x0,.Lloop")
    out.append("")

    # Signature code: same structure as the old generator.
    out += [
        ".Lfinish:",
        "  add x31,x1,x0",
        "  add x30,x2,x0",
    ]

    sources = list(range(1, 20)) + list(range(21, 30))

    for r in sources[1:]:
        out.append("  slli x31,x31,5")
        out.append(f"  xor x31,x31,x{r}")
        out.append("  slli x30,x30,7")
        out.append(f"  xor x30,x30,x{r}")

    out += [
        "  sw x31,1792(x20)",
        "  sw x30,1796(x20)",
        ".Lhalt:",
        "  jal x0,.Lhalt",
        "",
    ]

    return "\n".join(out), loops, required_branches


def main():
    if len(sys.argv) < 2:
        print("Usage: gen_branch_rate_10m.py RATIO [OUTPUT.S]")
        print("RATIO = 5, 10, 15, or 20")
        sys.exit(1)

    ratio = int(sys.argv[1])

    if len(sys.argv) > 2:
        output = sys.argv[2]
    else:
        output = f"sw/branch_{ratio}.S"

    program, loops, branch_count = make_program(ratio)

    Path(output).write_text(program)

    print("=" * 60)
    print(f"Branch ratio         : {ratio}%")
    print(f"Target retired       : {TARGET:,}")
    print(f"Loop iterations      : {loops:,}")
    print(f"Expected branches    : {branch_count:,}")
    print(f"Expected non-branch  : {TARGET - branch_count:,}")
    print(
        f"Expected branch rate : "
        f"{100.0 * branch_count / TARGET:.6f}%"
    )
    print(f"Assembly              : {output}")
    print("Signature             : 0x83000700 / 0x83000704")
    print("=" * 60)


if __name__ == "__main__":
    main()
