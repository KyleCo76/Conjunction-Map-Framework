"""The controller button sheet cutter (API version 9): geometry from the map movie, one picture per button.

No game files: a tiny FFDec-style movie and synthetic sheets stand in for the map file and its two sheets.
"""
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_button_sheet as sheet
import cmf_pack

# Two sheets, three cut-outs, one family clip (placed under all five family names) with three labelled frames:
# one plain picture, one two-piece picture (both halves overlap the box edge), one cut-out turned a quarter.
MOVIE = '''<swf><tags>
 <item type="DefineExternalImage2" fileName="panel-worldmap{3559ca43}_i1.dds" imageID="0" targetWidth="16" targetHeight="8"/>
 <item type="DefineExternalImage2" fileName="panel-worldmap{3559ca43}_i49.dds" imageID="1" targetWidth="12" targetHeight="4"/>
 <item type="DefineSubImage" characterID="10" imageId="1" x1="0" y1="0" x2="4" y2="4"/>
 <item type="DefineSubImage" characterID="11" imageId="1" x1="4" y1="0" x2="8" y2="4"/>
 <item type="DefineSubImage" characterID="12" imageId="0" x1="8" y1="4" x2="16" y2="8"/>
 <item type="DefineSpriteTag" spriteId="20" frameCount="1"><subTags>
  <item type="ShowFrameTag"/>
 </subTags></item>
 <item type="DefineSpriteTag" spriteId="30" frameCount="4"><subTags>
  <item type="FrameLabelTag" name="empty"/>
  <item type="PlaceObject3Tag" characterId="20" depth="1" name="holdIndicator" placeFlagHasCharacter="true" placeFlagHasName="true"/>
  <item type="ShowFrameTag"/>
  <item type="FrameLabelTag" name="gamepad_X"/>
  <item type="PlaceObject2Tag" characterId="10" depth="4" placeFlagHasCharacter="true" placeFlagHasMatrix="true">
   <matrix type="MATRIX" hasScale="false" hasRotate="false" translateX="-40" translateY="-40"/>
  </item>
  <item type="ShowFrameTag"/>
  <item type="RemoveObject2Tag" depth="4"/>
  <item type="FrameLabelTag" name="gamepad_RTLT"/>
  <item type="PlaceObject2Tag" characterId="10" depth="4" placeFlagHasCharacter="true" placeFlagHasMatrix="true">
   <matrix type="MATRIX" hasScale="false" hasRotate="false" translateX="-80" translateY="-40"/>
  </item>
  <item type="PlaceObject2Tag" characterId="11" depth="5" placeFlagHasCharacter="true" placeFlagHasMatrix="true">
   <matrix type="MATRIX" hasScale="false" hasRotate="false" translateX="0" translateY="-40"/>
  </item>
  <item type="ShowFrameTag"/>
  <item type="RemoveObject2Tag" depth="4"/>
  <item type="RemoveObject2Tag" depth="5"/>
  <item type="FrameLabelTag" name="gamepad_dpad_up_down"/>
  <item type="PlaceObject2Tag" characterId="12" depth="4" placeFlagHasCharacter="true" placeFlagHasMatrix="true">
   <matrix type="MATRIX" hasScale="true" scaleX="0" scaleY="0" hasRotate="true" rotateSkew0="1.0" rotateSkew1="-1.0" translateX="40" translateY="-80"/>
  </item>
  <item type="ShowFrameTag"/>
 </subTags></item>
 <item type="DefineSpriteTag" spriteId="40" frameCount="1"><subTags>
  <item type="PlaceObject2Tag" characterId="30" depth="1" name="mcIconXbox" placeFlagHasCharacter="true" placeFlagHasName="true"/>
  <item type="PlaceObject2Tag" characterId="30" depth="2" name="mcIconPS4" placeFlagHasCharacter="true" placeFlagHasName="true"/>
  <item type="PlaceObject2Tag" characterId="30" depth="3" name="mcIconPS5" placeFlagHasCharacter="true" placeFlagHasName="true"/>
  <item type="PlaceObject2Tag" characterId="30" depth="4" name="mcIconSteam" placeFlagHasCharacter="true" placeFlagHasName="true"/>
  <item type="PlaceObject2Tag" characterId="30" depth="5" name="mcIconSwitch" placeFlagHasCharacter="true" placeFlagHasName="true"/>
  <item type="ShowFrameTag"/>
 </subTags></item>
</tags></swf>'''

RED, GREEN, BLUE = (255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255)


