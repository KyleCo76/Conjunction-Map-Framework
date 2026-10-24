"""Icon pack kit: PNG reader, art checks, script checks, pack build and the pin type list.

The vanilla-panel case reads the ignored pinned reference panel and skips when it is
absent; a skipped case is not qualification.
"""
import json
from pathlib import Path
import re
import shutil
import struct
import sys
import tempfile
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_example_art
import cmf_pack
import cmf_pin_types
import cmf_test_theme
import cmf_texture_cache as cache

EXAMPLE = ROOT/'examples/modCMFExampleIconPack'
PROVIDERS = ROOT/'source/providers'


def png(width, height, colour, depth, rows, palette=b'', trns=b'', filters=None):
    """Hand-built PNG; rows are raw scanline bytes, optionally filtered with the given filter types."""
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    step = max(1, {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colour] * depth // 8)
    raw, previous = b'', bytes(len(rows[0]))
    for index, line in enumerate(rows):
        kind = filters[index % len(filters)] if filters else 0
        out = bytearray()
        for i, value in enumerate(line):
            a = line[i - step] if i >= step else 0
            b = previous[i]
            c = previous[i - step] if i >= step else 0
            p = a + b - c
            paeth = a if abs(p - a) <= abs(p - b) and abs(p - a) <= abs(p - c) else b if abs(p - b) <= abs(p - c) else c
            out.append((value - (0, a, b, (a + b) // 2, paeth)[kind]) & 255)
        raw += bytes([kind]) + bytes(out)
        previous = line
    body = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, depth, colour, 0, 0, 0))
    if palette:
        body += chunk(b'PLTE', palette)
    if trns:
        body += chunk(b'tRNS', trns)
    return cmf_pack.PNG_SIGNATURE + body + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')


def flat_icon(size=64, colour=(40, 110, 220, 255), margin=4):
    pixels = bytearray()
    for y in range(size):
        for x in range(size):
            inside = margin <= x < size - margin and margin <= y < size - margin
            pixels += bytes(colour if inside else (0, 0, 0, 0))
    return bytes(pixels)


def make_pack(root, name, script, art=None, readme=True):
    folder = Path(root)/name
    (folder/'content/scripts/local').mkdir(parents=True)
    (folder/'content/scripts/local'/(name.lower() + '_cmf.ws')).write_bytes(script.encode('ascii'))
    for image, data in (art or {}).items():
        (folder/'art').mkdir(exist_ok=True)
        (folder/'art'/image).write_bytes(data)
    if readme:
        (folder/'README.txt').write_text('pack\n')
    return folder


WRAP = ('@wrapMethod(CR4Game)\nfunction OnGameStarted(restored : bool)\n{\n\tvar result : bool;\n'
        '\tresult = wrappedMethod(restored);\n%s\treturn result;\n}\n')


class PngTests(unittest.TestCase):
    def test_round_trip_rgba(self):
        rgba = bytes(range(256)) * 4 * 4
        self.assertEqual(cmf_pack.read_png(cmf_pack.write_png(32, 32, rgba)), (32, 32, rgba))

    def test_every_filter_and_colour_type(self):
        rgb_rows = [bytes((x * 7 + y * 13) & 255 for x in range(4 * 3)) for y in range(4)]
        expected = b''.join(row[i:i + 3] + b'\xff' for row in rgb_rows for i in range(0, 12, 3))
        for filters in ([0], [1], [2], [3], [4], [0, 1, 2, 3, 4]):
            self.assertEqual(cmf_pack.read_png(png(4, 4, 2, 8, rgb_rows, filters=filters))[2], expected)
        grey = cmf_pack.read_png(png(2, 1, 4, 8, [bytes([10, 20, 30, 40])]))[2]
        self.assertEqual(grey, bytes([10, 10, 10, 20, 30, 30, 30, 40]))
        palette = cmf_pack.read_png(png(4, 1, 3, 2, [bytes([0b00011011])], palette=bytes(range(12)), trns=b'\x00\x80'))[2]
        self.assertEqual(palette, bytes([0, 1, 2, 0, 3, 4, 5, 128, 6, 7, 8, 255, 9, 10, 11, 255]))
        deep = cmf_pack.read_png(png(1, 1, 6, 16, [bytes([1, 2, 3, 4, 5, 6, 7, 8])]))[2]
        self.assertEqual(deep, bytes([1, 3, 5, 7]))

    def test_rejects_damage_and_interlace(self):
        good = cmf_pack.write_png(4, 4, bytes(64))
        with self.assertRaises(ValueError):
            cmf_pack.read_png(good[:20] + b'x' + good[21:])
        with self.assertRaises(ValueError):
            cmf_pack.read_png(b'GIF89a')
        laced = bytearray(png(4, 4, 6, 8, [bytes(16)] * 4))
        laced[28] = 1
        struct.pack_into('>I', laced, 29, zlib.crc32(bytes(laced[12:29])))
        with self.assertRaisesRegex(ValueError, 'interlaced'):
            cmf_pack.read_png(bytes(laced))


class ArtTests(unittest.TestCase):
    def check(self, name, width, height, rgba):
        report = cmf_pack.Report()
        result = cmf_pack.check_art(name, cmf_pack.write_png(width, height, rgba), report)
        return result, report

    def test_accepts_flat_icon_and_recommends_96(self):
        result, report = self.check('sign.png', 64, 64, flat_icon())
        self.assertEqual((result[0], result[1], report.errors, report.warnings), (64, 64, [], []))
        self.assertIn('96x96 is recommended', report.notes[0])
        self.assertEqual(self.check('sign.png', 96, 96, flat_icon(96))[1].notes, [])

    def test_refuses_shape_size_and_name(self):
        for size in ((64, 60), (28, 28), (132, 132), (50, 50)):
            result, report = self.check('a.png', size[0], size[1], bytes(size[0] * size[1] * 4))
            self.assertIsNone(result)
            self.assertEqual(len(report.errors), 1)
        for name in ('Sign.png', 'my sign.png', 'sign.PNG'):
            self.assertIsNone(self.check(name, 64, 64, flat_icon())[0])

    def test_warns_on_border_transparency_and_gradients(self):
        self.assertIn('outer 4 pixels', self.check('a.png', 64, 64, flat_icon(margin=0))[1].warnings[0])
        self.assertIn('fully transparent', self.check('a.png', 64, 64, bytes(64 * 64 * 4))[1].warnings[0])
        noisy = bytearray(flat_icon())
        for i in range(0, len(noisy), 4):
            if noisy[i + 3]:
                noisy[i:i + 3] = bytes(((i * 97) % 256, (i * 53 + 90) % 256, (i * 31 + 170) % 256))
        self.assertIn('change colour', self.check('a.png', 64, 64, bytes(noisy))[1].warnings[0])

    def test_example_art_is_reproducible_and_clean(self):
        for name, (fill, glyph) in cmf_example_art.ART.items():
            data = cmf_pack.write_png(96, 96, cmf_example_art.disc_icon(fill, glyph))
            self.assertEqual((EXAMPLE/'art'/name).read_bytes(), data, name)
            result, report = self.check(name, 96, 96, cmf_pack.read_png(data)[2])
            self.assertEqual((report.errors, report.warnings, report.notes), ([], [], []), name)


class ScriptTests(unittest.TestCase):
    def run_pack(self, body, art=None, name='modAcmeIcons'):
        with tempfile.TemporaryDirectory() as root:
            return cmf_pack.check_pack(make_pack(root, name, WRAP % body, art))[0]

    def test_clean_pack(self):
        art = {'innkeeper.png': cmf_pack.write_png(64, 64, flat_icon())}
        report = self.run_pack('\tCMFRegisterIcon("modAcmeIcons", \'Innkeeper\', '
                               '"img://icons/modacmeicons/innkeeper.png");\n'
                               '\tCMFRegisterTint("modAcmeIcons", \'Herbalist\', 4259648);\n', art)
        self.assertEqual((report.errors, report.warnings), ([], []))

    def test_errors(self):
        cases = {
            '\tCMFRegisterIcon("modOther", \'Innkeeper\', "img://icons/modacmeicons/x.png");\n': 'pack folder name',
            '\tCMFRegisterTint("modAcmeIcons", \'Herbalist\', 0x40FF40);\n': 'decimal (4259648',
            '\tCMFRegisterTint("modAcmeIcons", \'Herbalist\', 16777216);\n': 'outside 0 to 16777215',
            '\tCMFRegisterIcon("modAcmeIcons", \'\', "img://icons/modacmeicons/x.png");\n': 'empty pin type',
            '\tCMFRegisterIcon("modAcmeIcons", \'Innkeeper\', "");\n': 'empty image path',
            '\tCMFRegisterIcon("modAcmeIcons", \'Innkeeper\', "icons/x.png");\n': 'start with img://',
            '\tCMFSetIcon("modAcmeIcons", \'Innkeeper\', "x");\n': 'not a CMF function',
            '\tCMFReleaseProvider("modWrong");\n': 'must be the pack folder name',
            '\tvar entry : int;\n': 'reserved word',
            '\tdata.SetMemberFlashString("cmfIconPath", "x");\n': 'CMF pin fields',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in e for e in report.errors), (body, report.errors))
        report = self.run_pack('\tCMFRegisterIcon("modAcmeIcons", \'Innkeeper\', "img://icons/modacmeicons/gone.png");\n')
        self.assertIn('has no image in art/', report.errors[0])
        with tempfile.TemporaryDirectory() as root:
            folder = make_pack(root, 'modAcmeIcons', 'function CMFMine() {}\r\n')
            (folder/'content/blob0.bundle').write_bytes(b'x')
            errors = '\n'.join(cmf_pack.check_pack(folder)[0].errors)
            for expected in ('functions starting with CMF', 'LF line endings', 'not part of an icon pack'):
                self.assertIn(expected, errors)
        for name in ('mod0000_Icons', 'AcmeIcons', 'modAcme-Icons'):
            self.assertTrue(self.run_pack('', name=name).errors, name)

    def test_warnings(self):
        cases = {
            '\tCMFRegisterTint("modAcmeIcons", \'MonsterNest_1\', 1);\n': 'register MonsterNest',
            '\tCMFRegisterTint("modAcmeIcons", \'Player\', 1);\n': 'no effect in CMF 1',
            '\tCMFRegisterTint("modAcmeIcons", \'innkeeper\', 1);\n': "did you mean 'Innkeeper'",
            '\tCMFRegisterIcon("modAcmeIcons", \'SideQuest\', "img://icons/a/b.png");\n'
            '\tCMFRegisterIcon("modAcmeIcons", \'StoryQuest\', "img://icons/a/c.png");\n': 'share one legend row',
            '\tCMFRegisterTint("modAcmeIcons", \'Innkeeper\', 1);\n'
            '\tCMFRegisterTint("modAcmeIcons", \'Innkeeper\', 2);\n': 'the last call wins',
            '\tCMFRegisterIcon(PACK, \'Innkeeper\', URL);\n': 'non-literal arguments',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in w for w in report.warnings), (body, report.warnings))
        report = self.run_pack('\tCMFRegisterTint("modAcmeIcons", \'Innkeeper\', 1);\n',
                               {'spare.png': cmf_pack.write_png(64, 64, flat_icon())})
        self.assertTrue(any('not used by any' in w for w in report.warnings))

    def test_generic_calls(self):
        art = {'innkeeper.png': cmf_pack.write_png(64, 64, flat_icon())}
        report = self.run_pack('\tif (CMFHasProperty(3)) { CMFRegister("modAcmeIcons", 3, \'Herbalist\', \'\', "", 4259648); }\n'
                               '\tCMFRegister("modAcmeIcons", CMFPropertyIcon(), \'Innkeeper\', \'\', '
                               '"img://icons/modacmeicons/innkeeper.png", 0);\n'
                               '\tCMFRegisterForTag("modAcmeIcons", 5, \'seven_cats_inn\', \'FastTravel\', "", 1);\n', art)
        self.assertEqual((report.errors, report.warnings), ([], []))
        cases = {
            '\tCMFRegister("modAcmeIcons", 3, \'Herbalist\', \'Boat\', "", 1);\n': 'map context applies only',
            '\tCMFRegisterForTag("modAcmeIcons", 3, \'x_tag\', \'\', "", 1);\n': 'accepts only CMFPropertyIcon',
            '\tCMFRegister("modOther", 3, \'Herbalist\', \'\', "", 1);\n': 'pack folder name',
            '\tCMFRegister("modAcmeIcons", 3, \'Herbalist\', \'\', "", 0x40FF40);\n': 'decimal (4259648',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in e for e in report.errors), (body, report.errors))
        report = self.run_pack('\tCMFRegister("modAcmeIcons", 99, \'Herbalist\', \'\', "", 1);\n')
        self.assertTrue(any('guard the call with CMFHasProperty' in w for w in report.warnings), report.warnings)

    def test_version2_calls(self):
        clean = ('\tif (CMFHasProperty(8))\n\t{\n'
                 '\t\tCMFRegister("modAcmeIcons", 8, \'modAcmeIcons_tab\', \'\', "[[acme_tab]]", 8);\n'
                 '\t\tCMFRegister("modAcmeIcons", 6, \'AcmePin\', \'\', "modAcmeIcons_tab", 701);\n'
                 '\t\tCMFRegister("modAcmeIcons", CMFPropertyLegendLabel(), \'AcmePin\', \'\', "Acme", 0);\n'
                 '\t\tCMFRegister("modAcmeIcons", 6, \'OtherPin\', \'\', "", 0);\n\t}\n')
        report = self.run_pack(clean)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertFalse([n for n in report.notes if 'only with CMF 2' in n], report.notes)
        named = ('\tCMFRegisterLegendCategory("modAcmeIcons", \'modAcmeIcons_tab\', "Acme", 1);\n'
                 '\tCMFRegisterLegendRow("modAcmeIcons", \'AcmePin\', \'modAcmeIcons_tab\', 0);\n'
                 '\tCMFRegisterLegendLabel("modAcmeIcons", \'AcmePin\', "[[acme_pin]]");\n')
        report = self.run_pack(named)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('only with CMF 2' in n for n in report.notes), report.notes)
        cases = {
            '\tCMFRegister("modAcmeIcons", 8, \'quests\', \'\', "Mine", 1);\n': 'vanilla legend category',
            '\tCMFRegisterLegendCategory("modAcmeIcons", \'NPCs\', "Mine", 1);\n': 'vanilla legend category',
            '\tCMFRegister("modAcmeIcons", 7, \'AcmePin\', \'\', "", 0);\n': 'empty label',
            '\tCMFRegisterLegendCategory("modAcmeIcons", \'acme_tab\', "", 1);\n': 'empty tab name',
            '\tCMFRegisterForTag("modAcmeIcons", 6, \'x_tag\', \'\', "General", 1);\n': 'accepts only CMFPropertyIcon',
            '\tCMFRegisterLegendRow("modOther", \'AcmePin\', \'General\', 1);\n': 'pack folder name',
            '\tCMFStylePinTint("modOther", dataObject, 4259648);\n': 'must be the pack folder name',
            '\tdataObject.SetMemberFlashString("cmfTintBy", "x");\n': 'CMF pin fields',
            '\tdataObject.SetMemberFlashBool("cmfRowHide", true);\n': 'CMF pin fields',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in e for e in report.errors), (body, report.errors))
        report = self.run_pack('\tCMFRegister("modAcmeIcons", 18, \'AcmePin\', \'\', "", 1);\n')
        self.assertTrue(any('unknown to CMF 6' in w for w in report.warnings), report.warnings)

    def test_version3_calls(self):
        clean = ('\tif (CMFHasProperty(9))\n\t{\n'
                 '\t\tCMFRegister("modAcmeIcons", 9, \'\', \'FastTravel\', "fasttravel, Quest", 1);\n'
                 '\t\tCMFRegister("modAcmeIcons", 9, \'Herbalist\', \'\', "", 0);\n'
                 '\t\tCMFRegisterForTag("modAcmeIcons", 9, \'seven_cats_inn\', \'GlobalMap\', "tracked", 1);\n\t}\n')
        report = self.run_pack(clean)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertFalse([n for n in report.notes if 'only with CMF 3' in n], report.notes)
        named = ('\tCMFRegisterHidden("modAcmeIcons", \'Herbalist\', \'\', "quest", true);\n'
                 '\tCMFRegisterHiddenForTag("modAcmeIcons", \'seven_cats_inn\', \'\', "", false);\n'
                 '\tCMFRegister("modAcmeIcons", CMFPropertyHidden(), \'Armorer\', \'\', "", 1);\n'
                 '\tCMFHidePin("modAcmeIcons", dataObject);\n')
        report = self.run_pack(named)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('only with CMF 3' in n for n in report.notes), report.notes)
        cases = {
            '\tCMFRegister("modAcmeIcons", 9, \'Armorer\', \'\', "bogus", 1);\n': 'unknown exemption "bogus"',
            '\tCMFRegisterHidden("modAcmeIcons", \'Armorer\', \'\', "tracked,shops", true);\n': 'unknown exemption',
            '\tCMFRegisterForTag("modAcmeIcons", 9, \'\', \'\', "", 1);\n': 'empty pin tag',
            '\tCMFRegisterHiddenForTag("modAcmeIcons", \'\', \'\', "", true);\n': 'empty pin tag',
            '\tCMFRegisterHidden("modOther", \'Armorer\', \'\', "", true);\n': 'pack folder name',
            '\tCMFHidePin("modOther", dataObject);\n': 'must be the pack folder name',
            '\tdataObject.SetMemberFlashString("cmfHiddenBy", "x");\n': 'CMF pin fields',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in e for e in report.errors), (body, report.errors))

    def test_version5_theme_calls(self):
        clean = ('\tif (CMFRequireVersion("modAcmeIcons", 5))\n\t{\n'
                 '\t\tCMFStylePart("modAcmeIcons", \'title\', \'font\', "$TitleFont", 0);\n'
                 '\t\tCMFStylePart("modAcmeIcons", \'map\', \'backdrop\', "", 1381903);\n'
                 '\t\tCMFDraw("modAcmeIcons", \'legend\', \'acmeFrame\', \'ring\');\n'
                 '\t\tCMFDrawSet("modAcmeIcons", \'acmeFrame\', \'inset\', "", 2);\n'
                 '\t\tCMFDraw("modAcmeIcons", \'acmeFrame\', \'acmeDot\', \'ellipse\');\n'
                 '\t\tCMFRegister("modAcmeIcons", 17, \'Herbalist\', \'\', "", 4259648);\n'
                 '\t\tCMFRegisterForTag("modAcmeIcons", CMFPropertyLabelColor(), \'acme_well\', \'\', "", 0);\n\t}\n')
        report = self.run_pack(clean)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('only with CMF 5' in n for n in report.notes), report.notes)
        cases = {
            '\tCMFStylePart("modAcmeIcons", \'compass\', \'font\', "$TitleFont", 0);\n': 'not a part of CMF',
            '\tCMFStylePart("modAcmeIcons", \'legend\', \'wrap\', "none", 0);\n': "takes no key 'wrap'",
            '\tCMFStylePart("modOther", \'title\', \'size\', "", 20);\n': 'pack folder name',
            '\tCMFDraw("modAcmeIcons", \'legend\', \'acmeArc\', \'arc\');\n': 'not a drawing kind',
            '\tCMFDraw("modAcmeIcons", \'legend\', \'title\', \'rect\');\n': 'cannot be a drawing id',
            '\tCMFDraw("modAcmeIcons", \'over\', \'acmeBox\', \'rect\');\n': 'cannot be an anchor',
            '\tCMFDrawSet("modAcmeIcons", \'acmeBox\', \'image\', "img://x.png", 0);\n': 'not a drawing key in CMF 7',
            '\tCMFRegister("modAcmeIcons", 17, \'Herbalist\', \'\', "", 16777216);\n': 'not a colour',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in e for e in report.errors), (body, report.errors))

    def test_version4_calls(self):
        clean = ('\tif (CMFHasProperty(15))\n\t{\n'
                 '\t\tCMFRegister("modAcmeIcons", 10, \'Herbalist\', \'\', "", 150);\n'
                 '\t\tCMFRegister("modAcmeIcons", 11, \'Herbalist\', \'\', "", 12);\n'
                 '\t\tCMFRegister("modAcmeIcons", 12, \'Herbalist\', \'\', "Herbs", 0);\n'
                 '\t\tCMFRegister("modAcmeIcons", 13, \'Herbalist\', \'\', "pin, crosshair", 1);\n'
                 '\t\tCMFRegister("modAcmeIcons", 14, \'\', \'\', "", 640);\n'
                 '\t\tCMFRegister("modAcmeIcons", 15, \'\', \'\', "Quests,Buffs", 1);\n'
                 '\t\tCMFRegisterForTag("modAcmeIcons", 10, \'acme_well\', \'\', "", 200);\n\t}\n')
        report = self.run_pack(clean)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertFalse([n for n in report.notes if 'only with CMF 4' in n], report.notes)
        named = ('\tCMFStylePinScale("modAcmeIcons", dataObject, 120);\n'
                 '\tCMFStylePinLabel("modAcmeIcons", dataObject, CMFLevelLabel(12, 1));\n'
                 '\tCMFStylePin("modAcmeIcons", dataObject, CMFPropertyLabelHide(), "pin", 1);\n')
        report = self.run_pack(named)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('only with CMF 4' in n for n in report.notes), report.notes)
        cases = {
            '\tCMFRegister("modAcmeIcons", 10, \'Herbalist\', \'\', "", 500);\n': 'outside 25 to 400',
            '\tCMFRegister("modAcmeIcons", 11, \'Herbalist\', \'\', "", 20000);\n': 'outside 0 to 10000',
            '\tCMFRegister("modAcmeIcons", 12, \'Herbalist\', \'\', "", 0);\n': 'empty label text',
            '\tCMFRegister("modAcmeIcons", 13, \'Herbalist\', \'\', "name", 1);\n': 'pin, crosshair or both',
            '\tCMFRegister("modAcmeIcons", 14, \'\', \'\', "", 50);\n': 'outside 100 to 1080',
            '\tCMFRegister("modAcmeIcons", 14, \'Herbalist\', \'\', "", 640);\n': 'applies to the whole map',
            '\tCMFRegister("modAcmeIcons", 15, \'\', \'\', "", 1);\n': 'no filter tab named',
            '\tCMFRegisterForTag("modAcmeIcons", 14, \'acme_well\', \'\', "", 640);\n': 'applies to the whole map',
            '\tCMFStylePinScale("modOther", dataObject, 120);\n': 'must be the pack folder name',
            '\tdataObject.SetMemberFlashNumber("cmfIconScale", 2);\n': 'CMF pin fields',
            '\tdataObject.SetMemberFlashString("cmfLabelText", "x");\n': 'CMF pin fields',
        }
        for body, expected in cases.items():
            report = self.run_pack(body)
            self.assertTrue(any(expected in e for e in report.errors), (body, report.errors))
        # A withdrawal (number 0) is never range-checked.
        report = self.run_pack('\tCMFRegister("modAcmeIcons", 14, \'\', \'\', "", 0);\n')
        self.assertEqual(report.errors, [])

    def test_cmfcore_hooks(self):
        hook = ('@wrapMethod(CMFCore)\nfunction OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)\n'
                '{\n\twrappedMethod(dataObject, mapContext);\n\tCMFStylePinScale("modAcmeIcons", dataObject, 120);\n}\n')
        report, claims, calls = cmf_pack.Report(), [], set()
        cmf_pack.check_script('x.ws', hook, 'modAcmeIcons', report, claims, calls)
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('CMFCore.OnPinReady' in n for n in report.notes), report.notes)
        other = '@wrapMethod(CMFCore)\nfunction Prepare()\n{\n\twrappedMethod();\n}\n'
        report, claims, calls = cmf_pack.Report(), [], set()
        cmf_pack.check_script('x.ws', other, 'modAcmeIcons', report, claims, calls)
        self.assertTrue(any('wrap only the CMFCore hooks' in e for e in report.errors), report.errors)

    def test_adapter_mode_takes_the_adapted_mods_folder_as_provider(self):
        body = '\tCMFStylePinScale("modOtherMod", dataObject, 120);\n\tCMFRegisterIcon("modOtherMod", \'Innkeeper\', "img://icons/x/y.png");\n'
        script = '@wrapMethod(CR4Game)\nfunction OnGameStarted(restored : bool)\n{\n%s}\n' % body
        report, claims, calls = cmf_pack.Report(), [], set()
        cmf_pack.check_script('x.ws', script, 'modCMFAdapterOtherMod', report, claims, calls, 'modOtherMod')
        self.assertEqual(report.errors, [])
        report, claims, calls = cmf_pack.Report(), [], set()
        cmf_pack.check_script('x.ws', script, 'modCMFAdapterOtherMod', report, claims, calls)
        self.assertEqual(len([e for e in report.errors if 'pack folder name' in e]), 1, report.errors)
        report = cmf_pack.Report()
        cmf_pack.check_claims('modCMFAdapterOtherMod', claims, {}, report, {}, 'modOtherMod')
        self.assertFalse([e for e in report.errors if 'provider' in e], report.errors)

    def test_style_wrapper_is_not_warned(self):
        wrapper = ('@wrapMethod(CR4MapMenu)\nfunction AddPinTypeData(out dataObject : CScriptedFlashObject, '
                   'targetPin : SCommonMapPinInstance) : void\n{\n\twrappedMethod(dataObject, targetPin);\n%s}\n')
        styled = wrapper % '\tCMFStylePinTint("modAcmeIcons", dataObject, 4259648);\n'
        hidden = wrapper % '\tCMFHidePin("modAcmeIcons", dataObject);\n'
        plain = wrapper % ''
        with tempfile.TemporaryDirectory() as root:
            for body, warned in ((styled, False), (hidden, False), (plain, True)):
                report, claims, calls = cmf_pack.Report(), [], set()
                cmf_pack.check_script('x.ws', body, 'modAcmeIcons', report, claims, calls)
                self.assertEqual(any('AddPinTypeData' in w for w in report.warnings), warned, report.warnings)

    def test_comments_are_ignored(self):
        report = self.run_pack('\t// CMFRegisterIcon("modOther", \'X\', "y");\n\t/* var entry : int; */\n')
        self.assertEqual(report.errors, [])

    def test_core_owner_test_packs_pass_script_checks(self):
        for script in sorted(PROVIDERS.glob('*/content/scripts/local/*.ws')):
            report, claims, calls = cmf_pack.Report(), [], set()
            pack = script.parts[-5]
            cmf_pack.check_script(script.name, script.read_text(encoding='ascii'), pack, report, claims, calls)
            cmf_pack.check_claims(pack, claims, {}, report, cmf_pin_types.known_types())
            # Background and disabled-appearance packs make no art claims; the pack tool does not cook map tiles yet.
            # The N4 pack styles one pin from the OnPinReady hook and claims by tag through a property function.
            # The click probe (modZZCMFTestClick) registers one generic click claim (id 16); the smooth movement
            # probe (modZZCMFTestSmooth) only sends navigation and opening keys; the map-space probe
            # (modCMFTestMapSpace) only makes drawings; the hover names probe (modCMFTestHoverNames) registers generic
            # HoverName claims (id 28).
            self.assertTrue(claims or calls & {'CMFRegisterBackground', 'CMFRegisterDisabled', 'CMFStylePinScale'} or
                            pack in ('modZZCMFTestClick', 'modCMFTestHoverNames') and 'CMFRegister' in calls or
                            pack == 'modZZCMFTestSmooth' and 'CMFStylePart' in calls or
                            pack == 'modCMFTestMapSpace' and 'CMFDrawSetList' in calls, script)
            # CMF's own test packs may use the CMF prefix; their art is cooked by tools/cmf_pin_stage.py.
            # modcmfTestCaseA declares the vanilla 'Quests' category and the exemption "bogus" on purpose to
            # show core's rejections.
            allowed = ('has no image', 'functions starting with CMF', "'Quests' is a vanilla legend category",
                       'unknown exemption "bogus"')
            self.assertFalse([e for e in report.errors if not any(a in e for a in allowed)], (script, report.errors))


