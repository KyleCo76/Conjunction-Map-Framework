"""CMF API 17: a screen movie asks the map for a game key button picture (map.cmfMakeButton)."""
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tests')]
from test_cmf_movie_hide_panels import as3_body, assert_finds_anchor_on_added_text, simulate_chain

EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
MENU_EDITS = EDITS['red/game/witcher3/menus/worldmap/MapMenu.as']
MENU = simulate_chain(MENU_EDITS)[1]
CORE = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='utf-8')
DOC = (ROOT / 'docs/authors/theme-parts-and-keys.md').read_text(encoding='utf-8')
MOVIE_DOC = (ROOT / 'docs/authors/own-screen-movie.md').read_text(encoding='utf-8')
WIKI = (ROOT / 'docs/wiki/Theme-Parts-and-Keys.md').read_text(encoding='utf-8')
ADAPTER = ROOT / 'source/adapters/map-quest-insight'
AS = (ADAPTER / 'movie-src/MqiAdapterQuestList.as').read_text(encoding='utf-8')


def ws_body(text, name):
    match = re.search(r'^function ' + re.escape(name) + r'\([^)]*\)[^{]*\{', text, re.M)
    assert match, 'missing function ' + name
    depth = 1
    for pos in range(match.end(), len(text)):
        if text[pos] == '{':
            depth += 1
        elif text[pos] == '}':
            depth -= 1
            if not depth:
                return text[match.end():pos]
    raise AssertionError('unclosed ' + name)


class PanelMakeButton(unittest.TestCase):
    def test_map_menu_function(self):
        self.assertIn('public function cmfMakeButton(navCode:String, keyCode:int, label:String) : MovieClip', MENU)
        body = as3_body(MENU, 'cmfMakeButton')
        self.assertIn('.constructor as Class', body)
        self.assertIn('is InputFeedbackButton', body)
        order = [body.index(t) for t in ('setDataFromStage(navCode,keyCode)', '.label = ', 'updateDataFromStage()', 'validateNow()')]
        self.assertEqual(order, sorted(order))
        self.assertIn('catch(err:Error)', body)
        self.assertIn('return null;', body)
        self.assertNotIn('getDefinitionByName', body)

    def test_model_is_a_button_already_on_the_map(self):
        body = as3_body(MENU, 'cmfButtonModel')
        for source in ('this.mcQTButtons', 'this.mcGotoWorldMap', 'this.mcWorldMapButton', 'MapMenu.cmfButtonSeen'):
            self.assertIn(source, body)
        self.assertIn('is InputFeedbackButton', as3_body(MENU, 'cmfFindButton'))
        self.assertIn('return null;', body)

    def test_facade_is_live_movie_only(self):
        facade = as3_body(MENU, 'cmfScreenMap')
        self.assertIn('map.cmfMakeButton = function(navCode:String,keyCode:int,label:String):MovieClip { return menu.cmfMovieButton(state,navCode,keyCode,label); };', facade)
        body = as3_body(MENU, 'cmfMovieButton')
        self.assertIn('if(!this.cmfLiveScreenMovie(state)) { return null; }', body)
        self.assertIn('this.cmfMakeButton(navCode,keyCode,label)', body)

    def test_new_finds_survive_the_whole_chain(self):
        first = next(i for i, e in enumerate(MENU_EDITS) if 'cmfMakeButton' in e['replace'])
        self.assertGreaterEqual(len(MENU_EDITS) - first, 2)
        assert_finds_anchor_on_added_text(self, MENU_EDITS, first)
        # The hidePanels edits are untouched and still come first.
        self.assertTrue(any('hidePanels' in e['replace'] for e in MENU_EDITS[:first]))


class CoreMakeButton(unittest.TestCase):
    def test_version_18(self):
        self.assertIn('function CMFGetVersion() : int { return 18; }', CORE)

    def test_has_ability_screen_button(self):
        body = ws_body(CORE, 'CMFHasAbility')
        self.assertIn("if (part == 'screen' && key == 'button') { return true; }", body)
        # Additive: the older special key stays, and button is no style key of the screen part.
        self.assertIn("if (part == 'map' && key == 'rootValues') { return true; }", body)
        keys = re.search(r"function CMFThemePartKeys\(part : name\) : string\s*\{(.*?)\n\}", CORE, re.S)
        if keys:
            self.assertNotRegex(keys.group(1), r"part == 'screen'[^\n]*button")
        self.assertIn("Version 17 adds ('screen', 'button')", CORE)

    def test_ascii_tabs_lf(self):
        raw = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_bytes()
        self.assertNotIn(b'\r', raw)
        raw.decode('ascii')


