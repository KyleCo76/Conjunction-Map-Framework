"""MQI adapter 2.5.1 round 2 (plain unittest; run from tests/)."""
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
                     "\"[F] \" + GetLocStringByKeyExt(\"panel_title_journal_quest\")"):
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

    def test_next_update_is_the_qmiv230_group(self):
        code = code_of(CMF_WS)
        self.assertEqual(body(code, 'function MqiAdapterNextUpdate() : bool').strip(),
                         "return theGame.GetInGameConfigWrapper().GetGroupIdx('qmiV230') >= 0;")

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
        self.assertIn('return GAME_HINTS_H + footerH();', self.AS)
        self.assertIn('placeLine(hints[i],boxH - GAME_HINTS_H - footerH() / 2,footFont());', self.AS)
        # The list's scrolling area and the hit test both end at the separator line.
        self.assertGreaterEqual(self.AS.count('boxH - barLine() - 8'), 2)

    def test_hide_panels_is_called_only_when_present(self):
        self.assertRegex(self.AS, r'map\.hidePanels is Function')
        self.assertIn('map.hidePanels(["legend","title","hubBar"])', self.AS)
        close = as3_body(self.AS, 'close')
        self.assertIn('map.hidePanels(null)', close)
        self.assertRegex(close, r'hidePanels is Function')

    def test_section_stripes(self):
        # By section key since 2.5.1 (the values are pinned in MqiQuestListValues).
        self.assertIn('private function stripeOf(cat:String) : uint', self.AS)
        self.assertNotIn('STRIPE_COLOR', self.AS)
        self.assertIn('gradientBar(INSET,y,wide,h,stripeOf(key));', self.AS)
        self.assertIn('key = String(r.cat);', self.AS)

    def test_keys_match_mqi(self):
        keys = as3_body(self.AS, 'handleInput')
        self.assertRegex(keys, r'code == 72[^\n]*\n?[^\n]*toggleRegion\(\)')
        self.assertRegex(keys, r'code == 70[^\n]*close\(\)')
        self.assertRegex(keys, r'code == 84[^\n]*cycleSort\(\)')
        self.assertRegex(keys, r'code == 67[^\n]*fold\(selected\)')
        self.assertRegex(keys, r'code == 69[\s\S]*?activate\(selected\)')
        self.assertNotRegex(keys, r'journal')

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


