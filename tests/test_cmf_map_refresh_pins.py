"""CMF API 17 (additive): CMFMapRefreshPins rebuilds the open map's pins; the MQI adapter asks for it after a filter save."""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tests'), str(ROOT / 'tools')]
import cmf_pack
from test_cmf_make_button import ws_body

CORE = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='utf-8')
QL = (ROOT / 'source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/'
      'zz_modcmfadaptermapquestinsight_questlist.ws').read_text(encoding='utf-8')
TOOL = (ROOT / 'tools/cmf_author_docs.py').read_text(encoding='utf-8')
ASK = "CMFHasAbility('map', 'refreshPins')"


class CoreRefreshPins(unittest.TestCase):
    def test_map_menu_method_runs_the_full_pin_build(self):
        match = re.search(r'@addMethod\(CR4MapMenu\)\nfunction CMFRefreshPins\(\)[^{]*\{(.*?)\n\}', CORE, re.S)
        self.assertTrue(match)
        self.assertEqual(match.group(1).strip(), 'UpdateData(true);')

    def test_core_method_needs_an_open_map(self):
        match = re.search(r'public function RefreshPins\(\) : bool\n\t\{(.*?)\n\t\}', CORE, re.S)
        self.assertTrue(match)
        text = match.group(1)
        self.assertIn('if (!spaceMenu)', text)
        self.assertLess(text.index('return false;'), text.index('spaceMenu.CMFRefreshPins();'))
        self.assertIn('return true;', text)

    def test_global_function(self):
        self.assertIn('return theGame.CMFGetCore().RefreshPins();', ws_body(CORE, 'CMFMapRefreshPins'))
        self.assertIn('function CMFMapRefreshPins() : bool', CORE)
        self.assertLess(CORE.index('function CMFMapRefresh()'), CORE.index('function CMFMapRefreshPins()'))
        self.assertIn('Version 17 (additive, same API 17)', CORE)

    def test_ability_key_and_version(self):
        self.assertIn("if (part == 'map' && key == 'refreshPins') { return true; }", ws_body(CORE, 'CMFHasAbility'))
        self.assertIn('function CMFGetVersion() : int { return 17; }', CORE)


    def test_pack_checker_dates_the_call_to_api_17(self):
        # The wiki's API reference reads its "Since" column from cmf_pack.VERSION<n>.
        self.assertIn('CMFMapRefreshPins', cmf_pack.VERSION17)
        self.assertIn('CMFMapRefreshPins', cmf_pack.API)
        report = cmf_pack.Report()
        cmf_pack.check_script('test.ws', 'CMFMapRefreshPins();', 'modA', report, [], set())
        self.assertEqual(report.errors, [])
        self.assertTrue(any('compiles only with CMF API 17' in n for n in report.notes))
        wiki = (Path(__file__).resolve().parents[1] / 'docs' / 'wiki' / 'API-Reference.md').read_text(encoding='utf-8')
        self.assertIn('| `CMFMapRefreshPins() : bool` | 17 |', wiki)

class AdapterAsksForIt(unittest.TestCase):
    def test_only_the_filter_path_rebuilds_pins_after_cfg_reload_with_the_games_own_call(self):
        code = cmf_pack.strip_comments(QL)
        self.assertEqual(code.count('MqiAdapterRefreshPins();'), 1)
        filt = code[code.index('eventName == "filter"'):]
        filt = filt[:filt.index('\n\t}\n')]
        self.assertLess(filt.index('QMI_CfgReload();'), filt.index('MqiAdapterRefreshPins();'))
        self.assertLess(filt.index('MqiAdapterRefreshPins();'), filt.index('MqiAdapterQlSend();'))
        self.assertRegex(code, r'@addMethod\(CR4MapMenu\)\s*function MqiAdapterRefreshPins\(\)\s*\{\s*UpdateData\(true\);\s*\}')

    def test_filter_marks_the_minimap_quest_records_dirty_after_the_rebuild_like_mqi(self):
        code = cmf_pack.strip_comments(QL)
        filt = code[code.index('eventName == "filter"'):]
        filt = filt[:filt.index('\n\t}\n')]
        self.assertIn('QMI_MmQuestDirtyHud();', filt)
        self.assertLess(filt.index('MqiAdapterRefreshPins();'), filt.index('QMI_MmQuestDirtyHud();'))
        self.assertEqual(code.count('QMI_MmQuestDirtyHud();'), 1)

    def test_this_region_saves_and_resends_the_list_without_a_pin_build(self):
        code = cmf_pack.strip_comments(QL)
        part = code[code.index('eventName == "thisRegion"'):]
        part = part[:part.index('\n\t}\n')]
        self.assertIn('QMI_CfgReload();', part)
        self.assertIn('MqiAdapterQlSend();', part)
        self.assertNotIn('MqiAdapterRefreshPins', part)
        self.assertNotIn('UpdateData', part)

    def test_adapter_scripts_name_no_api_17_function(self):
        # A call to a function an older core does not declare is a compile error for everyone on that CMF.
        import glob
        for path in glob.glob(str(ROOT / 'source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/*.ws')):
            code = cmf_pack.strip_comments(open(path, encoding='utf-8').read())
            for name in ('CMFMapRefreshPins', 'CMFRefreshPins', 'refreshPins', 'cmfMakeButton'):
                self.assertNotIn(name, code, (path, name))

    def test_text_rules(self):
        raw = QL.encode('utf-8')
        self.assertNotIn(b'\r', raw)
        raw.decode('ascii')


class Docs(unittest.TestCase):
    def test_pages_name_both(self):
        for page in ('own-screen-movie.md', 'theme-parts-and-keys.md'):
            text = (ROOT / 'docs/authors' / page).read_text(encoding='utf-8')
            self.assertIn('CMFMapRefreshPins()', text)
            self.assertIn(ASK, text)
            self.assertIn('API 17', text)
        wiki = (ROOT / 'docs/wiki/Theme-Parts-and-Keys.md').read_text(encoding='utf-8')
        self.assertIn('CMFMapRefreshPins()', wiki)

    def test_version_notes(self):
        self.assertIn("`CMFMapRefreshPins()`", TOOL)
        self.assertIn("`CMFHasAbility('map', 'refreshPins')`", TOOL)


if __name__ == '__main__':
    unittest.main()
