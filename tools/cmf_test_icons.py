"""CMF-owned test icon art for the Stage 0 test icon pack (developer only, no dependencies)."""

WHITE = (255, 255, 255, 255)
BLUE = (40, 110, 220, 255)
ORANGE = (255, 140, 0, 255)


def _inside(polygon, x, y):
    """Even-odd test for the pixel centre (x + 0.5, y + 0.5)."""
    px, py = x + 0.5, y + 0.5
    hit = False
    for (x0, y0), (x1, y1) in zip(polygon, polygon[1:] + polygon[:1]):
        if (y0 > py) != (y1 > py) and px < x0 + (py - y0) * (x1 - x0) / (y1 - y0):
            hit = not hit
    return hit


def signpost_icon(size=64):
    """Blue disc in a white ring with a white two-arm signpost; flat colours, RGBA8 bytes."""
    scale = size / 64
    centre, ring, disc = 32 * scale, 30 * scale, 27 * scale
    post = [(30, 14), (35, 14), (35, 53), (30, 53)]
    right = [(35, 17), (46, 17), (51, 22.5), (46, 28), (35, 28)]
    left = [(30, 30), (18, 30), (13, 35.5), (18, 41), (30, 41)]
    shapes = [[(x * scale, y * scale) for x, y in shape] for shape in (post, right, left)]
    pixels = bytearray()
    for y in range(size):
        for x in range(size):
            distance = ((x + 0.5 - centre) ** 2 + (y + 0.5 - centre) ** 2) ** 0.5
            colour = (0, 0, 0, 0)
            if distance <= ring:
                colour = WHITE
            if distance <= disc:
                colour = WHITE if any(_inside(shape, x, y) for shape in shapes) else BLUE
            pixels += bytes(colour)
    return bytes(pixels)


def badge_icon(size=64):
    """Orange diamond in a white rim with a white centre square (second test pack); RGBA8 bytes."""
    scale = size / 64
    centre = 32 * scale
    pixels = bytearray()
    for y in range(size):
        for x in range(size):
            dx, dy = abs(x + 0.5 - centre), abs(y + 0.5 - centre)
            colour = (0, 0, 0, 0)
            if dx + dy <= 30 * scale:
                colour = WHITE
            if dx + dy <= 26 * scale:
                colour = ORANGE
            if max(dx, dy) <= 6 * scale:
                colour = WHITE
            pixels += bytes(colour)
    return bytes(pixels)


LEVEL_COLOURS = [(200, 60, 60), (220, 140, 40), (70, 170, 70), (50, 140, 200), (150, 80, 200)]
GLYPHS = {
    '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
    '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
    '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
    '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
    '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
    '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
    '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
    '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
    '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
    'x': ['00000', '00000', '10001', '01010', '00100', '01010', '10001'],
}


def _bc3_flat(rgb):
    """One opaque single-colour BC3 block (both endpoints equal, all indices 0)."""
    r, g, b = rgb
    c565 = (r >> 3) << 11 | (g >> 2) << 5 | b >> 3
    return b'\xff\xff' + bytes(6) + bytes((c565 & 255, c565 >> 8, c565 & 255, c565 >> 8)) + bytes(4)


def _stamp(cells, text, left, top, scale, value):
    for n, char in enumerate(text):
        for row, bits in enumerate(GLYPHS[char]):
            for col, bit in enumerate(bits):
                if bit == '1':
                    for dy in range(scale):
                        for dx in range(scale):
                            cells[(top + row * scale + dy, left + (n * 6 + col) * scale + dx)] = value


def background_tile_bc3(level, x, y, size=1024):
    """Test map tile as a single-mip BC3 stream: level colour, parity shade, dark border,
    the level number large and the tile's XxY coordinates small. Built from flat 4x4 blocks."""
    blocks = size // 4
    base = LEVEL_COLOURS[level % len(LEVEL_COLOURS)]
    if (x + y) % 2:
        base = tuple(c * 3 // 4 for c in base)
    fill, border, ink = _bc3_flat(base), _bc3_flat((32, 32, 32)), _bc3_flat((255, 255, 255))
    cells = {}
    big = max(1, blocks // 20)
    small = max(1, blocks // 64)
    _stamp(cells, str(level), (blocks - 5 * big) // 2, blocks // 2 - 7 * big - 2 * small, big, ink)
    label = '%dx%d' % (x, y)
    _stamp(cells, label, (blocks - (len(label) * 6 - 1) * small) // 2, blocks // 2 + 2 * small, small, ink)
    edge = max(1, blocks // 128)
    out = bytearray()
    for by in range(blocks):
        for bx in range(blocks):
            if bx < edge or by < edge or bx >= blocks - edge or by >= blocks - edge:
                out += border
            else:
                out += cells.get((by, bx), fill)
    return bytes(out)