class QuestListKeysAndPrompts(unittest.TestCase):
    """Quest List keys and prompts at Map Quest Insight 2.2.0's values (adapter 2.5.1)."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.KEYS = as3_body(cls.AS, 'handleInput')

    def test_no_journal_action_left_in_the_movie(self):
        self.assertNotIn('function journal(', self.AS)
        self.assertNotIn('note("journal"', self.AS)
        self.assertNotRegex(self.KEYS, r'code == 74|gamepad_X"\) \{ journal')

    def test_keyboard_codes_and_pad_buttons(self):
        keys = self.KEYS
        for text in ('code == 70', 'code == 27', 'code == 69', 'code == 13', 'code == 72', 'code == 84', 'code == 67',
                     'code == 39', 'code == 37',
                     '"gamepad_L2"', '"gamepad_R2"', '"gamepad_X"', '"gamepad_Y"', '"enter-gamepad_A"',
                     '"escape-gamepad_B"', '"dpad_right"', '"dpad_left"'):
            self.assertIn(text, keys)

    def test_close_f_and_lt_on_key_down_esc_and_b_on_key_up(self):
        keys = self.KEYS
        self.assertIn('details.value == "keyUp"', keys)
        up = keys[keys.index('"keyUp"'):]
        up = up[:up.index('return;')]
        self.assertRegex(up, r'code == 27')
        self.assertRegex(up, r'"escape-gamepad_B"')
        self.assertRegex(up, r'close\(\)')
        self.assertNotRegex(up, r'code == 70|gamepad_L2')
        down = keys[keys.index('code == 70'):]
        down = down[:down.index('\n')]
        self.assertIn('gamepad_L2', down)
        self.assertIn('close()', down)
        self.assertNotIn('code == 27', down)

    def test_region_track_sort_fold(self):
        keys = self.KEYS
        self.assertRegex(keys, r'code == 72 \|\| nav == "gamepad_X"\) \{ toggleRegion\(\); \}')
        self.assertRegex(keys, r'code == 13 \|\| code == 69 \|\| nav == "enter-gamepad_A"\)\s*\{\s*if\(padA && selected >= 0 && selected < rows.length && rows\[selected\].type == ROW_CAT\)[^\n]*\s*else\s*\{[\s\S]*?activate\(selected\);\s*\}\s*\}')
        self.assertRegex(keys, r'code == 84 \|\| nav == "gamepad_R2"\) \{ cycleSort\(\); \}')
        self.assertRegex(keys, r'code == 67 \|\| nav == "gamepad_Y"')

    def test_right_toggles_objectives_left_closes_them(self):
        keys = self.KEYS
        self.assertIn('private function objectivesOpen(open:Boolean) : void', self.AS)
        self.assertIn('private function toggleObjectives() : void', self.AS)
        # Since 2.5.5 the D-pad's direction-coded twin is dropped and the stick is found by fromJoystick (tests/test_mqi_pad_fix.py).
        self.assertIn('stick = arrow != "" && details.fromJoystick == true;', keys)
        self.assertRegex(keys, r'code == 37 \|\| code == 39 \|\| nav == "dpad_left" \|\| nav == "dpad_right"\) \{ sideKey\(pad != "" \? pad : arrow,pad != ""\); \}')
        self.assertTrue(keys.rstrip().endswith('event.handled = true;'))

    def test_keyboard_left_only_closes_pad_left_is_swallowed(self):
        body = as3_body(self.AS, 'sideKey')
        self.assertIn('r.type == ROW_QUEST', body)
        self.assertIn('if(dpad && dir == "left") { return; }', body)
        self.assertIn('if(dir == "right") { toggleObjectives(); }', body)
        self.assertIn('else { objectivesOpen(false); }', body)
        self.assertIn('else if(r.type == ROW_CAT) { fold(selected); }', body)

    def test_device_from_key_events_and_the_game(self):
        self.assertIn('private function learnDevice(code:int, nav:String) : void', self.AS)
        learn = as3_body(self.AS, 'learnDevice')
        for prefix in ('"gamepad_"', '"enter-gamepad_"', '"escape-gamepad_"'):
            self.assertIn(prefix, learn)
        self.assertIn('setDevice(', learn)
        self.assertIn('private function setDevice(isPad:Boolean, isPs:Boolean) : void', self.AS)
        setter = as3_body(self.AS, 'setDevice')
        self.assertIn('render()', setter)
        self.assertIn('isGamepad()', self.AS)
        self.assertIn('gamepadType', self.AS)
        self.assertIn('managerDevice()', as3_body(self.AS, 'onFrame'))
        self.assertIn('learnDevice(code,nav);', self.KEYS)

    def test_prompts_are_drawn_by_one_helper(self):
        self.assertIn('PROMPT_KEYS[id]', as3_body(self.AS, 'promptKey'))
        self.assertIn('promptKey(id)', as3_body(self.AS, 'promptButton'))
        table = re.search(r'PROMPT_KEYS:Object = \{(.*?)\};', self.AS, re.S).group(1)
        got = dict((k, v.split(',')) for k, v in
                   re.findall(r'"(\w+)":\[([^\]]*)\]', table.replace('"', '"')))
        norm = {k: [x.strip().strip('"') for x in v] for k, v in got.items()}
        self.assertEqual(norm, {'close': ['F', 'LT', 'L2'], 'track': ['E', 'A', 'Cross'],
                                'region': ['H', 'X', 'Square'], 'sort': ['T', 'RT', 'R2'],
                                'objs': ['>', 'D-pad Right', 'D-pad Right'], 'fold': ['C', 'Y', 'Triangle']})
        # Nothing else builds a "[key]" text, so the helper is the one place to swap for the game's pictures.
        self.assertEqual(len(re.findall(r'"\[" \+', self.AS)), 1)
        self.assertEqual(len(re.findall(r'promptButton\(', self.AS)), 4)  # the helper, the footer, Objectives, fold

    def test_footer_words_order_and_style(self):
        bar = as3_body(self.AS, 'drawHintBar')
        self.assertIn('var ids:Array = ["close","track","region","sort"];', bar)
        self.assertRegex(bar, r'words:Array = \[word\("close"\),word\("track"\),thisRegion \? word\("allRegions"\) : word\("thisRegion"\),word\("sort"\)\]')
        self.assertIn('FOOT_LABEL', bar)
        self.assertIn('FOOT_LABEL:uint = 0xDCD6C8', self.AS)
        self.assertIn('FOOT_FONT:Number = 28', self.AS)
        self.assertIn('FOOT_GAP:Number = 24', self.AS)
        self.assertIn('FOOT_SCALE:Number = 0.78', self.AS)
        self.assertIn('PANEL_W - 40', bar)
        self.assertIn('(PANEL_W - total * k) / 2', bar)
        self.assertIn('return px(FOOT_FONT * FOOT_SCALE);', as3_body(self.AS, 'footFont'))
        self.assertNotIn('"F","E","H","T"', self.AS)

    def test_sort_line_has_t_on_the_keyboard_only(self):
        title = as3_body(self.AS, 'drawTitleBlock')
        self.assertIn('(pad ? "" : span(" [" + promptKey("sort") + "]"', title)
        self.assertNotIn('" [T]"', title)

    def test_objectives_prompt_place(self):
        render = as3_body(self.AS, 'render')
        self.assertIn('objLabel = span(promptButton("objs",word("objectives")),FOOT_LABEL,px(18),false);', render)
        self.assertIn('OBJ_PROMPT_GAP:Number = 14;', self.AS)
        self.assertIn('REGION_MIN_W:Number = 40;', self.AS)
        # Only the selected quest row, only when the quest has objectives.
        self.assertRegex(render, r'i == selected && !r\.q\.avail && r\.q\.objs is Array && \(r\.q\.objs as Array\)\.length > 0')
        # Second line, right-aligned: 14 px left of the distance text, or at W-28 when there is none.
        self.assertIn('s.obj.x = r.type == ROW_QUEST ? (distHtml != "" ? s.dist.x + 2 - OBJ_PROMPT_GAP : ROW_RIGHT) + 2 - s.obj.width', render)
        self.assertIn('ROW_RIGHT:Number = 612;', self.AS)
        self.assertIn('placeLine(s.obj,r.type == ROW_QUEST ? y + h * 0.69 : y + h / 2,px(18));', render)
        # The region text is clipped to make room, never narrower than 40 px.
        self.assertIn('Math.min(330,Math.max(REGION_MIN_W,s.obj.x - OBJ_PROMPT_GAP / 2 - s.right.x)) : 330;', render)
        self.assertIn('promptButton("fold",word("collapse")),FOOT_LABEL,', render)
        learn = as3_body(self.AS, 'learnDevice')
        self.assertIn('nav.indexOf("dpad_") == 0', learn)
        self.assertIn('code >= 37 && code <= 40', learn)
        self.assertIn('s.right.autoSize = TextFieldAutoSize.NONE;', render)
        self.assertNotIn('triangle(s.obj.x - 4', render)

    def test_fold_prompt_uses_the_helper(self):
        self.assertIn('promptButton("fold",word("collapse"))', self.AS)


class QuestListSlotsAndBacking(unittest.TestCase):
    """Reused row slots start clean on a row-type change; the backing is one piece on every render (adapter 2.5.1)."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.RENDER = as3_body(cls.AS, 'render')

    def test_slot_reset_clears_picture_scale_tint_and_filters(self):
        reset = as3_body(self.AS, 'resetSlot')
        # The old picture goes with its Loader: a fresh one (scale 1, hidden) takes its place.
        self.assertIn('newLoader(s);', reset)
        self.assertIn('old.unload();', as3_body(self.AS, 'newLoader'))
        self.assertIn('s.icon.scaleX = s.icon.scaleY = 1;', reset)
        self.assertIn('s.icon.transform.colorTransform = new ColorTransform();', reset)
        # No filter is ever set on a row picture (see QuestListFifthStart).
        self.assertNotIn('.filters', reset)
        self.assertIn('s.url = "";', reset)
        self.assertIn('if(s.type == type) { return; }', reset)

    def test_slot_reset_runs_on_every_row_type_change(self):
        self.assertRegex(self.RENDER, r'resetSlot\(s,r\.type\);')
        # Before the row's own picture is set, and slots left unused forget their type.
        self.assertLess(self.RENDER.index('resetSlot(s,r.type);'), self.RENDER.index('switch(r.type)'))
        self.assertRegex(self.RENDER, r'slots\[j\]\.type = -1;')
        self.assertIn('"url":"","type":-1', self.AS)

    def test_new_picture_stays_hidden_until_loaded(self):
        self.assertIn('s.loader.visible = false;', as3_body(self.AS, 'newLoader'))
        self.assertIn('s.loader.visible = !(s.grey && s.greyPic);', as3_body(self.AS, 'fitIcon'))
        self.assertIn('if(!s.loader.content ||', as3_body(self.AS, 'fitIcon'))

    def test_backing_is_one_piece_per_render(self):
        plate = as3_body(self.AS, 'drawPlate')
        self.assertEqual(plate.count('drawRect(0,0,boxW,boxH)'), 1)
        self.assertIn('g.clear();', plate)
        self.assertIn('beginFill(PLATE_COLOR,conf("fullScreen") ? 0.68 : 0.78)', plate)
        self.assertIn('drawPlate();', self.RENDER)
        self.assertEqual(self.AS.count('PLATE_COLOR,'), 1)
        self.assertIn('PLATE_COLOR:uint = 0x0B0B0B;', self.AS)
        # Nothing else adds a second backing: bg is the only sprite of the plate and it is made once.
        self.assertEqual(self.AS.count('bg = new Sprite();'), 1)

    def test_list_sits_above_the_map_pins_when_it_can(self):
        top = as3_body(self.AS, 'toFront')
        self.assertIn('setChildIndex(this,parent.numChildren - 1)', top)
        self.assertIn('try', top)
        self.assertIn('toFront();', self.RENDER)

    def test_quests_available_rows_follow_the_filters(self):
        ws = code_of(QL_WS)
        avail = body(ws, 'function MqiAdapterQlAvailable(')
        # MQI's own rule: a row is skipped when its quest is hidden by category at the row's level (Contracts off
        # drops a contract's row, Treasure off the treasure rows); counts are untouched.
        self.assertRegex(avail, r'journalQuest && QMI_QuestHiddenByCategory\(journalQuest, level\)')
        self.assertIn('continue;', avail)
        self.assertLess(avail.index('QMI_QuestHiddenByCategory'), avail.index('row = storage.CreateTempFlashObject()'))
        # The same send after a filter change rebuilds them, after the config is reloaded.
        event = body(ws, 'function MqiAdapterQlEvent(')
        flt = event[event.index('if (eventName == "filter")'):]
        flt = flt[:flt.index('qaPick')]
        self.assertLess(flt.index('QMI_CfgReload();'), flt.index('MqiAdapterQlSend();'))


