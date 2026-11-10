#!/usr/bin/env python3
"""Writes AppIcon.png: the prototype's pixel ship (SHIP_SPR) on navy over a pixel sea.

Spec M9's icon: an OPAQUE 1024x1024 PNG (an alpha channel, or an empty appiconset,
fails Xcode's Distribute validation). Standard library only.

    python3 Tools/make_icon.py
"""
import struct, zlib, pathlib

SHIP = [
    "           r              ",
    "           rrr            ",
    "    m      m       m      ",
    "   sss    sssss    ss     ",
    "  sssss  sssssss  ssss    ",
    "    m      m       m      ",
    "  sssss  sssssss  sssss   ",
    " ssssss sssssssss ssssss  ",
    " ssssss sssssssss ssssss  ",
    "    m      m       m      ",
    " ssssss sssssssss sssssss ",
    " ssssss sssssssss sssssss b",
    "    m      m       m    bb",
    "hh  m      m       m   hhh",
    "hhhhhhhhhhhhhhhhhhhhhhhhhh",
    " hyyyyyyyyyyyyyyyyyyyyyyh ",
    "  hhhhhhhhhhhhhhhhhhhhhh  ",
    "   hhhhhhhhhhhhhhhhhhhh   ",
]
COL = {"s": "efe6cc", "m": "6b4a2b", "h": "4a2e1a", "y": "d9a441", "r": "d64545", "b": "6b4a2b"}
SKY, SEA, WAVE = "0a0e14", "123a5c", "2f6a96"

GRID = 32            # logical pixels per side
SIZE = 1024
CELL = SIZE // GRID  # 32 px per logical pixel


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def logical():
    g = [[SKY] * GRID for _ in range(GRID)]
    horizon = 22
    for y in range(horizon, GRID):
        for x in range(GRID):
            g[y][x] = SEA
    for y, offset in ((24, 0), (27, 3), (30, 1)):
        for x in range(offset, GRID, 6):
            g[y][x] = g[y][x + 1 if x + 1 < GRID else x] = WAVE
    top, left = horizon - 14, 3  # hull sits low in the water
    for r, row in enumerate(SHIP):
        for c, ch in enumerate(row):
            y, x = top + r, left + c
            if ch in COL and 0 <= y < GRID and 0 <= x < GRID:
                g[y][x] = COL[ch]
    return g


def png(path):
    g = logical()
    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)
        row = g[y // CELL]
        for x in range(SIZE):
            raw.extend(rgb(row[x // CELL]))

    def chunk(kind, data):
        c = struct.pack(">I", len(data)) + kind + data
        return c + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)  # 8-bit RGB, no alpha
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.write_bytes(data)


if __name__ == "__main__":
    out = pathlib.Path(__file__).resolve().parent.parent / "AroundTheHorn/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    png(out)
    print(out)
