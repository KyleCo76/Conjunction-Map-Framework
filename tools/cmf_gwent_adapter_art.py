"""Draw the CMF-owned placeholder art of the Gwent Players Map adapter (developer only, no dependencies).

  python tools/cmf_gwent_adapter_art.py [--out source/adapters/gwent-players-map/modCMFAdapterGwentPlayersMap/art]
Writes card.png and card_beaten.png: 96x96 upright playing cards with a dark outline, a light face
(white, or grey once the player is beaten or gone) and a dark diamond in the middle. 4 transparent
pixels at every edge. Deterministic. None of it is Gwent Players Map's art.
"""
import argparse
from pathlib import Path

import cmf_pack
from cmf_test_icons import _inside

SIZE = 96
DARK = (32, 28, 24, 255)
WHITE, GREY = (255, 255, 255, 255), (150, 150, 150, 255)
CARD = [(26, 10), (70, 10), (74, 14), (74, 82), (70, 86), (26, 86), (22, 82), (22, 14)]
FACE = [(27, 14), (69, 14), (70, 15), (70, 81), (69, 82), (27, 82), (26, 81), (26, 15)]
BORDER = [(31, 19), (65, 19), (65, 77), (31, 77)]
BORDER_INNER = [(33, 21), (63, 21), (63, 75), (33, 75)]
DIAMOND = [(48, 34), (60, 48), (48, 62), (36, 48)]


def card_icon(fill):
    """Upright card: dark outline, light face, thin inner border and a diamond."""
    pixels = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            colour = (0, 0, 0, 0)
            if _inside(CARD, x, y):
                colour = DARK
                if _inside(FACE, x, y):
                    colour = fill
                    if _inside(BORDER, x, y) and not _inside(BORDER_INNER, x, y):
                        colour = DARK
                    if _inside(DIAMOND, x, y):
                        colour = DARK
            pixels += bytes(colour)
    return bytes(pixels)


ART = {'card.png': WHITE, 'card_beaten.png': GREY}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', default=str(Path(__file__).resolve().parents[1] /
                                             'source/adapters/gwent-players-map/modCMFAdapterGwentPlayersMap/art'))
    out = Path(parser.parse_args().out)
    out.mkdir(parents=True, exist_ok=True)
    for name, fill in ART.items():
        (out/name).write_bytes(cmf_pack.write_png(SIZE, SIZE, card_icon(fill)))
        print(out/name)


if __name__ == '__main__':
    main()