def solid(width, height, regions):
    """RGBA of a sheet: transparent, with each (x1, y1, x2, y2, colour) filled."""
    out = bytearray(width * height * 4)
    for x1, y1, x2, y2, colour in regions:
        for y in range(y1, y2):
            for x in range(x1, x2):
                out[(y * width + x) * 4:(y * width + x) * 4 + 4] = bytes(colour)
    return bytes(out)


def pixel(rgba, width, x, y):
    return tuple(rgba[(y * width + x) * 4:(y * width + x) * 4 + 4])


class MapTests(unittest.TestCase):
    def setUp(self):
        self.result = sheet.Movie(MOVIE).button_map()

    def test_frames_become_cut_outs(self):
        xbox = self.result['families']['xbox']
        self.assertEqual(list(xbox), ['gamepad_X', 'gamepad_RTLT', 'gamepad_dpad_up_down'])
        self.assertEqual(xbox['gamepad_X'], [{'sheet': '_i49', 'x': 0, 'y': 0, 'w': 4, 'h': 4,
                                              'm': [1.0, 0.0, 0.0, 1.0, -2.0, -2.0]}])
        self.assertEqual([p['x'] for p in xbox['gamepad_RTLT']], [0, 4])
        self.assertEqual(xbox['gamepad_dpad_up_down'][0]['m'], [0.0, 1.0, -1.0, 0.0, 2.0, -4.0])
        # The hold ring and the empty frame are not pictures.
        self.assertNotIn('empty', xbox)
        self.assertEqual(self.result['sheets'], {'_i1': [16, 8], '_i49': [12, 4]})
        self.assertEqual(self.result['cutouts'], 3)
        self.assertEqual(sorted(self.result['families']), sorted(sheet.FAMILY_CLIPS))

    def test_dump_is_json(self):
        self.assertEqual(json.loads(sheet.dump_map(self.result)), json.loads(json.dumps(self.result)))

    def test_a_movie_without_a_family_clip_fails(self):
        with self.assertRaises(ValueError):
            sheet.Movie(MOVIE.replace('mcIconSteam', 'mcSomethingElse')).button_map()

    def test_covered_rectangle(self):
        xbox = self.result['families']['xbox']
        self.assertEqual(sheet.covered(xbox['gamepad_X']), (-2.0, -2.0, 2.0, 2.0))
        self.assertEqual(sheet.covered(xbox['gamepad_RTLT']), (-4.0, -2.0, 4.0, 2.0))
        self.assertEqual(sheet.picture_size(xbox['gamepad_RTLT']), (8, 4))


