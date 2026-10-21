"""Assemble the Stage 0 pin-field probe Mods tree (developer only).

Writes, under a new output directory:
  Mods/mod0000_ConjunctionMapFramework/content/{blob0.bundle,metadata.store}  (from a cmf_pin_panel build)
  Mods/mod0000_ConjunctionMapFramework/content/scripts/local/cmfCore.ws
  Mods/modCMFTestIconPack/content/texture.cache
  Mods/modCMFTestIconPack/content/scripts/local/cmfTestIconPack.ws
  Mods/modCMFTestIconPackB/content/{texture.cache,scripts/local/cmfTestIconPackB.ws}
  Mods/modCMFTestTintPack/content/scripts/local/cmfTestTintPack.ws
  Mods/modCMFTestBackgroundPack/content/{texture.cache,scripts/local/cmfTestBackgroundPack.ws}
  Mods/modCMFTestSignpostPack/content/scripts/local/cmfTestSignpostPack.ws
  Mods/modCMFTestCaseB/content/scripts/local/cmfTestCaseB.ws  (folder order, failed image)
  Mods/modcmfTestCaseA/content/scripts/local/cmfTestCaseA.ws  (generic registration)
  Mods/modCMFTestGearTint/content/scripts/local/cmfTestGearTint.ws  (Witcher Gear Map observation)
With --settings (a tools/cmf_settings_stage.py output) it also overlays CMF's string
tables, cmfSettings.ws and menu XML (under bin/config/...), checked against that
output's own hashes. Writes stage.json with SHA-256 of every file. Entry 1 of the test cache reuses the
engine-loaded S03b frame byte for byte; entry 2 is the CMF-owned signpost.
Never deploys or launches anything.
"""
import argparse
import hashlib
import json
from pathlib import Path

import cmf_cooked_codec
import cmf_test_icons
import cmf_texture_cache as cache

ROOT = Path(__file__).resolve().parents[1]
CORE = 'mod0000_ConjunctionMapFramework'
PACK = 'modCMFTestIconPack'
PACK_B = 'modCMFTestIconPackB'
TINT = 'modCMFTestTintPack'
BACKGROUND = 'modCMFTestBackgroundPack'
SIGNPOSTS = 'modCMFTestSignpostPack'
CASE_B = 'modCMFTestCaseB'
CASE_A = 'modcmfTestCaseA'
GEAR_TINT = 'modCMFTestGearTint'
BACKGROUND_ROOT = 'cmf_testbg'
BACKGROUND_LEVELS = range(5)
NOTICE_KEY = 'gameplay\\gui_new\\icons\\cmf_s03\\icon.png'
SIGNPOST_KEY = 'gameplay\\gui_new\\icons\\cmf_testpack\\signpost.png'
BADGE_KEY = 'gameplay\\gui_new\\icons\\modcmftesticonpackb\\badge.png'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def s03b_frame(data):
    """Return the single 64x64 entry frame of the S03b cache unchanged."""
    entries = cache.read_entries(data)
    need([(e[0], e[1], e[2]) for e in entries] == [(NOTICE_KEY, 64, 64)], 'not the S03b cache')
    page, size = cache.ENTRY.unpack_from(data, len(data) - cache.FOOTER.size - cache.ENTRY.size)[2:4]
    return data[page * cache.PAGE:page * cache.PAGE + size]


def test_pack_cache(s03b):
    signpost = cmf_cooked_codec.encode_bc3(cmf_test_icons.signpost_icon(), 64, 64)
    data = cache.build_cache([(NOTICE_KEY, 64, 64, s03b_frame(s03b)),
                              (SIGNPOST_KEY, 64, 64, cache.frame_bc3(signpost))])
    keys = [(e[0], e[1], e[2]) for e in cache.read_entries(data)]
    need(keys == [(NOTICE_KEY, 64, 64), (SIGNPOST_KEY, 64, 64)], 'cache readback mismatch')
    return data


def test_pack_b_cache():
    badge = cmf_cooked_codec.encode_bc3(cmf_test_icons.badge_icon(), 64, 64)
    data = cache.build_cache([(BADGE_KEY, 64, 64, cache.frame_bc3(badge))])
    need([(e[0], e[1], e[2]) for e in cache.read_entries(data)] == [(BADGE_KEY, 64, 64)], 'cache B readback mismatch')
    return data


def background_tiles():
    """(key, level, x, y) for levels 0..4 of the test root, in insertion order."""
    return [('gameplay\\gui_new\\maps\\%s\\level%d\\tile%dx%d.jpg' % (BACKGROUND_ROOT, level, x, y), level, x, y)
            for level in BACKGROUND_LEVELS for y in range(2 ** level) for x in range(2 ** level)]