class ThemeTestPackTests(unittest.TestCase):
    """The Cyberpunk check (Stage 6b design 6): a different look from public calls only, with no CMF change."""
    SOURCE = PROVIDERS/'modCMFTestThemePack'

    def test_calls_only_public_cmf_calls(self):
        report, plan = cmf_pack.check_pack(self.SOURCE)
        self.assertEqual((report.errors, report.warnings), ([], []))
        code = cmf_pack.strip_comments(
            (self.SOURCE/'content/scripts/local/modcmftestthemepack_cmf.ws').read_text(encoding='ascii'))
        called = set(cmf_pack.CALL.findall(code))
        self.assertTrue(called <= cmf_pack.API, called - cmf_pack.API)
        self.assertTrue({'CMFStylePart', 'CMFDraw', 'CMFDrawSet', 'CMFRegisterBackground', 'CMFRegisterIcon'} <= called)
        # Its only hook into the game is the start-up wrapper every pack uses; it touches no CMF or game class.
        self.assertEqual(re.findall(r'@\w+\(\s*(\w+)\s*\)', code), ['CR4Game'])
        self.assertEqual({c['provider'] for c in plan['claims']}, {'modCMFTestThemePack'})

    def test_art_is_reproducible(self):
        for name, draw in cmf_test_theme.ART.items():
            self.assertEqual(cmf_pack.write_png(96, 96, draw()), (self.SOURCE/'art'/name).read_bytes(), name)

    def test_stage_cooks_icons_and_neon_tiles(self):
        with tempfile.TemporaryDirectory() as out:
            manifest = cmf_test_theme.stage(Path(out)/'stage')
            data = (Path(out)/'stage/Mods/modCMFTestThemePack/content/texture.cache').read_bytes()
            keys = [(e[0], e[1], e[2]) for e in cache.read_entries(data)]
            icons = [k for k in keys if '\\icons\\' in k[0]]
            self.assertEqual(sorted(k[0].rsplit('\\', 1)[1] for k in icons), sorted(cmf_test_theme.ART))
            self.assertEqual(keys[len(icons):], [(k, 1024, 1024) for k, _, _, _ in cmf_test_theme.neon_tiles()])
            self.assertEqual(len(keys) - len(icons), 341)
            self.assertEqual(manifest['background'], {'root': 'cmf_testneon', 'tiles': 341})


