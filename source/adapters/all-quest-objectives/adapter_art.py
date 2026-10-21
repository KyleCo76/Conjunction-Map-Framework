"""Draw the placeholder art of the All Quest Objectives adapter (developer only, no dependencies).

  python source/adapters/all-quest-objectives/adapter_art.py [--out .../modCMFAdapterAllQuestObjectives/art]
Writes badge.png (a white disc with a dark rim and a dark exclamation mark) and mark.png (a white
exclamation mark with a dark outline), 96x96 with 4 transparent pixels at every edge. The adapter tints
them per pin with the colour All Quest Objectives names, so white parts take the colour and dark parts stay
dark. Deterministic. Our own drawings, none of it All Quest Objectives' art.
"""
import argparse
import math
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[3]/'tools'))
import cmf_pack

SIZE = 96
CENTRE = SIZE / 2
DARK = (29, 29, 27, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)


def in_bar(x, y, top, bottom, half_top, half_bottom):
    """Inside the tapering stroke of the mark (wider at the top), centred on the middle column."""
    if y < top or y > bottom:
        return False
    half = half_top + (half_bottom - half_top) * (y - top) / (bottom - top)
    return abs(x - CENTRE) <= half


def in_mark(x, y, scale, grow=0.0):
    """The exclamation mark: a stroke and a dot, both grown by `grow` pixels for an outline."""
    top, bottom = CENTRE - 30 * scale - grow, CENTRE + 8 * scale + grow
    if in_bar(x, y, top, bottom, 7 * scale + grow, 3.5 * scale + grow):
        return True
    return math.hypot(x - CENTRE, y - (CENTRE + 22 * scale)) <= 7 * scale + grow


def badge(x, y):
    distance = math.hypot(x - CENTRE, y - CENTRE)
    if distance > 44:
        return CLEAR
    if distance > 37:
        return DARK
    if in_mark(x, y, 0.85):
        return DARK
    return WHITE


def mark(x, y):
    if in_mark(x, y, 1.3):
        return WHITE
    if in_mark(x, y, 1.3, 3):
        return DARK
    return CLEAR


def draw(shape):
    pixels = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            pixels += bytes(shape(x + 0.5, y + 0.5))
    return bytes(pixels)


ART = {'badge.png': badge, 'mark.png': mark}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', default=str(Path(__file__).resolve().parent/'modCMFAdapterAllQuestObjectives/art'))
    out = Path(parser.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    for name, shape in ART.items():
        (out/name).write_bytes(cmf_pack.write_png(SIZE, SIZE, draw(shape)))
        print(out/name)


if __name__ == '__main__':
    main()
