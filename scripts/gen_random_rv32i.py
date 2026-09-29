#!/usr/bin/env python3

import random
import struct
import sys

SEED = 0x20260929

# Reserved registers:
# x20 = data-memory base = 0x80000000
# x30/x31 = final signature accumulators
RESERVED = {0, 20, 30, 31}

DATA_BASE = 0x80010000
SIG0_ADDR = 0x80010700
SIG1_ADDR = 0x80010704

def rtype(funct3, funct7, rd, rs1, rs2):
    return (
        (funct7 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | 0x33
    )


def itype(funct3, rd, rs1, imm):
    imm &= 0xFFF
    return (
        (imm << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | 0x13
    )


def shift_imm(funct3, funct7, rd, rs1, shamt):
    imm = (funct7 << 5) | (shamt & 0x1F)
    return (
        (imm << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | 0x13
    )


def lui(rd, imm20):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0x37


def load(funct3, rd, rs1, imm):
    imm &= 0xFFF
    return (
        (imm << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (rd << 7)
        | 0x03
    )


def store(funct3, rs1, rs2, imm):
    imm &= 0xFFF
    return (
        ((imm >> 5) << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | ((imm & 0x1F) << 7)
        | 0x23
    )


def pick_reg(rng):
    regs = list(range(1, 32))
    regs = [r for r in regs if r not in RESERVED]
    return rng.choice(regs)


def emit(words, w):
    words.append(w & 0xFFFFFFFF)


def generate(random_count):
    rng = random.Random(SEED)
    words = []

    # ------------------------------------------------------------
    # Initial state
    # ------------------------------------------------------------

    # x20 = 0x80000000
    emit(words, lui(20, 0x80010))

    # Known register values.
    for rd in range(1, 20):
        emit(words, itype(0, rd, 0, rd))

    # Seed DMEM with known values at 0x80000000 .. 0x80000020
    for i, rs2 in enumerate(range(1, 9)):
        emit(words, store(2, 20, rs2, i * 4))

    # ------------------------------------------------------------
    # Random RV32I instructions
    # No branch / JAL / JALR / PC-relative instruction.
    # Therefore:
    #   RTL PC = 0x00000000 + 4*n
    #   Spike PC = 0x80000000 + 4*n
    # but instruction flow is identical.
    # ------------------------------------------------------------

    while len(words) < random_count + 21:

        rd = pick_reg(rng)
        rs1 = pick_reg(rng)
        rs2 = pick_reg(rng)

        kind = rng.randrange(16)

        if kind == 0:
            emit(words, rtype(0, 0x00, rd, rs1, rs2))       # ADD

        elif kind == 1:
            emit(words, rtype(0, 0x20, rd, rs1, rs2))       # SUB

        elif kind == 2:
            emit(words, rtype(7, 0x00, rd, rs1, rs2))       # AND

        elif kind == 3:
            emit(words, rtype(6, 0x00, rd, rs1, rs2))       # OR

        elif kind == 4:
            emit(words, rtype(4, 0x00, rd, rs1, rs2))       # XOR

        elif kind == 5:
            emit(words, rtype(1, 0x00, rd, rs1, rs2))       # SLL

        elif kind == 6:
            emit(words, rtype(5, 0x00, rd, rs1, rs2))       # SRL

        elif kind == 7:
            emit(words, rtype(5, 0x20, rd, rs1, rs2))       # SRA

        elif kind == 8:
            emit(words, rtype(2, 0x00, rd, rs1, rs2))       # SLT

        elif kind == 9:
            emit(words, rtype(3, 0x00, rd, rs1, rs2))       # SLTU

        elif kind == 10:
            imm = rng.randint(-2048, 2047)
            emit(words, itype(0, rd, rs1, imm))             # ADDI

        elif kind == 11:
            imm = rng.randint(-2048, 2047)
            emit(words, itype(7, rd, rs1, imm))             # ANDI

        elif kind == 12:
            imm = rng.randint(-2048, 2047)
            emit(words, itype(6, rd, rs1, imm))             # ORI

        elif kind == 13:
            imm = rng.randint(-2048, 2047)
            emit(words, itype(4, rd, rs1, imm))             # XORI

        elif kind == 14:
            shamt = rng.randrange(32)
            subkind = rng.randrange(3)

            if subkind == 0:
                emit(words, shift_imm(1, 0x00, rd, rs1, shamt))  # SLLI
            elif subkind == 1:
                emit(words, shift_imm(5, 0x00, rd, rs1, shamt))  # SRLI
            else:
                emit(words, shift_imm(5, 0x20, rd, rs1, shamt))  # SRAI

        else:
            # Load/store group.
            subkind = rng.randrange(6)

            if subkind == 0:
                # LW + often immediate consumer -> load-use hazard
                load_rd = pick_reg(rng)
                offset = rng.randrange(64) * 4
                emit(words, load(2, load_rd, 20, offset))

                if len(words) < random_count + 21:
                    consume_rd = pick_reg(rng)
                    consume_rs2 = pick_reg(rng)
                    emit(words,
                         rtype(0, 0x00,
                               consume_rd,
                               load_rd,
                               consume_rs2))

            elif subkind == 1:
                # LH
                rd2 = pick_reg(rng)
                offset = rng.randrange(128) * 2
                emit(words, load(1, rd2, 20, offset))

            elif subkind == 2:
                # LHU
                rd2 = pick_reg(rng)
                offset = rng.randrange(128) * 2
                emit(words, load(5, rd2, 20, offset))

            elif subkind == 3:
                # LB
                rd2 = pick_reg(rng)
                offset = rng.randrange(256)
                emit(words, load(0, rd2, 20, offset))

            elif subkind == 4:
                # LBU
                rd2 = pick_reg(rng)
                offset = rng.randrange(256)
                emit(words, load(4, rd2, 20, offset))

            else:
                # Random store
                rs2_store = pick_reg(rng)

                store_type = rng.randrange(3)

                if store_type == 0:
                    offset = rng.randrange(256)
                    emit(words, store(0, 20, rs2_store, offset))   # SB

                elif store_type == 1:
                    offset = rng.randrange(128) * 2
                    emit(words, store(1, 20, rs2_store, offset))   # SH

                else:
                    offset = rng.randrange(64) * 4
                    emit(words, store(2, 20, rs2_store, offset))   # SW

    # ------------------------------------------------------------
    # Trim so exactly random_count "body" instructions remain
    # after the fixed initialization.
    # ------------------------------------------------------------

    init_count = 1 + 19 + 8

    if len(words) > init_count + random_count:
        words = words[:init_count + random_count]

    # ------------------------------------------------------------
    # Final reference signature.
    #
    # x30 and x31 are deliberately excluded from random writes.
    # Two order-sensitive 32-bit hashes are generated from:
    # x1..x19, x21..x29
    #
    # Signature addresses:
    #   0x80000700
    #   0x80000704
    #
    # On RTL Data_memory:
    #   A[15:2] is used, so these are inside its 64-KiB RAM.
    # On Spike:
    #   RAM starts at 0x80000000, so these are the same addresses.
    # ------------------------------------------------------------

    sources = list(range(1, 20)) + list(range(21, 30))

    emit(words, rtype(0, 0x00, 31, 1, 0))  # x31 = x1
    emit(words, rtype(0, 0x00, 30, 2, 0))  # x30 = x2

    for r in sources[1:]:
        emit(words, shift_imm(1, 0x00, 31, 31, 5))  # slli x31,x31,5
        emit(words, rtype(4, 0x00, 31, 31, r))       # xor  x31,x31,r

        emit(words, shift_imm(1, 0x00, 30, 30, 7))  # slli x30,x30,7
        emit(words, rtype(4, 0x00, 30, 30, r))       # xor  x30,x30,r

    # Store signature 0
    emit(words, store(2, 20, 31, 0x0700))

    # Store signature 1
    emit(words, store(2, 20, 30, 0x0704))

    return words


def main():
    if len(sys.argv) != 4:
        print(
            "Usage:\n"
            "  python3 gen_random_rv32i.py <random_count> <output.hex> <output.bin>"
        )
        sys.exit(1)

    random_count = int(sys.argv[1])
    hex_file = sys.argv[2]
    bin_file = sys.argv[3]

    if random_count <= 0:
        raise ValueError("random_count must be > 0")

    words = generate(random_count)

    with open(hex_file, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")

    with open(bin_file, "wb") as f:
        for w in words:
            f.write(struct.pack("<I", w))

    print(f"Seed          : 0x{SEED:08x}")
    print(f"Random body   : {random_count}")
    print(f"Total words   : {len(words)}")
    print(f"Total bytes   : {len(words) * 4}")
    print(f"HEX           : {hex_file}")
    print(f"BIN           : {bin_file}")


if __name__ == "__main__":
    main()

