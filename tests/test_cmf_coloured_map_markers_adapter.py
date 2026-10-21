"""Coloured Map Markers adapter: art, registrations against the 5.01 pin types, credit and the pack build.

The art is Coloured Map Markers' own Shape icons by DJ_Kovrik (Nexus 938, maintained by LewisElementary), shared
in its misc file "CMM Shapes - Remastered" 1.60 for other mods to use with credit. The shape-to-type table lives
in tools/cmf_coloured_map_markers_art.js and was read from the 5.01 pin glyph sprite (PinIcon_122) frame labels.
These are static checks; nothing here ran in game.
"""
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack
import cmf_pin_types
import cmf_texture_cache as cache

PACK = ROOT/'source/adapters/coloured-map-markers/modCMFAdapterColouredMapMarkers'
SCRIPT = PACK/'content/scripts/local/modcmfadaptercolouredmapmarkers_cmf.ws'
ART_TOOL = ROOT/'tools/cmf_coloured_map_markers_art.js'
# Claims use the adapted mod's folder name (N4 spec 7.3), as the other adapters do.
PROVIDER = 'modcoloured_map_marker'


def shape_table():
    """pin type -> shape id, from the art tool's SHAPES object."""
    text = ART_TOOL.read_text(encoding='utf-8')
    block = text[text.index('const SHAPES = {'):text.index('};', text.index('const SHAPES = {'))]
    return {name: int(number) for name, number in re.findall(r'(\w+): (\d+)', block)}


def file_for(name):
    name = 'PlayerStash' if name == 'PlayerStashDiscoverable' else name
    return re.sub(r'([a-z])([A-Z])', r'\1_\2', name).lower() + '.png'


class ColouredMapMarkersAdapterTests(unittest.TestCase):
    def test_every_type_is_a_drawn_5_01_type(self):
        known = cmf_pin_types.known_types()
        for name in shape_table():
            self.assertIn(name, known, name)
            self.assertEqual(known[name]['reach'], 'yes', name)
            self.assertTrue(known[name]['art'], name)

    def test_art_is_one_96_picture_per_shape(self):
        table = shape_table()
        self.assertEqual(len(table), 61)
        # Only PlayerStash and PlayerStashDiscoverable share a shape (374), and so one picture.
        self.assertEqual(len(set(table.values())), 60)
        self.assertEqual(sorted(p.name for p in (PACK/'art').iterdir()), sorted({file_for(t) for t in table}))
        for path in sorted((PACK/'art').iterdir()):
            report = cmf_pack.Report()
            self.assertEqual(cmf_pack.check_art(path.name, path.read_bytes(), report)[:2], (96, 96), path.name)
            self.assertEqual(report.errors, [], path.name)

    def test_one_icon_per_type_under_coloured_map_markers_folder_name(self):
        report, plan = cmf_pack.check_pack(PACK, adapts=PROVIDER)
        self.assertEqual(report.errors, [])
        icons = {c['target']: c['url'] for c in plan['claims'] if c['kind'] == 'icon'}
        self.assertEqual(icons, {t: 'img://icons/modcmfadaptercolouredmapmarkers/' + file_for(t) for t in shape_table()})
        self.assertEqual({c['kind'] for c in plan['claims']}, {'icon'})
        code = cmf_pack.strip_comments(SCRIPT.read_text())
        self.assertEqual(set(re.findall(r'CMF\w+\(\s*"(\w+)"', code)), {PROVIDER})
        self.assertIn('CMFRequireVersion("modcoloured_map_marker", 1)', code)

    def test_credit_names_the_artist_the_mod_and_the_permission(self):
        for path in (PACK/'README.txt', SCRIPT):
            text = ' '.join(path.read_text(encoding='ascii').split())
            for words in ('DJ_Kovrik', 'Coloured Map Markers', 'LewisElementary', 'You have permission as long as '
                          'you credit DJ_Kovrik and the mod'):
                self.assertIn(words, text, '%s: %s' % (path.name, words))
        readme = (PACK/'README.txt').read_text(encoding='ascii')
        self.assertIn('https://www.nexusmods.com/witcher3/mods/938', readme)
        self.assertNotIn('every map mod', readme.lower())

    def test_adapter_builds(self):
        with tempfile.TemporaryDirectory() as out:
            out = Path(out)/'build'
            report, manifest = cmf_pack.build_pack(PACK, out, adapts=PROVIDER)
            self.assertEqual(report.errors, [])
            pack = out/'Mods/modCMFAdapterColouredMapMarkers'
            entries = cache.read_entries((pack/'content/texture.cache').read_bytes())
            self.assertEqual(sorted((e[0], e[1], e[2]) for e in entries),
                             sorted(('gameplay\\gui_new\\icons\\modcmfadaptercolouredmapmarkers\\' + p.name, 96, 96)
                                    for p in (PACK/'art').iterdir()))
            self.assertEqual(sorted(manifest['files']), sorted(
                'Mods/modCMFAdapterColouredMapMarkers/' + n for n in
                ('README.txt', 'content/texture.cache', 'content/scripts/local/modcmfadaptercolouredmapmarkers_cmf.ws')))


if __name__ == '__main__':
    unittest.main()
