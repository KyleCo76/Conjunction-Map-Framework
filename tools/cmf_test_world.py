"""Art and staging for the revision 9 test packs modCMFTestWorldA and modCMFTestWorldB (developer only, no dependencies).

  python tools/cmf_test_world.py art
  python tools/cmf_test_world.py stage --out <new folder>

art draws both packs' placeholder pictures into source/providers/<pack>/art/: big letters "A" or "B" on plain shapes.
A: the world painting as one 2100 x 1380 picture, crests for six regions, a player marker, and a button picture for
every Xbox button. B: the painting as 2 x 2 tiles, four crests, and a button picture for every Xbox button whose name
starts with gamepad_. Every picture carries a small number or tile coordinate so screenshots tell them apart.

BC3 needs each side to be a multiple of 4, so a picture whose game size is not one is drawn one step larger (the map
stretches every picture to the game's own rectangle): crests 136 x 132 (Kaer Morhen, 135 x 130 in the game) and
136 x 116 (135 x 116); B's tiles 1052 x 692 (half of 2100 x 1380 is 1050 x 690).

stage builds both packs with tools/cmf_pack.py into <out>/Mods/<pack>/... (as they install), keeps each build's
pack-build.json as <out>/<pack>-pack-build.json and writes <out>/README.md listing every file with its SHA-256. All art is CMF's own procedural geometry. Never deploys or launches anything.
"""
import argparse
import hashlib
from pathlib import Path
import shutil
import tempfile

import cmf_button_sheet
import cmf_pack
from cmf_test_icons import GLYPHS

ROOT = Path(__file__).resolve().parents[1]
PROVIDERS = ROOT/'source/providers'
PACKS = ('modCMFTestWorldA', 'modCMFTestWorldB')
LETTERS = {
    'A': ['01110', '10001', '10001', '11111', '10001', '10001', '10001'],
    'B': ['11110', '10001', '10001', '11110', '10001', '10001', '11110'],
}
CLEAR = (0, 0, 0, 0)
WHITE = (255, 255, 255, 255)
INK = (24, 24, 24, 255)
# Pack colours: A blue-green, B amber, so a screenshot shows whose picture won.
COLOURS = {'A': {'sea': (38, 92, 112, 255), 'land': (70, 140, 150, 255), 'mark': (30, 110, 220, 255)},
           'B': {'sea': (120, 70, 20, 255), 'land': (190, 130, 50, 255), 'mark': (230, 120, 0, 255)}}
PAINTING = (2100, 1380)
TILE = (1052, 692)
CRESTS_A = ('kaer_morhen', 'skellige', 'novigrad', 'no_mans_land', 'wyzima_castle', 'bob')
CRESTS_B = ('skellige', 'novigrad', 'bob', 'prolog_village')
BUTTON = 64


class Canvas:
    def __init__(self, width, height, colour=CLEAR):
        self.width, self.height = width, height
        self.pixels = bytearray(bytes(colour) * (width * height))

    def rect(self, left, top, right, bottom, colour):
        left, top = max(0, int(left)), max(0, int(top))
        right, bottom = min(self.width, int(right)), min(self.height, int(bottom))
        if right <= left:
            return
        run = bytes(colour) * (right - left)
        for y in range(top, bottom):
            start = (y * self.width + left) * 4
            self.pixels[start:start + len(run)] = run

    def shape(self, inside, colour):
        """Fill every pixel whose centre passes inside(x, y)."""
        for y in range(self.height):
            for x in range(self.width):
                if inside(x + 0.5, y + 0.5):
                    start = (y * self.width + x) * 4
                    self.pixels[start:start + 4] = bytes(colour)

    def text(self, text, centre_x, top, scale, colour):
        """Stamp 5 x 7 glyphs (one pixel gap) scaled by scale, centred on centre_x."""
        width = (len(text) * 6 - 1) * scale
        left = centre_x - width // 2
        for n, char in enumerate(text):
            for row, bits in enumerate(LETTERS.get(char) or GLYPHS[char]):
                for col, bit in enumerate(bits):
                    if bit == '1':
                        x = left + (n * 6 + col) * scale
                        self.rect(x, top + row * scale, x + scale, top + (row + 1) * scale, colour)

    def png(self):
        return cmf_pack.write_png(self.width, self.height, bytes(self.pixels))