class QuestListRetest251(unittest.TestCase):
    """Kyle's 2.5.1 retest of e91188d: one picture per slot, the legend stays hidden after a pin build, and the
    keyboard's key pictures with a bare triangle in the Objectives cap."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.CODE = code_of_as(cls.AS)
        cls.RENDER = as3_body(cls.AS, 'render')

    # 1. Scroll redraw: a slot's picture holder holds exactly one Loader, replaced (never reloaded) on a new picture.
    def test_one_loader_per_slot_replaced_on_every_new_picture(self):
        fresh = as3_body(self.AS, 'newLoader')
        self.assertIn('old.contentLoaderInfo.removeEventListener(Event.COMPLETE,iconLoaded);', fresh)
        self.assertIn('try { old.close(); } catch(error:Error) { }', fresh)
        self.assertIn('try { old.unload(); } catch(error:Error) { }', fresh)
        self.assertIn('while(s.icon.numChildren > 0) { s.icon.removeChildAt(0); }', fresh)
        self.assertIn('s.loader = new Loader();', fresh)
        self.assertIn('s.icon.addChild(s.loader);', fresh)
        self.assertIn('s.greyOn = false;', fresh)
        self.assertLess(fresh.index('removeChildAt(0)'), fresh.index('s.icon.addChild(s.loader);'))
        # The only places a Loader is made or added: newLoader, used by the slot, the type reset and a new picture.
        self.assertEqual(self.CODE.count('new Loader()'), 1)
        self.assertEqual(self.CODE.count('addChild(s.loader)'), 1)
        # The holder gets only the Loader (newLoader) and the grey copy of that Loader's picture (fitIcon), and
        # newLoader empties it before either goes in again.
        self.assertEqual(self.CODE.count('.icon.addChild('), 2)
        self.assertIn('s.icon.addChild(s.greyPic);', as3_body(self.AS, 'fitIcon'))
        self.assertIn('newLoader(s);', as3_body(self.AS, 'slot'))
        self.assertIn('newLoader(s);', as3_body(self.AS, 'resetSlot'))
        load = self.RENDER[self.RENDER.index('if(s.url != iconUrl)'):]
        load = load[:load.index('fitIcon(s);')]
        self.assertLess(load.index('newLoader(s);'), load.index('s.loader.load(new URLRequest(iconUrl))'))
        # A finished load counts only for the slot's current Loader.
        loaded = as3_body(self.AS, 'iconLoaded')
        self.assertIn('s.loader.contentLoaderInfo == event.target', loaded)
        self.assertIn('fitIcon(s);', loaded)

    def test_backing_covers_the_whole_list_box(self):
        plate = as3_body(self.AS, 'drawPlate')
        self.assertIn('g.drawRect(0,0,boxW,boxH);', plate)
        # Rows draw no backing of their own (the selection fill and the section bars sit on the plate).
        self.assertLess(self.RENDER.index('drawPlate();'), self.RENDER.index('for(i = top; i < rows.length; i++)'))

    # 2. The legend: hidden again on every value while open, for a second after it, and when the map's pins change.
    def test_panels_hidden_again_after_a_pin_build(self):
        take = as3_body(self.AS, 'take')
        self.assertIn('if(opened) { rehide(); }', take)
        again = as3_body(self.AS, 'rehide')
        self.assertIn('hidePanelsAgain();', again)
        self.assertIn('rehideUntil = getTimer() + 1000;', again)
        frame = as3_body(self.AS, 'onFrame')
        self.assertLess(frame.index('if(!map || !opened) { return; }'), frame.index('if(rehideUntil > 0)'))
        self.assertIn('hidePanelsAgain();', frame[frame.index('if(rehideUntil > 0)'):])
        pins = frame[frame.index('if(pins && pins !== pinsRef'):]
        self.assertLess(pins.index('rehide();'), pins.index('snapshot();'))
        self.assertIn('rehideUntil = 0;', as3_body(self.AS, 'close'))
        self.assertIn('rehideUntil = 0;', as3_body(self.AS, 'onRemoved'))

    def test_script_sends_the_list_after_each_pin_build(self):
        event = body(code_of(QL_WS), 'function MqiAdapterQlEvent(')
        part = event[event.index('if (eventName == "filter")'):]
        part = part[:part.index('return;')]
        self.assertLess(part.index('MqiAdapterRefreshPins();'), part.index('MqiAdapterQlSend();'))
        this_region = event[event.index('if (eventName == "thisRegion")'):]
        this_region = this_region[:this_region.index('return;')]
        self.assertIn('MqiAdapterQlSend();', this_region)
        self.assertNotIn('MqiAdapterRefreshPins', this_region)

    # 3. Keyboard: the hint row's key pictures, and the Objectives cap's text hidden again whenever it comes back.
    def test_buttons_take_the_hint_rows_key_pictures(self):
        gb = as3_body(self.AS, 'gameButton')
        self.assertLess(gb.index('keyPicture(made);'), gb.index('addChild(made);'))
        pic = as3_body(self.AS, 'keyPicture')
        self.assertIn('"clickable" in made', pic)
        self.assertIn('made["clickable"] = false;', pic)
        self.assertIn('made["updateDataFromStage"]();', pic)
        self.assertIn('made["validateNow"]();', pic)
        self.assertIn('catch(error:Error) { }', pic)
        # The text fallback stays only for a missing ability or no button.
        self.assertIn('hints[i].visible = !made;', as3_body(self.AS, 'drawHintBar'))

    def test_buttons_are_dressed_again_every_frame(self):
        self.assertIn('dressButtons();', as3_body(self.AS, 'onFrame'))
        gb = as3_body(self.AS, 'gameButton')
        self.assertIn('dressButton(held);', gb[:gb.index('dropButton(place);')])
        self.assertIn('dressButton(held);', gb[gb.index('buttons[place] = held;'):])
        dress = as3_body(self.AS, 'dressButton')
        self.assertIn('textColor = FOOT_LABEL', dress)
        self.assertIn('if(held.cap) { capTriangle(held); }', dress)

    def test_cap_triangle_is_one_shape_and_hides_the_cap_each_time(self):
        cap = as3_body(self.AS, 'capTriangle')
        self.assertIn('var mark:Shape = held.mark as Shape;', cap)
        self.assertIn('if(!mark) { mark = new Shape(); }', cap)
        self.assertIn('mark.graphics.clear();', cap)
        self.assertIn('held.mark = mark;', cap)
        self.assertIn('cap.visible = false;', cap)
        self.assertIn('cap = capField(held,made);', cap)
        self.assertIn('if(!cap) { return; }', cap)
        self.assertEqual(self.CODE.count('new Shape()'), 1)
        field = as3_body(self.AS, 'capField')
        self.assertIn('made["tfKeyLabel"] as TextField', field)
        self.assertIn('if(found) { return found; }', as3_body(self.AS, 'capSearch'))


class QuestListThirdStart(unittest.TestCase):
    """Kyle's third start (759b9be): the Objectives cap's triangle in the hint row look, the header bars' width, and
    the selection kept by row key after any rebuild, as in Map Quest Insight 2.2.0."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.CODE = code_of_as(cls.AS)
        cls.RENDER = as3_body(cls.AS, 'render')

    # 1. The hint row look keeps tfKeyLabel hidden and shows its key text ("Right") in another field: a hidden
    # tfKeyLabel must not end the search, and the triangle is shown on top of the button each time.
    def test_cap_found_past_a_hidden_tfkeylabel(self):
        field = as3_body(self.AS, 'capField')
        self.assertIn('if(shownText(cap)) { return cap; }', field)
        self.assertEqual(field.count('if(shownText(cap)) { return cap; }'), 2)
        self.assertNotRegex(field, r'if\(!cap[^)]*\) \{ return')
        self.assertIn('return capSearch(made,made,label,labelLeft,0);', field)
        self.assertLess(field.index('held.capField as TextField'), field.index('made["tfKeyLabel"]'))
        self.assertLess(field.index('made["tfKeyLabel"]'), field.index('capSearch('))
        search = as3_body(self.AS, 'capSearch')
        self.assertIn('child !== label', search)
        self.assertIn('child.getBounds(made).right <= labelLeft + 4', search)
        self.assertIn('depth > 4', search)
        self.assertIn('return f != null && f.visible && f.text != "";', as3_body(self.AS, 'shownText'))

    def test_triangle_is_shown_on_top_and_the_cap_hidden(self):
        cap = as3_body(self.AS, 'capTriangle')
        self.assertIn('mark.visible = true;', cap)
        self.assertIn('mark.graphics.beginFill(cap.textColor,1);', cap)
        self.assertIn('size = CAP_TRIANGLE * box.height;', cap)
        self.assertGreaterEqual(cap.count('made.addChild(mark);'), 2)
        self.assertLess(cap.index('mark.visible = true;'), cap.index('cap.visible = false;'))
        self.assertIn('made.getChildIndex(mark) < made.numChildren - 1', cap)
        self.assertIn('dressButtons();', as3_body(self.AS, 'onFrame'))

    # 2. Header bars: full width on every render, from constants only (nothing kept between renders).
    def test_header_bars_use_the_full_width_every_render(self):
        self.assertIn('var wide:Number = PANEL_W - 2 * INSET;', self.RENDER)
        self.assertIn('gradientBar(INSET,y,wide,h,stripeOf(key));', self.RENDER)
        self.assertIn('bar.graphics.clear();', self.RENDER)
        bar = as3_body(self.AS, 'gradientBar')
        self.assertIn('m.createGradientBox(w,h,0,x,y);', bar)
        self.assertIn('[1,0.85,0.22],[0,110,255]', bar)
        self.assertIn('bar.graphics.drawRect(x,y,w,h);', bar)
        self.assertEqual(self.CODE.count('gradientBar('), 2)

    # 3. Selection after a rebuild: the same key, else the same index clamped to the last row; minimal scroll.
    def test_selection_kept_by_key_then_clamped_index(self):
        build = as3_body(self.AS, 'build')
        keep = build[build.index('selected = -1;'):]
        self.assertLess(keep.index('Number(rows[i].q.i) == keepId'), keep.index('rowKey(rows[i]) == keepKey'))
        self.assertLess(keep.index('rowKey(rows[i]) == keepKey'), keep.index('if(selected < 0 && keepIndex >= 0)'))
        self.assertIn('if(selected < 0 && keepIndex >= 0) { selected = Math.max(0,Math.min(keepIndex,rows.length - 1)); }', keep)
        key = as3_body(self.AS, 'rowKey')
        self.assertIn('String(r.q.i)', key)
        self.assertIn('String(r.cat) + ":" + String(r.k)', key)
        self.assertIn('build(selectedQuestId(),selectedKey(),selected);', as3_body(self.AS, 'buildKept'))

    def test_every_rebuild_keeps_the_selection(self):
        take = as3_body(self.AS, 'take')
        self.assertIn('var keepIndex:int = rows.length > 0 ? selected : -1;', take)
        self.assertIn('build(keepId,keepKey,keepIndex);', take)
        for name in ('rebuild', 'toggleRegion', 'cycleSort'):
            self.assertIn('buildKept();', as3_body(self.AS, name))
        self.assertIn('build(-1,rowKey(r),selected);', as3_body(self.AS, 'followObjectives'))
        # The old index-only keep is gone.
        self.assertNotIn('selected = Math.min(keep,rows.length - 1);', self.AS)

    def test_scroll_moves_only_as_far_as_the_selection_needs(self):
        self.assertIn('if(selected < top) { top = selected; }', self.RENDER)
        self.assertIn('while(top < selected && heightSum(top,selEnd) > avail) { top++; }', self.RENDER)
        self.assertNotIn('top = 0;', self.CODE)


