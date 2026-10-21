"""Draw the placeholder quest icons of the Map Quest Insight adapter (developer only, no dependencies).

  python tools/cmf_mqi_adapter_art.py [--out source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/art]
Writes quest_main.png (a diamond with a star), quest_contract.png (a scroll) and quest_gwent.png (a card
with a round seal): 96x96, light faces drawn white so a tint multiplies them, a dark outline, 4 transparent
pixels at every edge. Deterministic. None of it is Map Quest Insight's art. They stand in for its main quest,
contract and Gwent quest frames until its author ports them; they live in the adapter, never in CMF (Kyle
2026-10-20 18:05Z), and the pack tool cooks them into the adapter's own content/texture.cache, which the map
loads as img://icons/modcmfadaptermapquestinsight/<name>.
"""
import argparse
import math
from pathlib import Path

import cmf_pack
from cmf_test_icons import _inside

SIZE = 96
DARK = (32, 28, 24, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)


def _star(cx, cy, outer, inner):
    return [(cx + (outer if i % 2 == 0 else inner) * math.sin(math.pi * i / 5),
             cy - (outer if i % 2 == 0 else inner) * math.cos(math.pi * i / 5)) for i in range(10)]


def _draw(colour_at):
    pixels = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            pixels += bytes(colour_at(x + 0.5, y + 0.5))
    return bytes(pixels)


def main_quest():
    """Diamond with a five-pointed star, the game's quest shape made distinct."""
    outer = [(48, 6), (90, 48), (48, 90), (6, 48)]
    face = [(48, 13), (83, 48), (48, 83), (13, 48)]
    star = _star(48, 50, 22, 9)
    def at(x, y):
        if not _inside(outer, x, y):
            return CLEAR
        if not _inside(face, x, y) or _inside(star, x, y):
            return DARK
        return WHITE
    return _draw(at)


def contract():
    """A scroll: a sheet between two rolls, with three text lines."""
    sheet = [(24, 18), (72, 18), (72, 78), (24, 78)]
    face = [(28, 22), (68, 22), (68, 74), (28, 74)]
    def roll(x, y, cy):
        return (x - 48) ** 2 / 34.0 ** 2 + (y - cy) ** 2 / 9.0 ** 2 <= 1
    def roll_face(x, y, cy):
        return (x - 48) ** 2 / 30.0 ** 2 + (y - cy) ** 2 / 5.5 ** 2 <= 1
    def at(x, y):
        for cy in (16, 80):
            if roll(x, y, cy):
                return WHITE if roll_face(x, y, cy) else DARK
        if not _inside(sheet, x, y):
            return CLEAR
        if not _inside(face, x, y):
            return DARK
        if 33 <= x <= 63 and any(abs(y - line) <= 1.5 for line in (36, 48, 60)):
            return DARK
        return WHITE
    return _draw(at)


def gwent():
    """An upright card with a round seal in the middle."""
    card = [(26, 8), (70, 8), (76, 14), (76, 82), (70, 88), (26, 88), (20, 82), (20, 14)]
    face = [(27, 13), (69, 13), (71, 15), (71, 81), (69, 83), (27, 83), (25, 81), (25, 15)]
    def at(x, y):
        if not _inside(card, x, y):
            return CLEAR
        if not _inside(face, x, y):
            return DARK
        r = math.hypot(x - 48, y - 48)
        if 10 <= r <= 15 or r <= 5:
            return DARK
        return WHITE
    return _draw(at)


ART = {'quest_main.png': main_quest, 'quest_contract.png': contract, 'quest_gwent.png': gwent}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', default=str(Path(__file__).resolve().parents[1]/
                        'source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/art'))
    out = Path(parser.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    for name, draw in ART.items():
        (out/name).write_bytes(cmf_pack.write_png(SIZE, SIZE, draw()))
        print(out/name)


if __name__ == '__main__':
    main()
