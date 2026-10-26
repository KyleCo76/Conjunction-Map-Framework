"""Keeping a tab's rows out of Default (API version 6, property 23): a CMF tab's rows list in Default too, as
General's do, unless the tab opts out, as Community Patch's Botanist tab did on its own map.

Static checks only; nothing here has run in game.
"""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
GUIDE = ROOT/'docs/authors/icon-pack-guide.md'
PACK = ROOT/'tools/cmf_pack.py'


def replaced(path):
    data = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/' + path]
    return ''.join(e['replace'] for e in data)


class CategoryNoDefaultTests(unittest.TestCase):
    def test_core_declares_and_accepts_the_property(self):
        core = CORE.read_text(encoding='ascii')
        self.assertIn('function CMFPropertyCategoryNoDefault() : int { return 23; }', core)
        start = core.index('function CMFHasProperty(')
        self.assertIn('CMFPropertyCategoryNoDefault()', core[start:core.index('\n}', start)])
        start = core.index('function CMFPropertyTextFree(')
        self.assertIn('CMFPropertyCategoryNoDefault()', core[start:core.index('\n}', start)])
        self.assertIn('(incoming.propertyId == CMFPropertyLegendCategory() || incoming.propertyId == '
                      'CMFPropertyCategoryNoDefault()) &&\n\t\t\tCMFIsVanillaCategory(', core)
        self.assertIn('function CMFRegisterCategoryNoDefault(provider : string, category : name, noDefault : bool)',
                      core)

    def test_core_writes_the_field_only_for_a_declared_cmf_tab(self):
        core = CORE.read_text(encoding='ascii')
        start = core.index('\tprivate function WriteFields(')
        fields = core[start:core.index('\n\t}', start)]
        tab = fields.index('if (categoryAt >= 0)')
        flag = fields.index('dataObject.SetMemberFlashBool("cmfCategoryNoDefault", true);')
        self.assertLess(tab, flag)
        self.assertLess(flag, fields.index('else if (CMFIsVanillaCategory(claim.text, false))'))
        self.assertIn('Find(CMFPropertyCategoryNoDefault(), claim.text, \'\', 1, noDefault) && noDefault.number != 0',
                      fields)

    def test_panel_skips_default_for_an_opted_out_tab(self):
        self.assertIn('public var cmfCategoryNoDefault:Boolean = false;', replaced('data/StaticMapPinData.as'))
        panel = replaced('menus/worldmap/HubMapPinPanel.as')
        self.assertIn('_loc7_ = param1.cmfCategoryNoDefault ? "" : "General";', panel)

    def test_pack_tool_and_guide_know_the_property(self):
        import cmf_pack
        self.assertEqual(cmf_pack.PROPERTY_IDS['CMFPropertyCategoryNoDefault'], 23)
        self.assertIn(23, cmf_pack.KNOWN_PROPERTIES)
        self.assertEqual(cmf_pack.KNOWN_PROPERTIES, set(range(1, 45)))
        self.assertEqual(cmf_pack.n4_issues(23, 'modAcmeIcons_finds', '1'), [])
        self.assertNotIn(0, cmf_pack.KNOWN_PROPERTIES)
        self.assertNotIn(45, cmf_pack.KNOWN_PROPERTIES)
        guide = GUIDE.read_text(encoding='utf-8')
        self.assertIn('| `23` `CMFPropertyCategoryNoDefault()`', guide)
        self.assertIn("CMFRegisterCategoryNoDefault(p, 'modAcmeIcons_finds', true)", guide)


if __name__ == '__main__':
    unittest.main()
