"""MQI adapter 2.5.0 round 2 (plain unittest; run from tests/)."""
import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import cmf_pack  # noqa: E402

BASE = ROOT / 'source/adapters/map-quest-insight'
LOCAL = BASE / 'modCMFAdapterMapQuestInsight/content/scripts/local'
CMF_WS = LOCAL / 'zz_modcmfadaptermapquestinsight_cmf.ws'
QL_WS = LOCAL / 'zz_modcmfadaptermapquestinsight_questlist.ws'


def code_of(path):
    return cmf_pack.strip_comments(path.read_text())


def body(code, header):
    start = code.index(header)
    i = code.index('{', start)
    depth = 0
    for j in range(i, len(code)):
        if code[j] == '{':
            depth += 1
        elif code[j] == '}':
            depth -= 1
            if depth == 0:
                return code[i + 1:j]
    raise AssertionError(header)


HUD = body(code_of(CMF_WS), 'function MqiAdapterSendCornerHud()')


def _block_end(text, open_at):
    depth = 0
    for i in range(open_at, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return i + 1
    raise ValueError('unbalanced braces')


def clean_branch(hud):
    start = hud.index('if (text == "")')
    return hud[start:_block_end(hud, hud.index('{', start))]


def game_branch(hud):
    start = hud.index('if (text == "")')
    start = _block_end(hud, hud.index('{', start))
    return hud[start:hud.index("MqiAdapterMotion('tracker', 'glow1Color'")]


class CleanCornerHud(unittest.TestCase):
    def test_clean_hides_key_row_and_plate(self):
        clean = clean_branch(HUD)
        self.assertIn("MqiAdapterMotion('tracker', 'show', \"nokeys\", 0)", clean)
        self.assertIn("MqiAdapterMotion('tracker', 'hide', \"plate\", 0)", clean)
        self.assertNotIn('MqiAdapterNextUpdate', clean)
        self.assertNotIn('questPlate', clean)
        self.assertNotIn('CMFGetVersion', HUD)

    def test_clean_raises_tracker(self):
        self.assertIn("MqiAdapterMotion('tracker', 'y', \"\", -58)", clean_branch(HUD))

    def test_quests_box_under_title(self):
        code = code_of(CMF_WS)
        self.assertRegex(code, r"(?s)id = 'mqiQuestsBox';.*CMFDraw\(\"modMapQuestInsight\", 'title', id, 'text'\)")
        box = body(code, 'function MqiAdapterQuestsBox(on : bool)')
        for line in ("'fill', \"\", 723723)", "'alpha', \"\", 0.78)", "'stroke', \"\", 9209726)",
                     "'strokeWidth', \"\", 1)", "'click', \"\", 1)", "'width', \"\", 100)", "'height', \"\", 32)",
                     "GetLocStringByKeyExt(\"mqi_adapter_quests_box\")"):
            self.assertIn(line, box)
        self.assertIn("CMFHasAbility('text', 'click')", box)
        self.assertIn("MqiAdapterQuestsBox(", clean_branch(HUD))

    def test_game_look_sends_none_of_the_clean_keys(self):
        game = game_branch(HUD)
        for key in ("'show', \"nokeys\"", "'hide', \"plate\"", "'y', \"\", -58"):
            self.assertNotIn(key, game)
        self.assertIn("MqiAdapterMotion('tracker', 'y', \"unset\", 0)", game)
        self.assertIn("MqiAdapterMotion('tracker', 'hide', \"unset\", 0)", game)
        self.assertIn("MqiAdapterMotion('tracker', 'show', \"unset\", 0)", game)
        self.assertIn("MqiAdapterQuestsBox(false)", game)

    def test_older_cmf_keeps_the_key_row(self):
        # Without the tracker show ability the key row cannot be hidden: nothing moves, only the quest boxes go.
        clean = clean_branch(HUD)
        self.assertRegex(clean, r"if \(CMFHasAbility\('tracker', 'show'\)\)\s*\{[^}]*nokeys[^}]*'y', \"\", -58\);\s*\}\s*else\s*\{[^}]*'hide', \"plate\"[^}]*\}")

    def test_next_update_still_false(self):
        code = code_of(CMF_WS)
        self.assertEqual(body(code, 'function MqiAdapterNextUpdate() : bool').strip(), 'return false;')

    def test_click_opens_the_quest_list_like_the_f_key(self):
        code = code_of(QL_WS)
        click = body(code, 'function OnDrawingClicked(')
        self.assertRegex(click, r"id == 'mqiQuestsBox'")
        self.assertIn('menu.MqiAdapterQlOpenList();', click)

    def test_string_in_table(self):
        rows = json.loads((BASE / 'strings.json').read_text())['strings']
        row = [r for r in rows if r['key'] == 'mqi_adapter_quests_box']
        self.assertEqual(len(row), 1)
        self.assertEqual(row[0]['text']['en'], 'Quests')


AS_FILE = BASE / 'movie-src/MqiAdapterQuestList.as'


def as3_body(source, name):
    """Body of the first AS3 function called name."""
    m = re.search(r'function\s+' + re.escape(name) + r'\s*\(', source)
    if not m:
        raise AssertionError(name)
    return body(source, source[m.start():])


class QuestListLayout(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.QLWS = QL_WS.read_text()

    def test_panel_is_full_height_and_fixed_width(self):
        self.assertRegex(self.QLWS, r"if \(CMFGetVersion\(\) >= 16\)\s*\{\s*CMFDrawSet\([^;]*'screenTop', \"\", 0\);\s*CMFDrawSet\([^;]*'height', \"\", 1080\);\s*\}\s*else\s*\{\s*CMFDrawSet\([^;]*'screenTop', \"\", 180\);\s*CMFDrawSet\([^;]*'height', \"\", 450\);")
        # 450 survives only in the older-CMF branch (CMF below API 16 cannot hide the title and legend).
        self.assertEqual(code_of(QL_WS).split('function MqiAdapterQlDrawing')[1].split('function')[0].count('450'), 1)
        self.assertIn('PANEL_W:Number = 640', self.AS)

    def test_key_row_clears_the_games_hint_row(self):
        # The game's own bottom hint row takes the last 64 map units; the key row and the list's end sit above it.
        self.assertIn('GAME_HINTS_H:Number = 64;', self.AS)
        self.assertIn('BAR_LINE:Number = 70 + GAME_HINTS_H;', self.AS)
        self.assertIn('placeLine(hints[i],boxH - 44 - GAME_HINTS_H,20 * scale);', self.AS)
        # The list's scrolling area and the hit test both end at the separator line.
        self.assertGreaterEqual(self.AS.count('boxH - BAR_LINE - 8'), 2)

    def test_hide_panels_is_called_only_when_present(self):
        self.assertRegex(self.AS, r'map\.hidePanels is Function')
        self.assertIn('map.hidePanels(["legend","title","hubBar"])', self.AS)
        close = as3_body(self.AS, 'close')
        self.assertIn('map.hidePanels(null)', close)
        self.assertRegex(close, r'hidePanels is Function')

    def test_section_stripes(self):
        for name, value in (('STRIPE_MAIN', '0xFFD402'), ('STRIPE_SECONDARY', '0xFFD402'),
                            ('STRIPE_AVAILABLE', '0xDEB25C'), ('STRIPE_FILTERS', '0xDCD6C8')):
            self.assertRegex(self.AS, name + r':uint = ' + value)
        self.assertNotIn('STRIPE_COLOR', self.AS)

    def test_keys_match_mqi(self):
        keys = as3_body(self.AS, 'handleInput')
        self.assertRegex(keys, r'code == 72[^\n]*\n?[^\n]*toggleRegion\(\)')
        self.assertRegex(keys, r'code == 70[^\n]*close\(\)')
        self.assertRegex(keys, r'code == 84[^\n]*cycleSort\(\)')
        self.assertRegex(keys, r'code == 67[^\n]*fold\(selected\)')
        self.assertRegex(keys, r'code == 69[^\n]*activate\(selected\)')
        self.assertNotRegex(keys, r'code == 72[^\n]*journal')
        self.assertRegex(keys, r'code == 74[^\n]*journal\(selected\)')

    def test_bottom_hints_and_labels_from_strings(self):
        for key in ('close', 'track', 'allRegions', 'sort', 'listTitle', 'collapse', 'objectives', 'on', 'off',
                    'filtersTitle'):
            self.assertIn('word("%s")' % key, self.AS)
        sent = set(re.findall(r'words\.SetMemberFlashString\("(\w+)"', code_of(QL_WS)))
        used = set(re.findall(r'word(?:List)?\("(\w+)"\)', self.AS))
        self.assertEqual(used, sent)
        self.assertNotIn('help', used)

    def test_no_old_header_form_or_help(self):
        self.assertNotIn('"+ "', self.AS)
        self.assertNotIn('"- "', self.AS)
        self.assertNotIn('SHOWN_HELP', self.AS)
        self.assertNotIn('word("help")', self.AS)

    def test_words_are_in_the_string_table_append_only(self):
        rows = json.loads((BASE / 'strings.json').read_text())['strings']
        by_key = {r['key']: r for r in rows}
        for key in ('list_title', 'sort', 'on', 'off', 'filters_title', 'collapse', 'objectives', 'hint_close',
                    'hint_track', 'hint_all_regions'):
            self.assertIn('mqiadapter_ql_' + key, by_key, key)
        self.assertEqual(by_key['mqiadapter_ql_list_title']['text']['en'], 'Quest List')
        self.assertEqual(by_key['mqi_adapter_quests_box']['id'], 2000240030)
        ids = [r['id'] for r in rows]
        self.assertEqual(ids, sorted(ids))
        self.assertEqual(ids, list(range(2000240001, 2000240001 + len(ids))))
        self.assertEqual(by_key['mqiadapter_ql_hint_quests']['id'], 2000240001)

    def test_script_text_rules(self):
        raw = QL_WS.read_bytes()
        self.assertNotIn(b'\r', raw)
        raw.decode('ascii')

    def test_no_in_movie_player_words(self):
        # Key letters only; the on-screen words come from word(...). A phrase of two words in a literal is a stray word.
        literals = re.findall(r'"((?:[^"\\\n]|\\.)*)"', code_of_as(self.AS))
        stray = {l for l in literals if re.fullmatch(r"[A-Za-z]{2,}(?: [A-Za-z]{2,})+", l)}
        self.assertEqual(stray, set())
        for key in ('F', 'E', 'H', 'T', 'C'):
            self.assertIn('"%s"' % key, self.AS)


class QuestListRound3b(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()

    def test_panels_hidden_again_after_an_area_change(self):
        screen = as3_body(self.AS, 'cmfScreen')
        branch = screen[screen.index('curMap() != lastArea'):]
        branch = branch[:branch.index('lastArea = curMap()')]
        self.assertIn('hidePanelsAgain();', branch)
        helper = as3_body(self.AS, 'hidePanelsAgain')
        self.assertRegex(helper, r'map\.hidePanels is Function')
        self.assertIn('map.hidePanels(["legend","title","hubBar"])', helper)

    def test_selected_quest_keeps_its_objectives_on_the_page(self):
        render = as3_body(self.AS, 'render')
        self.assertIn('heightSum(top,selEnd) > avail', render)
        self.assertIn('listTop + avail - (y + h)', render)

    def test_row_at_only_returns_drawn_rows(self):
        self.assertIn('row < top + drawn', as3_body(self.AS, 'rowAt'))
        self.assertIn('drawn = shown;', as3_body(self.AS, 'render'))


def code_of_as(source):
    return re.sub(r'//[^\n]*', '', source)


if __name__ == '__main__':
    unittest.main()