class CutTests(unittest.TestCase):
    def setUp(self):
        self.map = sheet.Movie(MOVIE).button_map()
        self.temp = tempfile.TemporaryDirectory()
        self.dir = Path(self.temp.name)
        # _i49: cut-out 10 red, 11 green; _i1: cut-out 12 blue on its left half, red on its right half.
        (self.dir/'i49.png').write_bytes(cmf_pack.write_png(12, 4, solid(12, 4, [(0, 0, 4, 4, RED), (4, 0, 8, 4, GREEN)])))
        (self.dir/'i1.png').write_bytes(cmf_pack.write_png(16, 8, solid(16, 8, [(8, 4, 12, 8, BLUE), (12, 4, 16, 8, RED)])))

    def tearDown(self):
        self.temp.cleanup()

    def cut(self, **extra):
        return sheet.cut(self.map, {'_i49': self.dir/'i49.png', '_i1': self.dir/'i1.png'}, 'modMyPack',
                         self.dir/'out', **extra)

    def picture(self, name):
        return cmf_pack.read_png((self.dir/'out/art/buttons'/name).read_bytes())

    def test_one_picture_per_button_and_its_line(self):
        lines = self.cut(families=['xbox'])
        self.assertEqual(lines[0], 'CMFRegisterButtonPicture("modMyPack", \'xbox\', "gamepad_X", '
                                   '"img://icons/modmypack/buttons/xbox_gamepad_x.png");')
        self.assertEqual(len(lines), 3)
        register = (self.dir/'out/register.ws').read_text(encoding='ascii')
        self.assertIn('CMFRequireVersion("modMyPack", 9)', register)
        self.assertTrue(all(line in register for line in lines))
        width, height, rgba = self.picture('xbox_gamepad_x.png')
        self.assertEqual((width, height), (4, 4))
        self.assertTrue(all(pixel(rgba, 4, x, y) == RED for x in range(4) for y in range(4)))

    def test_two_pieces_side_by_side(self):
        self.cut(families=['xbox'])
        width, height, rgba = self.picture('xbox_gamepad_rtlt.png')
        self.assertEqual((width, height), (8, 4))
        self.assertEqual(pixel(rgba, 8, 1, 1), RED)
        self.assertEqual(pixel(rgba, 8, 6, 2), GREEN)

    def test_quarter_turn(self):
        self.cut(families=['xbox'])
        width, height, rgba = self.picture('xbox_gamepad_dpad_up_down.png')
        # An 8 x 4 cut-out turned a quarter covers 4 x 8: its left (blue) half ends up on top.
        self.assertEqual((width, height), (4, 8))
        self.assertEqual(pixel(rgba, 4, 1, 1), BLUE)
        self.assertEqual(pixel(rgba, 4, 2, 6), RED)

    def test_every_family_by_default(self):
        self.assertEqual(len(self.cut()), 15)

    def test_wrong_sheet_size_fails(self):
        (self.dir/'i49.png').write_bytes(cmf_pack.write_png(8, 4, bytes(8 * 4 * 4)))
        with self.assertRaises(ValueError):
            self.cut()

    def test_missing_sheet_fails(self):
        with self.assertRaises(ValueError):
            sheet.cut(self.map, {'_i49': self.dir/'i49.png'}, 'modMyPack', self.dir/'out', families=['xbox'])

    def test_cut_pictures_build_into_a_pack(self):
        self.cut(families=['xbox'])
        pack = self.dir/'modMyPack'
        (pack/'content/scripts/local').mkdir(parents=True)
        (pack/'art').mkdir()
        (self.dir/'out/art/buttons').rename(pack/'art/buttons')
        lines = (self.dir/'out/register.ws').read_text(encoding='ascii').splitlines()[1:]
        (pack/'content/scripts/local/modmypack_cmf.ws').write_text(
            '@wrapMethod(CR4Game)\nfunction OnGameStarted(restored : bool)\n{\n\tvar result : bool;\n'
            '\tresult = wrappedMethod(restored);\n\tif (CMFRequireVersion("modMyPack", 9))\n\t{\n' +
            ''.join('\t\t%s\n' % line for line in lines) + '\t}\n\treturn result;\n}\n', encoding='ascii')
        (pack/'README.txt').write_text('test\n', encoding='ascii')
        report, plan = cmf_pack.check_pack(pack)
        self.assertEqual(report.errors, [])
        self.assertIn('buttons/xbox_gamepad_rtlt.png', plan['images'])
        self.assertEqual(plan['images']['buttons/xbox_gamepad_rtlt.png']['key'],
                         'gameplay\\gui_new\\icons\\modmypack\\buttons\\xbox_gamepad_rtlt.png')


class CommittedMapTests(unittest.TestCase):
    """tools/cmf_button_sheets.json, recorded from the 5.01 map file."""

    @classmethod
    def setUpClass(cls):
        cls.map = json.loads(sheet.MAP.read_text(encoding='utf-8'))

    def test_families_and_buttons(self):
        families = self.map['families']
        self.assertEqual(sorted(families), sorted(cmf_pack.BUTTON_FAMILIES))
        for family, buttons in families.items():
            expected = [b for b in cmf_pack.BUTTON_NAMES
                        if family != 'steam' or b not in cmf_pack.BUTTON_NAMES_NOT_STEAM]
            self.assertEqual(sorted(buttons), sorted(expected), family)

    def test_sheets_used_per_family(self):
        used = {f: sorted(set(p['sheet'] for pieces in b.values() for p in pieces))
                for f, b in self.map['families'].items()}
        self.assertEqual(used, {'xbox': ['_i1', '_i49'], 'ps4': ['_i49'], 'ps5': ['_i49'], 'steam': ['_i49'],
                                'switch': ['_i1', '_i49']})
        self.assertEqual(self.map['sheets'], {'_i1': [1024, 1020], '_i49': [988, 544]})

    def test_geometry_only(self):
        for buttons in self.map['families'].values():
            for pieces in buttons.values():
                for piece in pieces:
                    self.assertEqual(sorted(piece), ['h', 'm', 'sheet', 'w', 'x', 'y'])
                    width, height = self.map['sheets'][piece['sheet']]
                    self.assertLessEqual(piece['x'] + piece['w'], width)
                    self.assertLessEqual(piece['y'] + piece['h'], height)

    def test_pictures_fit_the_cap(self):
        for buttons in self.map['families'].values():
            for pieces in buttons.values():
                width, height = sheet.picture_size(pieces)
                self.assertTrue(4 <= width <= 128 and 4 <= height <= 128 and width % 4 == height % 4 == 0)


if __name__ == '__main__':
    unittest.main()
