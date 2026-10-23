"""Revision 9 (CMF 1.3.0) pictures in the pack tool, and the two test world packs (probe only, never released)."""
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_cooked_codec
import cmf_pack
import cmf_test_world

PROVIDERS = ROOT/'source/providers'
HEAD = ('@wrapMethod(CR4Game)\nfunction OnGameStarted(restored : bool)\n{\n\tvar result : bool;\n'
        '\tresult = wrappedMethod(restored);\n\tif (CMFRequireVersion("modMyPack", 9))\n\t{\n')
TAIL = '\t}\n\treturn result;\n}\n'


def blank(width, height, alpha=255):
    return cmf_pack.write_png(width, height, bytes((10, 20, 30, alpha)) * (width * height))


class PackToolTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.pack = Path(self.temp.name)/'modMyPack'
        (self.pack/'content/scripts/local').mkdir(parents=True)
        (self.pack/'art/world').mkdir(parents=True)
        (self.pack/'art/buttons').mkdir()
        (self.pack/'README.txt').write_text('test\n', encoding='ascii')

    def tearDown(self):
        self.temp.cleanup()

    def check(self, body, art=None):
        for name, data in (art or {}).items():
            (self.pack/'art'/name).write_bytes(data)
        (self.pack/'content/scripts/local/modmypack_cmf.ws').write_text(HEAD + body + TAIL, encoding='ascii')
        return cmf_pack.check_pack(self.pack)

    def test_world_and_button_pictures_any_shape(self):
        report, plan = self.check(
            '\t\tCMFRegisterWorldPainting("modMyPack", "img://icons/modmypack/world/painting.png");\n'
            '\t\tCMFRegisterWorldCrest("modMyPack", \'kaer_morhen\', "img://icons/modmypack/world/crest.png");\n'
            '\t\tCMFRegisterButtonPicture("modMyPack", \'xbox\', "gamepad_RTLT", '
            '"img://icons/modmypack/buttons/rtlt.png");\n',
            {'world/painting.png': blank(212, 140), 'world/crest.png': blank(136, 132),
             'buttons/rtlt.png': blank(100, 64)})
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertEqual(plan['images']['world/painting.png']['size'], [212, 140])
        self.assertEqual(plan['images']['world/crest.png']['key'],
                         'gameplay\\gui_new\\icons\\modmypack\\world\\crest.png')
        self.assertEqual(plan['images']['buttons/rtlt.png']['url'], 'img://icons/modmypack/buttons/rtlt.png')
        self.assertIn('content/texture.cache', plan['files'])

    def test_picture_sizes(self):
        report, _ = self.check('', {'world/odd.png': blank(135, 116), 'buttons/big.png': blank(132, 64)})
        self.assertTrue(any('art/world/odd.png' in e and 'multiple of 4' in e for e in report.errors), report.errors)
        self.assertTrue(any('art/buttons/big.png' in e and 'up to 128' in e for e in report.errors), report.errors)

    def test_tiles_need_every_tile(self):
        art = {'world/tile_0x0.png': blank(8, 8), 'world/tile_1x0.png': blank(8, 8), 'world/tile_0x1.png': blank(8, 8)}
        report, _ = self.check('\t\tCMFRegisterWorldPaintingTiles("modMyPack", '
                               '"img://icons/modmypack/world/tile_{x}x{y}.png", 2, 2);\n', art)
        self.assertEqual(report.errors, ['content/scripts/local/modmypack_cmf.ws:8: img://icons/modmypack/world/tile_1x1.png '
                                         'has no image in art/ (the map would keep the game\'s picture)'])

    def test_named_call_targets(self):
        report, _ = self.check(
            '\t\tCMFRegisterWorldPaintingTiles("modMyPack", "img://icons/modmypack/world/t.png", 9, 1);\n'
            '\t\tCMFRegisterWorldMarker("modMyPack", \'boss\', "");\n'
            '\t\tCMFRegisterButtonPicture("modMyPack", \'gamecube\', "gamepad_X", "");\n'
            '\t\tCMFRegisterButtonPicture("modMyPack", \'xbox\', "gamepad_x", "");\n'
            '\t\tCMFRegisterButtonPicture("modMyPack", \'steam\', "gamepad_dpad_all", "");\n'
            '\t\tCMFRegisterWorldCrest("modMyPack", \'Skellige\', "");\n'
            '\t\tCMFRegisterWorldCrest("modOther", \'skellige\', "");\n'
            '\t\tCMFRegisterChoiceOnly("modMyPack", "painting crests");\n'
            '\t\tCMFSetOpeningView("modOther", \'\', 0, 0, 0, true);\n'
            '\t\tCMFSetOpeningWorld("modOther", \'\', 0, 0, 0);\n')
        errors, warnings = ' | '.join(report.errors), ' | '.join(report.warnings)
        self.assertIn('tiles 9 x 1', errors)
        self.assertIn('must hold {x} and {y}', errors)
        self.assertIn('"boss" must be player or quest', errors)
        self.assertIn("'gamecube' is not a controller family", errors)
        self.assertIn('provider "modOther" must be the pack folder name', errors)
        self.assertIn('"painting crests" is not a choice key', errors)
        self.assertIn('CMFSetOpeningView names provider "modOther"', errors)
        self.assertIn('CMFSetOpeningWorld names provider "modOther"', errors)
        self.assertIn("did you mean 'gamepad_X'", errors)
        self.assertIn("the steam family has no 'gamepad_dpad_all' picture", errors)
        self.assertIn("did you mean 'skellige'", warnings)

    def test_empty_url_withdraws(self):
        report, _ = self.check('\t\tCMFRegisterWorldPainting("modMyPack", "");\n'
                               '\t\tCMFRegisterWorldMarker("modMyPack", \'player\', "");\n')
        self.assertEqual((report.errors, report.warnings), ([], []))

    def test_a_crest_for_a_region_another_mod_adds(self):
        report, _ = self.check('\t\tCMFRegisterWorldCrest("modMyPack", \'AN_MyIsland\', '
                               '"img://icons/modmypack/world/c.png");\n', {'world/c.png': blank(136, 116)})
        self.assertEqual(report.errors, [])
        self.assertTrue(any('region another mod adds' in w for w in report.warnings))

    def test_bc3_blocks_are_encoded_once(self):
        # A repeated block encodes to the same bytes as encoding every block on its own.
        rgba = bytearray()
        for y in range(16):
            for x in range(16):
                rgba += bytes(((x // 4) * 60, (y // 4) * 60, (x * y) % 256 if x > 11 else 0, 255 if y < 12 else x * 16))
        rgba = bytes(rgba)
        expected = b''.join(cmf_cooked_codec._block([tuple(rgba[((by + dy) * 16 + bx + dx) * 4:
                                                                 ((by + dy) * 16 + bx + dx) * 4 + 4])
                                                     for dy in range(4) for dx in range(4)])
                            for by in range(0, 16, 4) for bx in range(0, 16, 4))
        self.assertEqual(cmf_cooked_codec.encode_bc3(rgba, 16, 16), expected)


class TestWorldPackTests(unittest.TestCase):
    """modCMFTestWorldA and modCMFTestWorldB, as the build contract's section 6 lists them."""

    def check(self, pack):
        report, plan = cmf_pack.check_pack(PROVIDERS/pack)
        self.assertEqual((report.errors, report.warnings), ([], []))
        code = cmf_pack.strip_comments((PROVIDERS/pack/('content/scripts/local/%s_cmf.ws' % pack.lower()))
                                       .read_text(encoding='ascii'))
        return plan, code

    def test_pack_a(self):
        plan, code = self.check('modCMFTestWorldA')
        claims = plan['claims']
        self.assertEqual([c['target'] for c in claims if c['kind'] == 'painting'], ['painting'])
        self.assertEqual([c['target'] for c in claims if c['kind'] == 'crest'],
                         ['kaer_morhen', 'skellige', 'novigrad', 'no_mans_land', 'wyzima_castle', 'bob'])
        self.assertEqual([c['target'] for c in claims if c['kind'] == 'marker'], ['player'])
        self.assertEqual([c['target'] for c in claims if c['kind'] == 'button'],
                         ['xbox:' + b for b in cmf_pack.BUTTON_NAMES])
        self.assertEqual(plan['images']['world/painting.png']['size'], [2100, 1380])
        self.assertIn('CMFRegisterHidden("modCMFTestWorldA", \'Player\', \'GlobalMap\', "", true);', code)
        self.assertIn('CMFRequireVersion("modCMFTestWorldA", 9)', code)
        # The view hooks: wrappedMethod first, the log line, and the kept view handed back with keepPlace false.
        self.assertRegex(code, r'@wrapMethod\(CMFCore\)\nfunction OnMapView\(menu : CR4MapMenu, area : name, x : float, '
                               r'y : float, worldX : float, worldY : float, zoom : float, reason : name\)\n\{\n\tvar i : int;'
                               r'\n\twrappedMethod\(menu, area, x, y, worldX, worldY, zoom, reason\);')
        self.assertRegex(code, r'@wrapMethod\(CMFCore\)\nfunction OnMapOpening\(menu : CR4MapMenu, area : name, '
                               r'mapContext : name\)\n\{\n\tvar i : int;\n\twrappedMethod\(menu, area, mapContext\);')
        self.assertIn('"CMF test world A view area=" + NameToString(area) + " reason=" + NameToString(reason)', code)
        self.assertRegex(code, r'CMFSetOpeningView\("modCMFTestWorldA", area, modCMFTestWorldAX\[i\], '
                               r'modCMFTestWorldAY\[i\], modCMFTestWorldAZoom\[i\],\s+false\);')
        # Session only: plain fields, never saved.
        self.assertNotIn('saved', code)

    def test_pack_b(self):
        plan, code = self.check('modCMFTestWorldB')
        claims = plan['claims']
        tiles = [c for c in claims if c['kind'] == 'tiles']
        self.assertEqual([(c['columns'], c['rows']) for c in tiles], [(2, 2)])
        self.assertEqual([c['target'] for c in claims if c['kind'] == 'crest'],
                         ['skellige', 'novigrad', 'bob', 'prolog_village'])
        self.assertEqual([c['target'] for c in claims if c['kind'] == 'button'],
                         ['xbox:' + b for b in cmf_pack.BUTTON_NAMES if b.startswith('gamepad_')])
        self.assertFalse([c for c in claims if c['kind'] in ('painting', 'marker')])
        for x in (0, 1):
            for y in (0, 1):
                self.assertEqual(plan['images']['world/painting_%dx%d.png' % (x, y)]['size'], [1052, 692])
        # Choice-only covers every claim of the crests piece, so it comes before them.
        self.assertLess(code.index('CMFRegisterChoiceOnly("modCMFTestWorldB", "Painting_Crests");'),
                        code.index('CMFRegisterWorldCrest('))
        # The opening view on Geralt's place for his own region, withdrawn for the others, game's zoom kept.
        self.assertRegex(code, r'@wrapMethod\(CMFCore\)\nfunction OnMapOpening\(menu : CR4MapMenu, area : name, '
                               r'mapContext : name\)\n\{\n\tvar spot : Vector;\n\twrappedMethod\(menu, area, mapContext\);')
        self.assertIn('if (menu && menu.IsCurrentAreaShown())', code)
        self.assertIn('CMFSetOpeningWorld("modCMFTestWorldB", area, spot.X, spot.Y, 0);', code)
        self.assertIn('CMFSetOpeningView("modCMFTestWorldB", area, 0, 0, 0, true);', code)

    def test_art_is_current(self):
        drawn = cmf_test_world.art()
        for pack, files in drawn.items():
            on_disk = sorted(p.relative_to(PROVIDERS/pack/'art').as_posix()
                             for p in (PROVIDERS/pack/'art').rglob('*.png'))
            self.assertEqual(on_disk, sorted(files), pack)
            for name, data in files.items():
                self.assertEqual((PROVIDERS/pack/'art'/name).read_bytes(), data,
                                 '%s/art/%s is out of date: run python tools/cmf_test_world.py art' % (pack, name))

    def test_crest_sizes(self):
        for pack in cmf_test_world.PACKS:
            for path in (PROVIDERS/pack/'art/world').glob('crest_*.png'):
                width, height, _ = cmf_pack.read_png(path.read_bytes())
                self.assertEqual((width, height), (136, 132) if 'kaer_morhen' in path.name else (136, 116))

    def test_test_packs_stay_out_of_player_packages(self):
        for pack in cmf_test_world.PACKS:
            readme = (PROVIDERS/pack/'README.txt').read_text(encoding='ascii')
            self.assertIn('TEST ONLY', readme)
            for folder in ('dist', 'previews', 'payload'):
                hits = [p for p in (ROOT/folder).rglob('*') if pack.lower() in p.name.lower()] \
                    if (ROOT/folder).is_dir() else []
                self.assertEqual(hits, [], folder)
        self.assertFalse(re.search(r'modCMFTestWorld', (ROOT/'tools/cmf_package.py').read_text(encoding='utf-8')))


if __name__ == '__main__':
    unittest.main()
