"""API 14 picture fit (property 48): core claim, panel fit box, pack tool and docs."""
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tests'), str(ROOT / 'tools')]
import cmf_pack
from rev14_animation_contracts import CORE, install, parser_environment
from test_cmf_pack import WRAP, make_pack

EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
GUIDE = (ROOT / 'docs/authors/icon-pack-guide.md').read_text(encoding='utf-8')


def piece(cls, find_start):
    found = [e['replace'] for e in EDITS['red/game/witcher3/' + cls] if e.get('find', '').startswith(find_start)]
    assert found, (cls, find_start)
    return '\n'.join(found)


class CoreTests(unittest.TestCase):
    def test_id_value_range_owner_and_discovery(self):
        self.assertIn('function CMFPropertyPictureFit() : int { return 48; }', CORE)
        env = parser_environment()
        for name, value in re.findall(r'function (CMF\w+)\(\) : int \{ return (\d+); \}', CORE):
            env[name] = lambda value=int(value): value
        env.update(CMFListHas=lambda s, w: w in s.split(','), CMFIsClickProperty=lambda p: p in (16, 20, 21),
                   CMFIsPictureProperty=lambda p: 24 <= p <= 27)
        install(env, {'CMFHasProperty', 'CMFHasAbility', 'CMFOwnerField', 'CMFPropertyTextFree'})
        self.assertTrue(env['CMFHasProperty'](48))
        self.assertFalse(env['CMFHasProperty'](49))
        self.assertTrue(env['CMFHasAbility']('claims', 'pictureFit'))
        self.assertEqual(env['CMFOwnerField'](48), 'cmfPictureFitBy')
        self.assertTrue(env['CMFPropertyTextFree'](48))

    def test_value_is_zero_or_one_and_reaches_the_pin(self):
        self.assertIn('if (propertyId == 48) { return number == 0 || number == 1; }', CORE)
        self.assertIn('case 48:\n\t\t\t\tdataObject.SetMemberFlashInt("cmfPictureFit", number);\n'
                      '\t\t\t\tdataObject.SetMemberFlashBool("cmfPictureFitEnabled", true);', CORE)
        self.assertIn('propertyId >= 42 && propertyId <= 48', CORE)
        self.assertIn('propertyId == 47 || propertyId == 48;\n}', CORE)
        self.assertIn('i == 45 || i == 46 || i == 48)) { activeWriteSlots', CORE)

    def test_legend_gets_the_same_claim(self):
        body = CORE[CORE.index('API 14 picture fit: the legend row'):]
        body = body[:body.index('PropertyWon(CMFPropertyTint())')]
        self.assertIn("Find(48, legendKey, '', 1, claim) || Find(48, pinKey, '', 1, claim)", body)
        self.assertIn('"cmfLegendFit"', body)
        self.assertIn('"cmfLegendFitEnabled"', body)