class BuildTests(unittest.TestCase):
    def test_example_pack_builds(self):
        with tempfile.TemporaryDirectory() as out:
            out = Path(out)/'build'
            report, manifest = cmf_pack.build_pack(EXAMPLE, out)
            self.assertEqual((report.errors, report.warnings), ([], []))
            pack = out/'Mods/modCMFExampleIconPack'
            entries = cache.read_entries((pack/'content/texture.cache').read_bytes())
            self.assertEqual([(e[0], e[1], e[2]) for e in entries],
                             [('gameplay\\gui_new\\icons\\modcmfexampleiconpack\\%s' % n, 96, 96)
                              for n in ('armorer.png', 'cleared.png', 'innkeeper.png', 'innkeeper_legend.png')])
            script = 'content/scripts/local/modcmfexampleiconpack_cmf.ws'
            self.assertEqual((pack/script).read_bytes(), (EXAMPLE/script).read_bytes())
            self.assertEqual(sorted(manifest['files']), sorted(
                'Mods/modCMFExampleIconPack/' + n for n in ('README.txt', 'content/texture.cache', script)))
            self.assertEqual(json.loads((out/'pack-build.json').read_text())['files'], manifest['files'])
            self.assertEqual([c['target'] for c in manifest['claims']], ['Innkeeper', 'Innkeeper', 'Armorer', 'BanditCampDisabled', 'BanditCampfireDisabled', 'MonsterNestDisabled', 'Herbalist'])
            self.assertEqual(manifest['claims'][6]['value'], '0x40FF40')
            again, second = cmf_pack.build_pack(EXAMPLE, Path(out).parent/'again')
            self.assertEqual(second['files'], manifest['files'])
            refused, nothing = cmf_pack.build_pack(EXAMPLE, out)
            self.assertIsNone(nothing)
            self.assertIn('already exists', refused.errors[0])

    def test_build_refuses_errors(self):
        with tempfile.TemporaryDirectory() as root:
            folder = make_pack(root, 'modAcmeIcons', WRAP % '\tCMFRegisterTint("modX", \'Innkeeper\', 1);\n')
            report, manifest = cmf_pack.build_pack(folder, Path(root)/'out')
            self.assertIsNone(manifest)
            self.assertFalse((Path(root)/'out').exists())

    def test_extra_files_are_carried(self):
        with tempfile.TemporaryDirectory() as root:
            folder = make_pack(root, 'modAcmeIcons', WRAP % '\tCMFRegisterTint("modAcmeIcons", \'Innkeeper\', 1);\n')
            (folder/'content/en.w3strings').write_bytes(b'strings')
            menu = folder/'bin/config/r4game/user_config_matrix/pc'
            menu.mkdir(parents=True)
            (menu/'modAcmeIcons.xml').write_bytes(b'<xml/>')
            report, manifest = cmf_pack.build_pack(folder, Path(root)/'out')
            self.assertEqual(report.errors, [])
            self.assertIn('Mods/modAcmeIcons/content/en.w3strings', manifest['files'])
            self.assertIn('bin/config/r4game/user_config_matrix/pc/modAcmeIcons.xml', manifest['files'])
            self.assertNotIn('Mods/modAcmeIcons/content/texture.cache', manifest['files'])

    def test_skeleton_matches_example_calls(self):
        text = cmf_pack.skeleton(EXAMPLE)
        example = (EXAMPLE/'content/scripts/local/modcmfexampleiconpack_cmf.ws').read_text()
        for line in text.splitlines():
            if line.strip().startswith('CMFRegister'):
                self.assertIn(line.strip(), example)
        self.assertIn('if (CMFRequireVersion("modCMFExampleIconPack", 1))', text)