class QuestListFourthStart(unittest.TestCase):
    """Kyle's fourth start (c4117b2): the Heroes' Pursuits symbol after a redraw."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.CODE = code_of_as(cls.AS)
        cls.RENDER = as3_body(cls.AS, 'render')

    def test_picture_shows_once_its_fresh_loader_has_content(self):
        fit = as3_body(self.AS, 'fitIcon')
        self.assertIn('if(!s.loader.content || !(s.loader.content.width > 0)) { return; }', fit)
        self.assertNotIn('s.ready', self.CODE)
        self.assertIn('s.loader.visible = !(s.grey && s.greyPic);', fit)


class QuestListFifthStart(unittest.TestCase):
    """Kyle's fifth start (578c3eb): the Heroes' Pursuits helmet vanished when its row moved (a section header went)
    and came back only on a full stage redraw (alt-tab), so the grey filter's cached image was not redrawn. The grey
    is now drawn once into a bitmap; no row picture carries a filter."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.CODE = code_of_as(cls.AS)
        cls.RENDER = as3_body(cls.AS, 'render')

    def test_no_filter_on_any_row_picture(self):
        # The only filter use left is applyFilter on the bitmap, in greyCopy.
        self.assertNotRegex(self.CODE, r'\.filters\s*=')
        self.assertEqual(self.CODE.count('new ColorMatrixFilter(GREY_MATRIX)'), 1)
        grey = as3_body(self.AS, 'greyCopy')
        self.assertIn('data.draw(content,m);', grey)
        self.assertIn('data.applyFilter(data,data.rect,new Point(0,0),new ColorMatrixFilter(GREY_MATRIX));', grey)
        self.assertIn('pic = new Bitmap(data,"auto",true);', grey)
        self.assertLess(grey.index('data.draw(content,m);'), grey.index('data.applyFilter('))

    def test_failed_or_empty_draw_shows_the_picture_ungreyed(self):
        grey = as3_body(self.AS, 'greyCopy')
        self.assertIn('try', grey)
        self.assertIn('catch(error:Error)', grey)
        self.assertIn('data.getColorBoundsRect(0xFF000000,0,false).width <= 0', grey)
        self.assertIn('holder = null;', grey)
        fit = as3_body(self.AS, 'fitIcon')
        self.assertIn('if(s.greyPic) { s.icon.addChild(s.greyPic); }', fit)
        self.assertIn('s.loader.visible = !(s.grey && s.greyPic);', fit)

    def test_heroes_row_uses_the_bitmap_and_shows_on_every_redraw(self):
        fit = as3_body(self.AS, 'fitIcon')
        self.assertIn('if(s.grey && !s.greyOn)', fit)
        self.assertIn('s.greyPic = greyCopy(s.loader.content);', fit)
        self.assertIn('s.greyPic.scaleX = s.greyPic.scaleY = k;', fit)
        self.assertIn('s.greyPic.visible = s.grey;', fit)
        # The redraw a filter change, a fold or a row move runs (render) sets the grey state and shows the picture
        # for every drawn row whether its picture was loaded again or not, and wherever the row now sits.
        load = self.RENDER[self.RENDER.index('if(iconUrl != "")'):]
        self.assertLess(load.index('s.grey = r.type == ROW_FILTER && int(r.k) == 6;'), load.index('fitIcon(s);'))
        self.assertLess(load.index('if(s.url != iconUrl)'), load.index('s.grey = r.type'))
        block = load[load.index('if(s.url != iconUrl)'):]
        block = block[:block.index('}') + 1]
        self.assertNotIn('fitIcon', block)
        filt = load[load.index('if(r.type == ROW_FILTER)'):]
        filt = filt[:filt.index('else')]
        self.assertIn('s.icon.y = y + (h - symbol) / 2;', filt)
        self.assertIn('s.icon.visible = true;', filt)
        # Filter changes, folds and device changes all redraw through that same render.
        self.assertIn('render();', as3_body(self.AS, 'rebuild'))
        self.assertIn('render();', as3_body(self.AS, 'fold'))
        self.assertIn('render();', as3_body(self.AS, 'setDevice'))

    def test_the_grey_copy_leaves_with_its_picture(self):
        fresh = as3_body(self.AS, 'newLoader')
        self.assertIn('.dispose();', fresh)
        self.assertIn('s.greyPic = null;', fresh)
        self.assertIn('s.greyOn = false;', fresh)
        self.assertLess(fresh.index('removeChildAt(0)'), fresh.index('s.greyPic = null;'))
        self.assertIn('import flash.display.BitmapData;', self.AS)
        self.assertIn('import flash.geom.Point;', self.AS)


