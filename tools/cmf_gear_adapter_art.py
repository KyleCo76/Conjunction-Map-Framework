"""Draw the CMF-owned placeholder art of the Witcher Gear Map adapter (developer only, no dependencies).

  python tools/cmf_gear_adapter_art.py [--out source/adapters/witcher-gear-map/modCMFAdapterWitcherGearMap/art]
Writes gear.png, gear_ring.png, gear_obtained.png and gear_obtained_ring.png: 96x96 diagram sheets
with a dark outline, light fill (white, or grey once learned) so CMF tints colour them, and an
optional ring. 4 transparent pixels at every edge. Deterministic. None of it is Gear Map's art.
"""
import argparse
from pathlib import Path

import cmf_pack
from cmf_test_icons import _inside

SIZE = 96
DARK = (32, 28, 24, 255)
WHITE, GREY = (255, 255, 255, 255), (150, 150, 150, 255)
SHEET = [(30, 20), (58, 20), (68, 30), (68, 76), (30, 76)]
SHEET_INNER = [(33, 23), (57, 23), (65, 31), (65, 73), (33, 73)]
FOLD = [(56, 22), (66, 32), (56, 32)]
LINES = [[(38, y), (60, y), (60, y + 3), (38, y + 3)] for y in (38, 47, 56, 65)]


def sheet_icon(fill, ring):
    """Diagram sheet; with ring, inside a light ring that also takes the tint."""
    pixels = bytearray()
    centre = SIZE / 2
    for y in range(SIZE):
        for x in range(SIZE):
            distance = ((x + 0.5 - centre) ** 2 + (y + 0.5 - centre) ** 2) ** 0.5
            colour = (0, 0, 0, 0)
            if ring and 37 <= distance <= 44:
                colour = DARK
            if ring and 39 <= distance <= 42:
                colour = fill
            if _inside(SHEET, x, y):
                colour = DARK
                if _inside(SHEET_INNER, x, y) and not _inside(FOLD, x, y) and \
                        not any(_inside(line, x, y) for line in LINES):
                    colour = fill
            pixels += bytes(colour)
    return bytes(pixels)


ART = {'gear.png': (WHITE, False), 'gear_ring.png': (WHITE, True),
       'gear_obtained.png': (GREY, False), 'gear_obtained_ring.png': (GREY, True)}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', default=str(Path(__file__).resolve().parents[1] /
                                             'source/adapters/witcher-gear-map/modCMFAdapterWitcherGearMap/art'))
    out = Path(parser.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    for name, (fill, ring) in ART.items():
        (out/name).write_bytes(cmf_pack.write_png(SIZE, SIZE, sheet_icon(fill, ring)))
        print(out/name)


if __name__ == '__main__':
    main()
