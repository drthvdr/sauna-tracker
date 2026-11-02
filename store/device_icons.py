"""Makes the two 128x128 on-device store icons from rendered PNGs.

usage: python3 -I device_icons.py <full-color 128px png> <low-color 128px png> <out dir>

Writes icon-128-24bit.png (24-bit RGB, for AMOLED watches) and icon-128-64color.png (an
8-bit palette PNG holding Garmin's 64-color palette, for memory-in-pixel watches). Plain
Python, no extra packages. Render the PNG inputs first, see LISTING.md.
"""
import os
import struct
import sys
import zlib

LEVELS = (0, 85, 170, 255)  # the 64-color palette: each channel is one of these


def read_png(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat, header = 8, b"", None
    while pos < len(data):
        size, tag = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + size]
        if tag == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif tag == b"IDAT":
            idat += body
        pos += 12 + size
    w, h, depth, ctype, _, _, interlace = header
    assert depth == 8 and ctype in (2, 6) and interlace == 0, "need an 8-bit RGB or RGBA PNG"
    bpp = 3 if ctype == 2 else 4
    raw, stride = zlib.decompress(idat), w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        kind, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if kind == 1:
                line[x] = (line[x] + a) & 255
            elif kind == 2:
                line[x] = (line[x] + b) & 255
            elif kind == 3:
                line[x] = (line[x] + ((a + b) >> 1)) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        prev = line
    pixels = []
    for line in rows:
        row = []
        for x in range(w):
            r, g, b = line[x * bpp], line[x * bpp + 1], line[x * bpp + 2]
            if bpp == 4:  # flatten any transparency onto white
                alpha = line[x * bpp + 3]
                r, g, b = [(v * alpha + 255 * (255 - alpha)) // 255 for v in (r, g, b)]
            row.append((r, g, b))
        pixels.append(row)
    return w, h, pixels


def chunk(tag, body):
    return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)


def write_png(path, w, h, color_type, rows, palette=None):
    out = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, color_type, 0, 0, 0))
    if palette:
        out += chunk(b"PLTE", b"".join(bytes(c) for c in palette))
    out += chunk(b"IDAT", zlib.compress(b"".join(b"\x00" + bytes(r) for r in rows), 9)) + chunk(b"IEND", b"")
    open(path, "wb").write(out)


def level(v):
    return min(range(4), key=lambda i: abs(LEVELS[i] - v))


def main():
    full_path, low_path, out_dir = sys.argv[1:4]

    w, h, px = read_png(full_path)
    assert (w, h) == (128, 128), "the full-color input must be 128x128"
    rows = [[v for p in row for v in p] for row in px]
    write_png(os.path.join(out_dir, "icon-128-24bit.png"), w, h, 2, rows)

    w, h, px = read_png(low_path)
    assert (w, h) == (128, 128), "the low-color input must be 128x128"
    palette = [(LEVELS[r], LEVELS[g], LEVELS[b]) for r in range(4) for g in range(4) for b in range(4)]
    rows = [[level(r) * 16 + level(g) * 4 + level(b) for r, g, b in row] for row in px]
    write_png(os.path.join(out_dir, "icon-128-64color.png"), w, h, 3, rows, palette)
    used = len({i for row in rows for i in row})
    print(f"icon-128-24bit.png and icon-128-64color.png written ({used} of 64 palette colors used)")


main()