def test_background_cache():
    tiles = background_tiles()
    data = cache.build_cache([(key, 1024, 1024, cache.frame_bc3(cmf_test_icons.background_tile_bc3(level, x, y)))
                              for key, level, x, y in tiles])
    need([e[0] for e in cache.read_entries(data)] == [t[0] for t in tiles], 'background cache readback mismatch')
    return data


def settings_overlay(settings, files):
    """Files of a cmf_settings_stage.py output, verified; shared files must equal ours."""
    settings = Path(settings)
    report = json.loads((settings/'settings-stage.json').read_text(encoding='utf-8'))
    need(report.get('schema') == 'cmf-settings-stage-1', 'not a settings stage output')
    overlay = {}
    for name, expected in report['files'].items():
        data = (settings/name).read_bytes()
        need(hashlib.sha256(data).hexdigest() == expected, 'settings file changed: ' + name)
        if name.startswith('Mods/'):
            mine = files.get(name[len('Mods/'):])
            need(mine is None or mine == data, 'settings output disagrees with source: ' + name)
        overlay[name] = data
    return overlay


def stage(panel, s03b_cache, out, settings=None):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    panel = Path(panel)
    build = json.loads((panel/'build.json').read_text(encoding='utf-8'))
    mods = out/'Mods'
    files = {
        CORE + '/content/blob0.bundle': (panel/'content/blob0.bundle').read_bytes(),
        CORE + '/content/metadata.store': (panel/'content/metadata.store').read_bytes(),
        CORE + '/content/scripts/local/cmfCore.ws':
            (ROOT/'source/core/content/scripts/local/cmfCore.ws').read_bytes(),
        PACK + '/content/texture.cache': test_pack_cache(Path(s03b_cache).read_bytes()),
        PACK + '/content/scripts/local/cmfTestIconPack.ws':
            (ROOT/'source/providers'/PACK/'content/scripts/local/cmfTestIconPack.ws').read_bytes(),
        PACK_B + '/content/texture.cache': test_pack_b_cache(),
        PACK_B + '/content/scripts/local/cmfTestIconPackB.ws':
            (ROOT/'source/providers'/PACK_B/'content/scripts/local/cmfTestIconPackB.ws').read_bytes(),
        TINT + '/content/scripts/local/cmfTestTintPack.ws':
            (ROOT/'source/providers'/TINT/'content/scripts/local/cmfTestTintPack.ws').read_bytes(),
        BACKGROUND + '/content/texture.cache': test_background_cache(),
        BACKGROUND + '/content/scripts/local/cmfTestBackgroundPack.ws':
            (ROOT/'source/providers'/BACKGROUND/'content/scripts/local/cmfTestBackgroundPack.ws').read_bytes(),
        SIGNPOSTS + '/content/scripts/local/cmfTestSignpostPack.ws':
            (ROOT/'source/providers'/SIGNPOSTS/'content/scripts/local/cmfTestSignpostPack.ws').read_bytes(),
        CASE_B + '/content/scripts/local/cmfTestCaseB.ws':
            (ROOT/'source/providers'/CASE_B/'content/scripts/local/cmfTestCaseB.ws').read_bytes(),
        CASE_A + '/content/scripts/local/cmfTestCaseA.ws':
            (ROOT/'source/providers'/CASE_A/'content/scripts/local/cmfTestCaseA.ws').read_bytes(),
        GEAR_TINT + '/content/scripts/local/cmfTestGearTint.ws':
            (ROOT/'source/providers'/GEAR_TINT/'content/scripts/local/cmfTestGearTint.ws').read_bytes(),
    }
    need(hashlib.sha256(files[CORE + '/content/blob0.bundle']).hexdigest() == build['bundle'], 'panel bundle hash')
    need(hashlib.sha256(files[CORE + '/content/metadata.store']).hexdigest() == build['metadata'], 'panel metadata hash')
    for name, data in files.items():
        if name.endswith('.ws'):
            need(b'\r' not in data and all(b < 128 for b in data), name + ' must be ASCII/LF')
        target = mods/name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    written = {'Mods/' + name: data for name, data in files.items()}
    if settings:
        for name, data in settings_overlay(settings, files).items():
            target = out/name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            written[name] = data
    report = {'schema': 'cmf-pin-stage-1', 'panel': build, 'settings': bool(settings),
              'files': {name: hashlib.sha256(data).hexdigest() for name, data in sorted(written.items())}}
    (out/'stage.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--panel', required=True, help='output directory of tools/cmf_pin_panel.py')
    parser.add_argument('--s03b-cache', required=True, help='engine-loaded S03b texture.cache')
    parser.add_argument('--settings', help='optional output directory of tools/cmf_settings_stage.py')
    parser.add_argument('--out', required=True, help='new output directory')
    args = parser.parse_args()
    print(json.dumps(stage(args.panel, args.s03b_cache, args.out, args.settings), indent=1))


if __name__ == '__main__':
    main()
