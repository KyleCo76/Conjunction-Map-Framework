"""Art and staging for the Cyberpunk-check test theme pack modCMFTestThemePack (developer only, no dependencies).

  python tools/cmf_test_theme.py art [--out source/providers/modCMFTestThemePack/art]
  python tools/cmf_test_theme.py stage --out <new folder>

art draws the pack's three quest icons (96x96, neon outlines on a dark face, 4 transparent pixels at every
edge). stage builds the pack with tools/cmf_pack.py and then adds the neon map art the pack registers with
CMFRegisterBackground: 341 tiles of 1024 px (levels 0 to 4, root cmf_testneon) cooked into the same
content/texture.cache beside the icons, the way the Stage 0 background pack's tiles were cooked. Writes
<out>/Mods/modCMFTestThemePack/... and <out>/pack-build.json with the SHA-256 of every file. All art is
CMF's own procedural geometry. Never deploys or launches anything.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

import cmf_pack
import cmf_texture_cache as cache
from cmf_test_icons import _bc3_flat, _inside

ROOT = Path(__file__).resolve().parents[1]
PACK = 'modCMFTestThemePack'
SOURCE = ROOT/'source/providers'/PACK
SIZE = 96
CLEAR = (0, 0, 0, 0)
CYAN = (0, 240, 255, 255)
MAGENTA = (255, 43, 214, 255)
YELLOW = (252, 238, 10, 255)
FACE = (10, 15, 26, 255)
NEON_ROOT = 'cmf_testneon'
NEON_LEVELS = range(5)


def _draw(colour_at):
    pixels = bytearray()
    for y in range(SIZE):
        for x in range(SIZE):
            pixels += bytes(colour_at(x, y))
    return bytes(pixels)


def _hexagon(radius):
    return [(48 + radius * math.cos(math.pi / 3 * i), 48 + radius * math.sin(math.pi / 3 * i)) for i in range(6)]


def _outlined(outer, inner, rim, core=None, core_colour=None):
    def at(x, y):
        if not _inside(outer, x, y):
            return CLEAR
        if not _inside(inner, x, y):
            return rim
        if core and _inside(core, x, y):
            return core_colour
        return FACE
    return _draw(at)


def quest_main():
    """Magenta hexagon outline with a cyan core."""
    return _outlined(_hexagon(44), _hexagon(36), MAGENTA, _hexagon(14), CYAN)


def quest_side():
    """Cyan hexagon outline with a magenta core."""
    return _outlined(_hexagon(40), _hexagon(33), CYAN, _hexagon(11), MAGENTA)


def quest_contract():
    """Yellow triangle outline with a cyan bar."""
    outer = [(48, 6), (90, 86), (6, 86)]
    inner = [(48, 22), (78, 79), (18, 79)]
    bar = [(44, 44), (52, 44), (52, 68), (44, 68)]
    return _outlined(outer, inner, YELLOW, bar, CYAN)


ART = {'quest_main.png': quest_main, 'quest_side.png': quest_side, 'quest_contract.png': quest_contract}


def neon_tile_bc3(size=1024):
    """The neon map tile (every tile is the same) as a single-mip BC3 stream: a near-black base, a cyan grid
    every 128 px, a magenta grid line every 512 px and a yellow mark in the centre. Built from flat 4x4 blocks."""
    blocks = size // 4
    base, cyan, magenta, yellow = (_bc3_flat(c[:3]) for c in ((6, 8, 16, 255), CYAN, MAGENTA, YELLOW))
    centre = blocks // 2
    out = bytearray()
    for by in range(blocks):
        for bx in range(blocks):
            if abs(bx - centre) <= 1 and abs(by - centre) <= 1:
                out += yellow
            elif bx % 128 == 0 or by % 128 == 0:
                out += magenta
            elif bx % 32 == 0 or by % 32 == 0:
                out += cyan
            else:
                out += base
    return bytes(out)


def neon_tiles():
    """(key, level, x, y) for levels 0..4 of the neon root, in insertion order."""
    return [('gameplay\\gui_new\\maps\\%s\\level%d\\tile%dx%d.jpg' % (NEON_ROOT, level, x, y), level, x, y)
            for level in NEON_LEVELS for y in range(2 ** level) for x in range(2 ** level)]


def stage(out):
    out = Path(out)
    report, manifest = cmf_pack.build_pack(SOURCE, out)
    if report.errors or manifest is None:
        raise ValueError('pack check failed: %s' % report.errors)
    name = 'Mods/%s/content/texture.cache' % PACK
    target = out/name
    icons = [(key, w, h, cache.frame_bc3(stream)) for key, w, h, stream in cache.read_entries(target.read_bytes())]
    tile = cache.frame_bc3(neon_tile_bc3())
    entries = icons + [(key, 1024, 1024, tile) for key, _, _, _ in neon_tiles()]
    data = cache.build_cache(entries)
    if [e[0] for e in cache.read_entries(data)] != [e[0] for e in entries]:
        raise ValueError('cache read-back mismatch')
    target.write_bytes(data)
    manifest['files'][name] = hashlib.sha256(data).hexdigest()
    manifest['background'] = {'root': NEON_ROOT, 'tiles': len(entries) - len(icons)}
    (out/'pack-build.json').write_text(json.dumps(manifest, indent=1) + '\n', encoding='utf-8', newline='\n')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest='command', required=True)
    art = sub.add_parser('art')
    art.add_argument('--out', default=str(SOURCE/'art'))
    staged = sub.add_parser('stage')
    staged.add_argument('--out', required=True, help='new output folder')
    args = parser.parse_args()
    if args.command == 'art':
        folder = Path(args.out)
        folder.mkdir(parents=True, exist_ok=True)
        for file_name, draw in ART.items():
            (folder/file_name).write_bytes(cmf_pack.write_png(SIZE, SIZE, draw()))
            print(folder/file_name)
    else:
        print(json.dumps(stage(args.out), indent=1))


if __name__ == '__main__':
    main()
