"""Minimap add-on tooling: add-on movie class, minimap script and add-on depot packaging.

The fixture case reads the ignored game hud_watermark.redswf and skips when it is
absent; a skipped case is not qualification.
"""
import json
from pathlib import Path
import re
import struct
import sys
import unittest

import lz4.block

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_minimap_panel as minimap
import cmf_panel

BASE = ROOT/'build/minimap/hud_watermark.redswf'


class SourceTests(unittest.TestCase):
    def setUp(self):
        self.pins = json.loads(minimap.PINS.read_text(encoding='utf-8'))
        self.script = minimap.SCRIPT.read_bytes().decode('ascii')
        self.movie = minimap.CLASS_SOURCE.read_bytes().decode('ascii')

    def test_addon_replaces_no_game_file(self):
        self.assertEqual(self.pins['schema'], 'cmf-minimap-overlay-1')
        self.assertEqual(self.pins['depot'], 'gameplay\\gui_new\\swf\\hud\\hud_pickeditemsinfo.redswf')
        self.assertNotEqual(self.pins['depot'], self.pins['minimapDepot'])
        self.assertNotEqual(self.pins['depot'], self.pins['baseDepot'])
        self.assertEqual(self.pins['class'], 'red/game/witcher3/hud/modules/HudModuleWatermark.as')
        self.assertIn('return "PickedItemsInfoModule";', self.movie)
        self.assertIn('CreateHudModule("PickedItemsInfoModule")', self.script)
        self.assertIn("hudModulesNames.Contains('PickedItemsInfoModule')", self.script)

    def test_script_wraps_and_never_replaces(self):
        self.assertNotIn('@replaceMethod', self.script)
        self.assertNotIn('CR4HudModuleMinimap2', self.script)
        for wrapped in re.findall(r'@wrapMethod\((\w+)\)\nfunction (\w+)\(', self.script):
            self.assertIn(wrapped, [('CR4ScriptedHud', 'OnConfigUI'), ('CR4HudModulePickedItemsInfo', 'OnConfigUI'),
                                    ('CR4HudModulePickedItemsInfo', 'OnTick')])
        self.assertEqual(self.script.count('wrappedMethod('), 3)

    def test_movie_defines_every_function_the_script_calls(self):
        names = re.findall(r'GetMemberFlashFunction\("([A-Za-z]+)"\)', self.script)
        self.assertEqual(sorted(names), ['CMFApplyTypeStyles', 'CMFClearTypeStyles', 'CMFSetTypeStyle', 'CMFTick'])
        for name in names:
            self.assertIn('public function %s(' % name, self.movie)
        for event in re.findall(r'GameEvent\.CALL,"(\w+)"', self.movie):
            self.assertTrue(event == 'OnConfigUI' or ('event %s(' % event) in self.script, event)

    def test_movie_touches_only_what_it_adds(self):
        # On a pin's own icon the add-on writes only its mask and colour transform; everything else it
        # writes belongs to objects it created (its layer, loader and mask shape) or to its own movie.
        assign = r'^\s*([\w.\[\]"]+)\s*=(?!=)'
        apply = self.movie[self.movie.index('private function cmfApplyPin('):self.movie.index('private function cmfRecordOfLoader(')]
        icon_targets = [t for t in re.findall(assign, self.movie, re.M) if '.icon.' in t]
        icon_targets += [t for t in re.findall(assign, apply, re.M) if t.startswith('param2.')]
        self.assertTrue(icon_targets)
        for target in icon_targets:
            self.assertRegex(target, r'(\.mask|\.transform\.colorTransform)$')
        self.assertNotIn('gotoAndStop', self.movie)
        self.assertIn('param1.icon.mask == param1.mask', self.movie)
        self.assertIn('_loc2_.icon.mask == null', self.movie)
        self.assertEqual(self.movie.count('removeChild('), 1)
        self.assertIn('param1.layer.parent.removeChild(param1.layer)', self.movie)

    def test_sources_are_ascii_lf_and_list_sorted_base_types(self):
        for text in (self.script, self.movie):
            self.assertNotIn('\r', text)
        types = minimap.script_pin_types(self.script)
        self.assertEqual(len(types), 101)
        self.assertEqual(types, sorted(set(types)))
        self.assertFalse([t for t in types if re.search(r'_[0-9]+$', t)])
        for word in ('entry', 'property'):
            self.assertIsNone(re.search(r'\bvar %s\b' % word, self.script))


class PackageTests(unittest.TestCase):
    def test_addon_depot_package_layout_and_extraction(self):
        depot = json.loads(minimap.PINS.read_text(encoding='utf-8'))['depot']
        resource = b'CR2W' + bytes(range(256)) * 40
        bundle = minimap.make_bundle(resource, depot)
        metadata = minimap.make_metadata(bundle, depot)
        self.assertEqual(cmf_panel.read_package(bundle, metadata, depot)['layout'], 'PASS')
        with self.assertRaises(ValueError):
            cmf_panel.read_package(bundle, metadata)
        offset, size, packed = struct.unpack_from('<QII', bundle, 32 + 272)
        self.assertEqual(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size), resource)


class FixtureTests(unittest.TestCase):
    @unittest.skipUnless(BASE.exists(), 'ignored game hud_watermark.redswf absent')
    def test_reads_pinned_base_resource(self):
        pins = json.loads(minimap.PINS.read_text(encoding='utf-8'))
        data = BASE.read_bytes()
        self.assertEqual(minimap.sha(data), pins['baseRedswfSha256'])
        parts = minimap.read_resource(data)
        self.assertEqual(minimap.sha(parts['movie']), pins['baseMovieSha256'])
        self.assertEqual(cmf_panel.read_movie(parts['movie'])['tailSha256'], pins['baseMovieTailSha256'])
        self.assertEqual(parts['texture'], b'')
        minimap.compare_resources(parts, minimap.read_resource(data), parts['movie'])

    @unittest.skipUnless(BASE.exists(), 'ignored game hud_watermark.redswf absent')
    def test_drops_only_the_empty_address_import_and_its_text(self):
        movie = minimap.read_resource(BASE.read_bytes())['movie']
        before = cmf_panel.read_movie(movie)
        self.assertIn(b'\0\x01\0\0\0', [t['payload'] for t in before['tags'] if t['code'] == 71])
        after = cmf_panel.read_movie(minimap.drop_unused_text(movie))
        self.assertEqual([t for t in before['tags'] if t['code'] not in minimap.UNUSED_TEXT_TAGS], after['tags'])
        self.assertFalse([t for t in after['tags'] if t['code'] in (57, 71, 37)])
        self.assertEqual(after['tail'], before['tail'])
        # read_movie requires End exactly at the declared length, so the new FileLength is checked there.
        self.assertLess(after['declared'], before['declared'] - 216)
        with self.assertRaises(ValueError):
            minimap.drop_unused_text(minimap.drop_unused_text(movie))


if __name__ == '__main__':
    unittest.main()