class DocsMakeButton(unittest.TestCase):
    def test_author_page(self):
        self.assertIn("`CMFHasAbility('screen', 'button')` (API 17)", DOC)
        self.assertIn('map.cmfMakeButton(navCode, keyCode, label)', DOC)
        self.assertIn('| `map.cmfMakeButton(navCode,keyCode,label)` |', MOVIE_DOC)

    def test_wiki_built(self):
        self.assertIn("`CMFHasAbility('screen', 'button')` (API 17)", WIKI)

    def test_guide_names_the_ability_beside_root_values(self):
        guide = (ROOT / 'docs/authors/icon-pack-guide.md').read_text(encoding='utf-8')
        self.assertIn("CMFHasAbility('map', 'rootValues')", guide)
        self.assertIn("CMFHasAbility('screen', 'button')", guide)

    def test_version_notes_in_the_reference(self):
        reference = (ROOT / 'docs/wiki/API-Reference.md').read_text(encoding='utf-8')
        self.assertIn("- **16**: movie facade `map.hidePanels`, the tracker glow keys", reference)
        self.assertIn("- **17**: `CMFHasAbility('screen', 'button')`, movie facade `map.cmfMakeButton`", reference)
        self.assertNotIn('new theme keys only', reference)


class QuestListButtons(unittest.TestCase):
    def test_call_is_guarded_and_falls_back_to_text(self):
        body = as3_body(AS, 'gameButton')
        self.assertIn('if(!map || !(map.cmfMakeButton is Function) || !nav) { return null; }', body)
        self.assertRegex(body, r'try \{ made = map\.cmfMakeButton\(String\(nav\[0\]\),int\(nav\[1\]\),label\) as MovieClip; \} catch\(error:Error\) \{ made = null; \}')
        self.assertIn('if(!made) { return null; }', body)
        # The text prompts stay: promptButton is the fallback and still names every key.
        self.assertIn('return "[" + promptKey(id) + "] " + label;', as3_body(AS, 'promptButton'))

    def test_nav_and_key_codes_match_the_keys_the_list_takes(self):
        table = re.search(r'PROMPT_NAV:Object = \{(.*?)\};', AS).group(1)
        got = dict((k, (n, int(c))) for k, n, c in re.findall(r'"(\w+)":\["([\w-]+)",(\d+)\]', table))
        self.assertEqual(got, {'close': ('gamepad_L2', 70), 'track': ('enter-gamepad_A', 69), 'region': ('gamepad_X', 72),
                               'sort': ('gamepad_R2', 84), 'objs': ('dpad_right', 39), 'fold': ('gamepad_Y', 67)})
        keys = as3_body(AS, 'handleInput')
        for nav, code in got.values():
            self.assertIn('"%s"' % nav, keys)
            self.assertIn('code == %d' % code, keys)

    def test_footer_and_prompt_use_the_button(self):
        bar = as3_body(AS, 'drawHintBar')
        self.assertIn('gameButton("foot" + i,ids[i],words[i])', bar)
        self.assertIn('hints[i].visible = !made;', bar)
        render = as3_body(AS, 'render')
        self.assertIn('hideButtons();', render)
        self.assertIn('promptPicture(s,objId,objWord,', render)
        place = as3_body(AS, 'promptPicture')
        # Fold and Objectives keep a place each, so moving between header and quest rows reuses both buttons.
        self.assertIn('gameButton("row_" + id,id,label)', place)
        self.assertIn('s.obj.visible = false;', place)

    def test_keyboard_objectives_cap_shows_a_triangle(self):
        gb = as3_body(AS, 'gameButton')
        self.assertIn('"cap":id == "objs" && !pad', gb)
        self.assertIn('if(held.cap) { capTriangle(held); }', as3_body(AS, 'dressButton'))
        body = as3_body(AS, 'capTriangle')
        self.assertIn('try', body)
        self.assertIn('"tfKeyLabel"', as3_body(AS, 'capField'))
        self.assertIn('size = CAP_TRIANGLE * box.height;', body)
        self.assertIn('CAP_TRIANGLE:Number = 0.42;', AS)
        self.assertIn('textColor', body)
        self.assertIn('.visible = false;', body)

    def test_buttons_follow_the_device_and_leave_with_the_list(self):
        gb = as3_body(AS, 'gameButton')
        self.assertIn('(pad ? (playStation ? "ps" : "pad") : "kb")', gb)
        self.assertIn('dropButtons();', as3_body(AS, 'onRemoved'))

    def test_adapter_does_not_need_api_17(self):
        for path in ADAPTER.rglob('*.ws'):
            self.assertNotRegex(path.read_text(encoding='utf-8'), r'CMFGetVersion\(\) >= 17|CMFRequireVersion\([^)]*17')


if __name__ == '__main__':
    unittest.main()
