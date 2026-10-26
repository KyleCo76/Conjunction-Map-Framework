"""Original deterministic CMF review glyph, drawn from geometry; no input images."""
from pathlib import Path
import struct
import zlib

def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)

def draw():
    pixels = bytearray()
    for y in range(96):
        pixels.append(0)
        for x in range(96):
            color = (0, 0, 0, 0)
            if 14 <= x <= 81 and 14 <= y <= 81:
                color = (24, 16, 32, 255)
            if 19 <= x <= 76 and 19 <= y <= 76:
                color = (224, 24, 180, 255)
            distance = abs(x - 47.5) + abs(y - 47.5)
            if 23 <= distance <= 28:
                color = (255, 255, 255, 255)
            if (44 <= x <= 51 and 31 <= y <= 64) or (31 <= x <= 64 and 44 <= y <= 51):
                color = (255, 255, 255, 255)
            pixels.extend(color)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB",96,96,8,6,0,0,0)) +
            chunk(b"IDAT",zlib.compress(bytes(pixels),9)) + chunk(b"IEND",b""))

if __name__ == "__main__":
    target = Path(__file__).resolve().parents[1] / "art" / "noticeboard_test.png"
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(draw())
    print(target)