class PinTypeTests(unittest.TestCase):
    def test_committed_page_matches_committed_list(self):
        data = json.loads(cmf_pin_types.JSON_PATH.read_text(encoding='utf-8'))
        self.assertEqual(cmf_pin_types.MD_PATH.read_text(encoding='utf-8'), cmf_pin_types.render(data))
        self.assertEqual((data['pinSpriteSha256'], data['legendSha256']),
                         (cmf_pin_types.PIN_SPRITE_SHA, cmf_pin_types.LEGEND_SHA))
        names = [t['name'] for t in data['types']]
        self.assertEqual(len(names), len(set(names)))
        types = cmf_pin_types.known_types()
        for name in ('Innkeeper', 'Armorer', 'Herbalist', 'NoticeBoard', 'NoticeBoardFull', 'RoadSign', 'Shopkeeper',
                     'Entrance', 'Blacksmith'):
            self.assertEqual(types[name]['reach'], 'yes', name)
        self.assertEqual(types['MonsterNest_2']['reach'], 'base')
        self.assertEqual(types['Hairdresser']['priority'], 511)

    def test_sprite_labels_from_a_synthetic_movie(self):
        def tag(code, payload):
            return struct.pack('<HI', code << 6 | 63, len(payload)) + payload
        inner = tag(43, b'Alpha\0') + tag(1, b'') + tag(43, b'Beta\0') + tag(1, b'') + tag(0, b'')
        sprite = tag(39, struct.pack('<HH', 588, 2) + inner)
        other = tag(39, struct.pack('<HH', 7, 1) + tag(43, b'Nope\0') + tag(0, b''))
        body = bytes([0x08, 0]) + struct.pack('<HH', 0x1800, 1) + other + sprite + tag(0, b'')
        digest, labels = cmf_pin_types.sprite_labels(body)
        self.assertEqual((digest, labels), (cmf_pin_types.sha(sprite), ['Alpha', 'Beta']))
        with self.assertRaises(ValueError):
            cmf_pin_types.sprite_labels(body, 9)
        movie = b'CWS\x0a' + struct.pack('<I', len(body) + 8) + zlib.compress(body)
        self.assertEqual(cmf_pin_types.movie_body(movie), body)

    def test_legend_definitions_take_the_last_duplicate(self):
        text = ('private var _pinTypeDefinitions:Object = {\n"A":new PinTypeDefinition("General",1),\n'
                '"B":new PinTypeDefinition("NPCs",2),\n"A":new PinTypeDefinition("Buffs",3)\n};')
        self.assertEqual(cmf_pin_types.legend_definitions(text), [('B', 'NPCs', 2), ('A', 'Buffs', 3)])
        with self.assertRaises(ValueError):
            cmf_pin_types.build(['A'], [('A', 'General', 1)], 'f' * 64, 'test')

    @unittest.skipUnless((ROOT/'build/reference/panel-topology-2026-10-18/gameplay/gui_new/swf/worldmap/'
                          'panel_worldmap.redswf').exists(), 'ignored pinned vanilla panel absent')
    def test_vanilla_panel_sprite_matches_committed_list(self):
        path = ROOT/'build/reference/panel-topology-2026-10-18/gameplay/gui_new/swf/worldmap/panel_worldmap.redswf'
        digest, labels = cmf_pin_types.sprite_labels(cmf_pin_types.movie_body(cmf_pin_types.movie_from(redswf=path)))
        self.assertEqual(digest, cmf_pin_types.PIN_SPRITE_SHA)
        self.assertEqual(set(labels), {n for n, t in cmf_pin_types.known_types().items() if t['art']})


if __name__ == '__main__':
    unittest.main()
