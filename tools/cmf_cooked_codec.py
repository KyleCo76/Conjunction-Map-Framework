"""Small deterministic single-mip BC3 encoder for CMF-owned RGBA diagnostics.

This is a developer specimen encoder, not a general image cooker. Pixels are
top-left origin, rows left-to-right, unpremultiplied RGBA8. BC3 is lossy.
"""
import struct


def _rgb565(rgb):
    return ((rgb[0] * 31 + 127) // 255 << 11) | ((rgb[1] * 63 + 127) // 255 << 5) | ((rgb[2] * 31 + 127) // 255)


def _expand565(value):
    r = (value >> 11) & 31
    g = (value >> 5) & 63
    b = value & 31
    return (r * 255 // 31, g * 255 // 63, b * 255 // 31)


def _block(texels):
    alpha = [pixel[3] for pixel in texels]
    a0, a1 = max(alpha), min(alpha)
    ap = (a0, a1) + tuple(((8 - i) * a0 + i * a1) // 7 for i in range(1, 7)) if a0 > a1 else (a0, a1, 0, 0, 0, 0, 255, 255)
    ai = sum(min(range(8), key=lambda i: abs(a - ap[i])) << (3 * n) for n, a in enumerate(alpha))
    visible = [p for p in texels if p[3] != 0] or [(0, 0, 0, 0)]
    lo = tuple(min(p[k] for p in visible) for k in range(3))
    hi = tuple(max(p[k] for p in visible) for k in range(3))
    c0, c1 = _rgb565(hi), _rgb565(lo)
    if c0 < c1:
        c0, c1 = c1, c0
    p0, p1 = _expand565(c0), _expand565(c1)
    cp = (p0, p1, tuple((2 * p0[k] + p1[k]) // 3 for k in range(3)),
          tuple((p0[k] + 2 * p1[k]) // 3 for k in range(3)))
    ci = 0
    for n, pixel in enumerate(texels):
        if pixel[3]:
            index = min(range(4), key=lambda i: sum((pixel[k] - cp[i][k]) ** 2 for k in range(3)))
            ci |= index << (2 * n)
    return bytes((a0, a1)) + ai.to_bytes(6, 'little') + struct.pack('<HHI', c0, c1, ci)


def encode_bc3(rgba, width, height):
    if width <= 0 or height <= 0 or width % 4 or height % 4 or len(rgba) != width * height * 4:
        raise ValueError('RGBA8 dimensions must be positive multiples of four with exact bytes')
    if not isinstance(rgba, (bytes, bytearray)):
        raise ValueError('RGBA8 must be bytes')
    view = memoryview(rgba)
    out = bytearray()
    for by in range(0, height, 4):
        for bx in range(0, width, 4):
            pixels = [tuple(view[((by + dy) * width + bx + dx) * 4:((by + dy) * width + bx + dx) * 4 + 4])
                      for dy in range(4) for dx in range(4)]
            out.extend(_block(pixels))
    return bytes(out)
