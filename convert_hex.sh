#!/bin/bash
set -e

SRC="$HOME/lab0_asic/sw/rv32ui"
DST="$HOME/lab0_asic/sw/rv32ui_word"

mkdir -p "$DST"

for f in "$SRC"/rv32ui-p-*.hex; do
    name=$(basename "$f")
    out="$DST/$name"

    python3 - "$f" "$out" <<'PY'
import sys

src = sys.argv[1]
dst = sys.argv[2]

data = []
addr = None

with open(src) as f:
    for line in f:
        line = line.strip()

        if not line:
            continue

        if line.startswith("@"):
            addr = int(line[1:], 16)
            continue

        for x in line.split():
            data.append((addr, int(x, 16)))
            addr += 1

mem = {}

for a, b in data:
    mem[a] = b

BASE = 0x80000000

with open(dst, "w") as out:
    if not mem:
        sys.exit(0)

    max_addr = max(mem)

    a = BASE
    while a <= max_addr:
        b0 = mem.get(a,   0)
        b1 = mem.get(a+1, 0)
        b2 = mem.get(a+2, 0)
        b3 = mem.get(a+3, 0)

        word = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

        out.write(f"{word:08X}\n")
        a += 4
PY

    echo "OK: $name"
done

echo
echo "===== DONE ====="
ls "$DST"/*.hex | wc -l
