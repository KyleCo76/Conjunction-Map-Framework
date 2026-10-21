"""Draw the CMF-owned art of examples/modCMFExampleIconPack (developer only, no dependencies).

  python tools/cmf_example_art.py [--out examples/modCMFExampleIconPack/art]
Writes innkeeper.png, innkeeper_legend.png, armorer.png and cleared.png: 96x96 flat-colour discs with a
dark outline and a white glyph, 4 transparent pixels at every edge. Deterministic.
"""
import argparse
from pathlib import Path

import cmf_pack
from cmf_test_icons import _inside

SIZE = 96
DARK, WHITE = (32, 28, 24, 255), (255, 255, 255, 255)
AMBER, PURPLE, GREEN = (214, 140, 36, 255), (128, 64, 192, 255), (40, 150, 80, 255)
GREY = (110, 110, 110, 255)
MUG = [[(32, 32), (58, 32), (58, 70), (32, 70)], [(29, 24), (61, 24), (61, 32), (29, 32)]]
MUG_HANDLE, MUG_HOLE = [(58, 38), (69, 38), (69, 62), (58, 62)], [(58, 44), (63, 44), (63, 56), (58, 56)]
SHIELD = [(29, 24), (67, 24), (67, 48), (48, 74), (29, 48)]
SHIELD_BAND = [(46, 28), (50, 28), (50, 66), (46, 66)]
# A tick: the short stroke down to the corner, then the long stroke up.
TICK = [[(26, 48), (34, 40), (46, 52), (40, 66)], [(40, 66), (34, 58), (62, 28), (70, 36)]]


def disc_icon(fill, glyph):
    """glyph(x, y) -> True for white pixels, 'fill' for disc-coloured cut-outs, False for disc."""
    pixels = bytearray()
    centre = SIZE / 2
    for y in range(SIZE):
        for x in range(SIZE):
            distance = ((x + 0.5 - centre) ** 2 + (y + 0.5 - centre) ** 2) ** 0.5
            colour = (0, 0, 0, 0)
            if distance <= 44:
                colour = DARK
            if distance <= 40:
                mark = glyph(x, y)
                colour = WHITE if mark is True else fill
            pixels += bytes(colour)
    return bytes(pixels)


def mug(x, y):
    if any(_inside(shape, x, y) for shape in MUG):
        return True
    return _inside(MUG_HANDLE, x, y) and not _inside(MUG_HOLE, x, y)


def shield(x, y):
    return _inside(SHIELD, x, y) and not _inside(SHIELD_BAND, x, y)


def tick(x, y):
    return any(_inside(shape, x, y) for shape in TICK)


ART = {'innkeeper.png': (AMBER, mug), 'innkeeper_legend.png': (PURPLE, mug), 'armorer.png': (GREEN, shield),
       'cleared.png': (GREY, tick)}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', default=str(Path(__file__).resolve().parents[1]/'examples/modCMFExampleIconPack/art'))
    out = Path(parser.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    for name, (fill, glyph) in ART.items():
        (out/name).write_bytes(cmf_pack.write_png(SIZE, SIZE, disc_icon(fill, glyph)))
        print(out/name)


if __name__ == '__main__':
    main()
