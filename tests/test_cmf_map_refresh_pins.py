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


class AdapterAsksForIt(unittest.TestCase):
    def test_both_save_paths_rebuild_pins_after_cfg_reload_with_the_games_own_call(self):
        code = cmf_pack.strip_comments(QL)
        self.assertEqual(code.count('MqiAdapterRefreshPins();'), 2)
        for event in ('"thisRegion"', '"filter"'):
            start = code.index('eventName == ' + event)
            part = code[start:code.index('\n\t}\n', start)]
            self.assertIn('QMI_CfgReload();', part)
            self.assertLess(part.index('QMI_CfgReload();'), part.index('MqiAdapterRefreshPins();'))
        filt = code[code.index('eventName == "filter"'):]
        self.assertIn('MqiAdapterRefreshPins();', filt[:filt.index('\n\t}\n')])
        self.assertLess(filt.index('MqiAdapterRefreshPins();'), filt.index('MqiAdapterQlSend();'))
        self.assertRegex(code, r'@addMethod\(CR4MapMenu\)\s*function MqiAdapterRefreshPins\(\)\s*\{\s*UpdateData\(true\);\s*\}')

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