class PanelTests(unittest.TestCase):
    def test_fields_are_declared_and_copied_to_the_legend(self):
        data = piece('data/StaticMapPinData.as', '      public var cmfIconUnderTintBy')
        for field in ('cmfPictureFit:int', 'cmfPictureFitEnabled:Boolean', 'cmfPictureFitBy:String'):
            self.assertIn(field, data)
        legend = piece('data/StaticMapPinData.as', '      public function StaticMapPinData()')
        self.assertIn('cmfLegendFit:int', legend)
        self.assertIn('cmfFitEnabled:Boolean', piece('menus/worldmap/data/CategoryPinData.as', '      public function CategoryPinData('))
        copy = piece('menus/worldmap/HubMapPinPanel.as', '         if(!param1.cmfIconTintEnabled && param2.cmfLegendTintEnabled)')
        self.assertIn('param1.cmfFit = param2.cmfLegendFit;', copy)

    def test_pin_pictures_use_the_fixed_box_only_when_asked(self):
        d = 'menus/worldmap/StaticMapPinDescribed.as'
        still = piece(d, '      public function SetWorldPosition(')
        self.assertIn('public static const CMF_FIT_BOX:Number = 24;', still)
        rect = still[still.index('private function cmfFitRect'):still.index('private function cmfShowIconArt')]
        self.assertIn('!pin.cmfPictureFitEnabled || pin.cmfPictureFit != 1', rect)
        self.assertIn('return glyph;', rect)
        self.assertIn('glyph.x + (glyph.width - CMF_FIT_BOX) / 2', rect)
        self.assertIn('this.cmfFitRect(data as StaticMapPinData,this.mcIcon.mcPinIcon.getBounds(this.mcIcon))', still)
        allrepl = '\n'.join(e.get('replace', '') for e in EDITS['red/game/witcher3/' + d])
        self.assertIn('if(!box) { box = this.cmfFitRect(pin,this.mcIcon.mcPinIcon.getBounds(this.mcIcon)); }', allrepl)
        self.assertNotIn('if(!box) { box = this.mcIcon.mcPinIcon.getBounds(this.mcIcon); }', allrepl)

    def test_legend_box_follows_the_glyph_scale_and_is_logged(self):
        r = 'menus/worldmap/HubMapPinCategoryItemRenderer.as'
        art = '\n'.join(e.get('replace', '') for e in EDITS['red/game/witcher3/' + r])
        self.assertIn('side = 24 * Math.abs(this.mcIconContainer.mcIcon.scaleX) / 1.3227;', art)
        self.assertIn('"legend fit box=" + side', art)
        self.assertIn('var _loc4_:Number = this.cmfFitSide(data as CategoryPinData,_loc1_);', art)
        self.assertIn('var side:Number = this.cmfFitSide(data as CategoryPinData,box);', art)

    def test_fit_box_model(self):
        # A model of cmfFitRect: a 13 x 13 glyph (Herb) and a 36.7 wide one (QuestReturn) both give a 24 square, centred.
        for w, h in ((13.0, 13.0), (36.7, 30.0), (16.1, 16.1)):
            x, y = 3.0, -4.0
            fit = (x + (w - 24) / 2, y + (h - 24) / 2, 24, 24)
            self.assertAlmostEqual(fit[0] + 12, x + w / 2)
            self.assertAlmostEqual(fit[1] + 12, y + h / 2)

    def test_no_bitmap_writes_or_filters_added(self):
        text = json.dumps(EDITS)
        for helper in ('cmfFitRect', 'cmfFitSide'):
            body = text[text.index('private function ' + helper):][:900]
            self.assertNotIn('BitmapData(', body)
            self.assertNotIn('filters', body)


class PackAndDocsTests(unittest.TestCase):
    def run_pack(self, body):
        with tempfile.TemporaryDirectory() as root:
            return cmf_pack.check_pack(make_pack(root, 'modAcmeIcons', WRAP % body, None))[0]

    def test_pack_tool_knows_the_property(self):
        self.assertEqual(cmf_pack.PROPERTY_IDS['CMFPropertyPictureFit'], 48)
        self.assertIn('CMFPropertyPictureFit', cmf_pack.VERSION14)
        self.assertIn(48, cmf_pack.KNOWN_PROPERTIES)
        self.assertIn(48, cmf_pack.EVERY_PIN_PROPERTIES)
        self.assertIn(48, cmf_pack.ONE_PIN_PROPERTIES)

    def test_claim_values_are_checked_and_old_cores_are_advised(self):
        report = self.run_pack('\tCMFRegister("modAcmeIcons", CMFPropertyPictureFit(), \'\', \'\', "", 1);\n')
        self.assertEqual(report.errors, [])
        self.assertTrue(any('API 14' in n or 'pictureFit' in n for n in report.notes), report.notes)
        report = self.run_pack('\tif (CMFHasProperty(48)) { CMFRegister("modAcmeIcons", 48, \'\', \'\', "", 1); }\n')
        self.assertEqual(report.errors, [])

    def test_guide_describes_it_with_the_glyph_numbers(self):
        self.assertIn('| `48` PictureFit (API version 14) | `CMFPropertyPictureFit()`', GUIDE)
        for fact in ('24 map-icon units', 'median of their larger side is 21.8', '75th percentile 25.3', '16.1', '13.0',
                     '30.1', '36.7', 'minimap add-on does not use it yet'):
            self.assertIn(fact, GUIDE)


if __name__ == '__main__':
    unittest.main()