class QuestListPromptClicks(unittest.TestCase):
    """Adapter 2.5.2: a mouse click on the Objectives prompt does what Right does, on the fold prompt what C does."""

    @classmethod
    def setUpClass(cls):
        cls.AS = AS_FILE.read_text()
        cls.CLICK = as3_body(cls.AS, 'onClick')
        cls.RENDER = as3_body(cls.AS, 'render')

    def test_render_records_the_prompt_box_of_the_row_it_drew(self):
        self.assertIn('promptRow = -1;', self.RENDER)
        self.assertIn('promptBox = null;', self.RENDER)
        self.assertIn('promptBox = promptBounds(s,objId);', self.RENDER)
        self.assertLess(self.RENDER.index('promptPicture(s,objId'), self.RENDER.index('promptBox = promptBounds(s,objId);'))
        bounds = as3_body(self.AS, 'promptBounds')
        self.assertIn('buttons["row_" + id]', bounds)
        self.assertIn('clip.getBounds(this)', bounds)
        self.assertIn('s.obj.getBounds(this)', bounds)

    def test_click_inside_the_prompt_toggles_and_never_tracks_or_swaps(self):
        click = self.CLICK
        hit = click[click.index('promptBox.contains(mouseX,mouseY)'):]
        hit = hit[:hit.index('return;')]
        self.assertIn('toggleObjectives();', hit)
        self.assertIn('fold(row);', hit)
        self.assertIn('swapAt = getTimer();', hit)  # the double click that follows does not track
        for call in ('pick(', 'activate(', 'nextObjective('):
            self.assertNotIn(call, hit)
        # The prompt test comes before the select-and-track path and the swap path.
        self.assertLess(click.index('promptBox.contains(mouseX,mouseY)'), click.index('nextObjective(rows[row].q)'))
        self.assertLess(click.index('promptBox.contains(mouseX,mouseY)'), click.index('pick(selected,true)'))

    def test_every_other_click_is_unchanged(self):
        click = self.CLICK
        self.assertIn('pick(selected,true); render();', click)
        self.assertIn('else { activate(selected); }', click)
        self.assertIn('swapAt = getTimer();', click)
        self.assertEqual(click.count('promptBox.contains('), 1)

    def test_rule_model(self):
        """The rule of onClick as a function: a click inside the box of the prompt on its row toggles or folds."""
        def click(row, prompt_row, prompt_id, box, x, y):
            if row < 0:
                return 'none'
            if row == prompt_row and box and box[0] <= x <= box[2] and box[1] <= y <= box[3]:
                return 'objectives' if prompt_id == 'objs' else 'fold'
            return 'track'
        box = (200, 40, 260, 60)
        self.assertEqual(click(2, 2, 'objs', box, 230, 50), 'objectives')
        self.assertEqual(click(2, 2, 'objs', box, 100, 50), 'track')  # the quest name
        self.assertEqual(click(3, 2, 'objs', box, 230, 50), 'track')  # another row
        self.assertEqual(click(0, 0, 'fold', box, 230, 50), 'fold')
        self.assertEqual(click(2, -1, '', None, 230, 50), 'track')


def code_of_as(source):
    return re.sub(r'//[^\n]*', '', source)


class BesideStretchTests(unittest.TestCase):
    def test_beside_sends_stretch_only_when_cmf_has_it(self):
        code = code_of(CMF_WS)
        send = body(code, 'function MqiAdapterSendBeside()')
        line = "CMFStyle(\"modMapQuestInsight\", 'tooltip', types[i], 'stretch', on, 1);"
        self.assertEqual(send.count(line), 1)
        guard = send.index("if (CMFHasAbility('tooltip', 'stretch'))")
        self.assertLess(guard, send.index(line))
        # "unset" withdraws it the way it withdraws clearAnchor and clearMinHeight: the same `on` value
        self.assertIn('on = "unset";', send)
        self.assertIn('on = "";', send)

    def test_version_2_5_4_in_the_three_places(self):
        self.assertIn('adapter 2.5.5', CMF_WS.read_text())
        self.assertIn('Version 2.5.5', (BASE / 'modCMFAdapterMapQuestInsight/README.txt').read_text(encoding='utf-8'))
        self.assertIn('Adapter version 2.5.5', (BASE / 'README.md').read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
