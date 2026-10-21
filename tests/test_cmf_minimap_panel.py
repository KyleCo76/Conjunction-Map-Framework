"""Minimap panel tooling: patch set, minimap script and minimap-depot packaging.

The fixture case reads the ignored pinned vanilla hud_minimap2.redswf and skips
when it is absent; a skipped case is not qualification.
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

VANILLA = ROOT/'build/minimap/hud_minimap2.redswf'


class SourceTests(unittest.TestCase):
    def setUp(self):
        self.edits = json.loads(minimap.EDITS.read_text(encoding='utf-8'))
        self.script = minimap.SCRIPT.read_bytes()

    def test_edits_cover_exactly_three_minimap_classes(self):
        self.assertEqual(self.edits['schema'], 'cmf-panel-edits-1')
        self.assertEqual(self.edits['depot'], 'gameplay\\gui_new\\swf\\hud\\hud_minimap2.redswf')
        self.assertEqual(sorted(self.edits['classes']), [
            'red/game/witcher3/hud/modules/HudModuleMinimap2.as',
            'red/game/witcher3/hud/modules/minimap2/CommonMap.as',
            'red/game/witcher3/hud/modules/minimap2/MapPin.as'])
        for changes in self.edits['classes'].values():
            for change in changes:
                self.assertEqual(change['count'], 1)
                self.assertNotEqual(change['find'], change['replace'])
                self.assertNotIn('\r', change['find'] + change['replace'])

    def test_panel_functions_match_script_calls(self):
        hud = ''.join(c['replace'] for c in self.edits['classes']['red/game/witcher3/hud/modules/HudModuleMinimap2.as'])
        for name in re.findall(r'GetMemberFlashFunction\("([A-Za-z]+)"\)', self.script.decode('ascii')):
            self.assertIn('public function %s(' % name, hud)
        self.assertIn('param3:int', hud)

    def test_pooled_pins_reset_before_release(self):
        pin = self.edits['classes']['red/game/witcher3/hud/modules/minimap2/MapPin.as']
        deinit = [c for c in pin if 'OnDeinitialize' in c['find']]
        self.assertEqual(len(deinit), 1)
        self.assertTrue(deinit[0]['replace'].endswith('this.CMFResetStyle();\n'))

    def test_script_is_ascii_lf_and_lists_sorted_base_types(self):
        self.assertNotIn(b'\r', self.script)
        self.assertTrue(all(b < 128 for b in self.script))
        types = minimap.script_pin_types(self.script.decode('ascii'))
        self.assertEqual(len(types), 101)
        self.assertEqual(types, sorted(set(types)))
        self.assertFalse([t for t in types if re.search(r'_[0-9]+$', t)])
        for word in ('entry', 'property'):
            self.assertIsNone(re.search(r'\bvar %s\b' % word, self.script.decode('ascii')))


class PackageTests(unittest.TestCase):
    def test_minimap_depot_package_layout_and_extraction(self):
        depot = json.loads(minimap.EDITS.read_text(encoding='utf-8'))['depot']
        resource = b'CR2W' + bytes(range(256)) * 40
        bundle = minimap.make_bundle(resource, depot)
        metadata = minimap.make_metadata(bundle, depot)
        self.assertEqual(cmf_panel.read_package(bundle, metadata, depot)['layout'], 'PASS')
        with self.assertRaises(ValueError):
            cmf_panel.read_package(bundle, metadata)
        offset, size, packed = struct.unpack_from('<QII', bundle, 32 + 272)
        self.assertEqual(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size), resource)


class FixtureTests(unittest.TestCase):
    @unittest.skipUnless(VANILLA.exists(), 'ignored pinned vanilla hud_minimap2.redswf absent')
    def test_reads_pinned_vanilla_resource(self):
        edits = json.loads(minimap.EDITS.read_text(encoding='utf-8'))
        data = VANILLA.read_bytes()
        self.assertEqual(minimap.sha(data), edits['vanillaRedswfSha256'])
        parts = minimap.read_resource(data)
        self.assertEqual(minimap.sha(parts['movie']), edits['vanillaMovieSha256'])
        self.assertEqual(cmf_panel.read_movie(parts['movie'])['tailSha256'], edits['vanillaMovieTailSha256'])
        minimap.compare_resources(parts, minimap.read_resource(data), parts['movie'])


if __name__ == '__main__':
    unittest.main()