def painting(letter, width, height, label):
    """A plain 'map': sea, a few land blocks, a border, the letter huge in the middle and a label under it."""
    colours = COLOURS[letter]
    canvas = Canvas(width, height, colours['sea'])
    for fx, fy, fw, fh in ((0.08, 0.1, 0.3, 0.35), (0.55, 0.08, 0.35, 0.3), (0.12, 0.58, 0.32, 0.3),
                           (0.6, 0.55, 0.3, 0.36)):
        canvas.rect(width * fx, height * fy, width * (fx + fw), height * (fy + fh), colours['land'])
    edge = max(4, width // 200)
    canvas.rect(0, 0, width, edge, INK)
    canvas.rect(0, height - edge, width, height, INK)
    canvas.rect(0, 0, edge, height, INK)
    canvas.rect(width - edge, 0, width, height, INK)
    big = height // 12
    canvas.text(letter, width // 2, height // 2 - 7 * big // 2 - height // 16, big, WHITE)
    small = max(2, height // 60)
    canvas.text(label, width // 2, height // 2 + 7 * big // 2, small, WHITE)
    return canvas


def crest(letter, width, height, number):
    """A shield: a rounded plate with a white rim, the letter large and the crest's number small."""
    colours = COLOURS[letter]
    canvas = Canvas(width, height)
    cx, rx, ry = width / 2, width / 2 - 4, height / 2 - 4

    def plate(inset):
        def inside(x, y):
            dx, dy = abs(x - cx) / (rx - inset), (y - height / 2) / (ry - inset)
            return dx <= 1 and abs(dy) <= 1 and (dy < 0.3 or dx ** 2 + ((dy - 0.3) / 0.7) ** 2 <= 1)
        return inside
    canvas.shape(plate(0), WHITE)
    canvas.shape(plate(6), colours['mark'])
    big = height // 12
    canvas.text(letter, width // 2, height // 2 - 7 * big // 2 - height // 10, big, WHITE)
    canvas.text(str(number), width // 2, height // 2 + 7 * big // 2 - height // 10 + 6, 3, WHITE)
    return canvas


def marker(letter):
    """The player marker: a white-rimmed disc with the letter."""
    colours = COLOURS[letter]
    canvas = Canvas(64, 64)
    canvas.shape(lambda x, y: (x - 32) ** 2 + (y - 32) ** 2 <= 28 ** 2, WHITE)
    canvas.shape(lambda x, y: (x - 32) ** 2 + (y - 32) ** 2 <= 24 ** 2, (40, 160, 70, 255))
    canvas.text(letter, 32, 18, 4, WHITE)
    return canvas


def button(letter, number):
    """A 64 x 64 button picture: a dark square with a coloured rim, the letter and the button's number in the list,
    4 transparent pixels at every edge."""
    colours = COLOURS[letter]
    canvas = Canvas(BUTTON, BUTTON)
    canvas.rect(4, 4, 60, 60, colours['mark'])
    canvas.rect(8, 8, 56, 56, INK)
    canvas.text(letter, 32, 12, 3, WHITE)
    canvas.text(str(number), 32, 38, 2, WHITE)
    return canvas


def button_file(name):
    """The picture's path under art/, named as tools/cmf_button_sheet.py names its cut pictures."""
    return 'buttons/' + cmf_button_sheet.file_name('xbox', name)


def b_buttons():
    return [name for name in cmf_pack.BUTTON_NAMES if name.startswith('gamepad_')]


def art():
    """{pack: {path under art/: PNG bytes}}."""
    out = {'modCMFTestWorldA': {}, 'modCMFTestWorldB': {}}
    a, b = out['modCMFTestWorldA'], out['modCMFTestWorldB']
    a['world/painting.png'] = painting('A', *PAINTING, '2100x1380').png()
    for y in range(2):
        for x in range(2):
            b['world/painting_%dx%d.png' % (x, y)] = painting('B', *TILE, '%dx%d' % (x, y)).png()
    for number, region in enumerate(CRESTS_A, 1):
        a['world/crest_%s.png' % region] = crest('A', 136, 132 if region == 'kaer_morhen' else 116, number).png()
    for number, region in enumerate(CRESTS_B, 1):
        b['world/crest_%s.png' % region] = crest('B', 136, 116, number).png()
    a['world/marker_player.png'] = marker('A').png()
    for number, name in enumerate(cmf_pack.BUTTON_NAMES, 1):
        a[button_file(name)] = button('A', number).png()
        if name in b_buttons():
            b[button_file(name)] = button('B', number).png()
    return out


def write_art():
    written = []
    for pack, files in art().items():
        for name, data in sorted(files.items()):
            target = PROVIDERS/pack/'art'/name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            written.append(target)
    return written


def stage(out):
    out = Path(out)
    if out.exists():
        raise ValueError('output folder already exists; give a new one')
    lines = ['# Revision 9 test packs (probe only, never released)', '',
             'Built by `python tools/cmf_test_world.py stage` from `source/providers/modCMFTestWorldA` and '
             '`modCMFTestWorldB` (our own placeholder art, drawn by `tools/cmf_test_world.py`). Copy each `Mods` '
             'folder into the probe game folder. They need CMF 9 (1.3.0); on an older CMF the game stops at the '
             'script compile screen.', '', '| File | Bytes | SHA-256 |', '| --- | ---: | --- |']
    with tempfile.TemporaryDirectory() as scratch:
        for pack in PACKS:
            report, manifest = cmf_pack.build_pack(PROVIDERS/pack, Path(scratch)/pack)
            if report.errors or manifest is None:
                raise ValueError('%s: %s' % (pack, report.errors))
            shutil.copytree(Path(scratch)/pack/'Mods', out/'Mods', dirs_exist_ok=True)
            shutil.copy(Path(scratch)/pack/'pack-build.json', out/('%s-pack-build.json' % pack))
            for name, digest in sorted(manifest['files'].items()):
                lines.append('| `%s` | %d | `%s` |' % (name, (out/name).stat().st_size, digest))
        for pack in PACKS:
            record = out/('%s-pack-build.json' % pack)
            lines.append('| `%s` (the pack tool\'s build record) | %d | `%s` |' % (
                record.name, record.stat().st_size, hashlib.sha256(record.read_bytes()).hexdigest()))
    (out/'README.md').write_text('\n'.join(lines) + '\n', encoding='utf-8', newline='\n')
    return out/'README.md'


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('art')
    staged = sub.add_parser('stage')
    staged.add_argument('--out', required=True, help='new output folder')
    args = parser.parse_args()
    if args.command == 'art':
        for path in write_art():
            print(path.relative_to(ROOT))
    else:
        print(stage(args.out))


if __name__ == '__main__':
    main()
