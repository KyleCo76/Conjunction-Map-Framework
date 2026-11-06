"""Customizer add-on (modCMFCustomizer 1.0.0): the script, the Options page and the strings.

Static checks. The add-on sends claims and marks them as the player's own settings (CMF API 19, the Player setting
level); the core part is a separate branch, so these tests read the add-on's text and model its rules. Nothing here
compiled or ran in game.
"""
import json
from pathlib import Path
import re
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_customizer_addon as tool
ADDON = ROOT/'source/addons/customizer'
SCRIPT_FILE = ADDON/'modCMFCustomizer/content/scripts/local/modcmfcustomizer.ws'
MENU_FILE = ADDON/'modCMFCustomizer.xml'
STRINGS_FILE = ADDON/'strings.json'
CORE = (ROOT/'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='utf-8')
GROUPS = ['General', 'Quests', 'Exploration', 'NPCs', 'Buffs']
SIZES = [50, 75, 90, 110, 125, 150, 175, 200, 250, 300]
GROWTH = [110, 125, 150, 175, 200]
QUEST_TYPES = ['StoryQuest', 'ChapterQuest', 'SideQuest', 'MonsterQuest', 'TreasureQuest', 'QuestReturn', 'QuestBelgard',
               'QuestCoronata', 'QuestVermentino', 'QuestAvailable', 'QuestAvailableHoS', 'QuestAvailableBaW',
               'QuestAvailableLy', 'QuestObjective', 'QuestObjectiveOther']
UNKNOWN_TYPES = ['NotDiscoveredPOI', 'NotDiscoveredPOI_1', 'NotDiscoveredPOI_2', 'NotDiscoveredPOI_3']
SCRIPT_VARS = (['CMFCZ_Size', 'CMFCZ_Quest', 'CMFCZ_Unknown', 'CMFCZ_Selected', 'CMFCZ_Labels'] +
               ['CMFCZ_Far_' + g for g in GROUPS] + ['CMFCZ_Standard'])
# The page shows Standardize under the pin size row.
VARS = (['CMFCZ_Size', 'CMFCZ_Standard', 'CMFCZ_Quest', 'CMFCZ_Unknown', 'CMFCZ_Selected', 'CMFCZ_Labels'] +
        ['CMFCZ_Far_' + g for g in GROUPS])


def script():
    return SCRIPT_FILE.read_text(encoding='utf-8')


def function_body(text, header):
    start = text.index(header)
    open_at = text.index('{', start)
    depth = 0
    for i in range(open_at, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return text[open_at:i + 1]
    raise AssertionError(header)


def cases(body):
    """{case int: returned text} of a switch that returns literals."""
    return {int(n): v.strip().strip('"') for n, v in re.findall(r'case (\d+):\s*return ([^;]+);', body)}


class ScriptTests(unittest.TestCase):
    def setUp(self):
        self.text = script()

    def test_value_tables(self):
        text = self.text
        sizes = cases(function_body(text, 'function CMFCZSizePercent('))
        self.assertEqual([int(sizes[i]) for i in range(1, 11)], SIZES)
        self.assertNotIn(0, sizes)
        growth = cases(function_body(text, 'function CMFCZGrowthPercent('))
        self.assertEqual([int(growth[i]) for i in range(1, 6)], GROWTH)
        value = function_body(text, 'function CMFCZValue(')
        self.assertIn('CMFCZSizePercent(index)', value)
        self.assertIn('CMFCZGrowthPercent(index)', value)
        # out of range gives 0
        self.assertIn('return 0;', value)

    def literals(self, name):
        body = function_body(self.text, 'function %s(' % name)
        return re.findall(r"list\.PushBack\('([A-Za-z0-9_]+)'\);", body)

    def test_group_and_type_lists(self):
        text = self.text
        data = json.loads((ROOT/'tools/cmf_pin_types.json').read_text(encoding='utf-8'))
        dispatcher = function_body(text, 'function CMFCZAddGroup(')
        for number, group in enumerate(GROUPS):
            want = [t['name'] for t in data['types'] if t['category'] == group]
            block = dispatcher[dispatcher.index('if (group == %d)' % number):]
            block = block[:block.index('}')]
            have = []
            for fn in re.findall(r'(CMFCZAdd[A-Za-z]+\d+)\(list\);', block):
                have += self.literals(fn)
            self.assertEqual(have, want, group)
            for name in have:
                self.assertFalse(name == 'Player' or re.fullmatch(r'User[1-7]', name), name)
        self.assertEqual(self.literals('CMFCZAddQuest'), QUEST_TYPES)
        self.assertEqual(self.literals('CMFCZAddUnknown'), UNKNOWN_TYPES)

    def test_script_lists_are_written_by_the_tool(self):
        self.assertEqual(self.text, tool.script_text())

    BAD_NAMES = ('ArrayClear', 'StringToName', 'ArrayPush', 'ArrayContains', 'ArrayErase', 'ArraySize', 'ArrayFind',
                 'StrToInt', 'IntToStr', 'StrToFloat', 'StrSplit', 'StrContains', 'ToString', 'NameToStr', 'Length')

    def test_no_calls_that_do_not_exist(self):
        # None of these is a WitcherScript function (the compile fails with "Could not find function"); arrays use methods
        # (Clear, PushBack, Size, FindFirst) and strings the Str* functions the CMF core itself calls.
        for path in (SCRIPT_FILE.parent).glob('*.ws'):
            code = '\n'.join(l for l in path.read_text(encoding='utf-8').splitlines() if not l.lstrip().startswith('//'))
            for name in self.BAD_NAMES:
                self.assertNotRegex(code, r'(?<![\w.])%s\(' % name, name)

    def test_global_functions_are_ones_the_core_uses(self):
        # Every global function the add-on calls, other than its own and CMF's public API, must be one the CMF core calls.
        code = '\n'.join(l for l in script().splitlines() if not l.lstrip().startswith('//'))
        own = set(re.findall(r'function ([A-Za-z0-9_]+)\(', code))
        called = set(re.findall(r'(?<![.\w])([A-Za-z_][A-Za-z0-9_]*)\(', code)) - own
        called -= {'if', 'for', 'while', 'switch', 'addMethod', 'addField', 'wrapMethod', 'wrappedMethod'}
        for name in sorted(called):
            if name.startswith('CMF'):
                continue
            self.assertRegex(CORE, r'(?<![.\w])%s\(' % name, name)

    def test_no_string_to_name(self):
        # WitcherScript has no StringToName: the compile fails with "Could not find function" (the 1.3.0 preview).
        for path in (SCRIPT_FILE.parent).glob('*.ws'):
            self.assertNotIn('StringToName', path.read_text(encoding='utf-8'), path.name)

    def test_state_survives_save_loads(self):
        body = function_body(self.text, 'function OnGameStarted(')
        self.assertIn('if (cmfczSent.Size() != 11)', body)
        reset = body[body.index('if (cmfczSent.Size() != 11)'):]
        self.assertLess(reset.index('CMFCZReset()'), reset.index('}'))

    def test_var_names_and_rows(self):
        names = cases_names(function_body(self.text, 'function CMFCZVarName('))
        self.assertEqual([names[i] for i in range(11)], SCRIPT_VARS)

    def test_off_sends_nothing(self):
        body = function_body(self.text, 'function CMFCZApply()')
        # a row at Off (index 0) is never sent; only a change from a sent value drops it
        self.assertIn('if (index > 0)', body)
        self.assertRegex(body, r'if \(cmfczSent\[i\] > 0\)\s*\{\s*CMFCZDropRow\(i\);')
        send = function_body(self.text, 'function CMFCZSendRow(')
        self.assertIn('if (value <= 0)', send)

    def test_unchanged_settings_send_nothing(self):
        body = function_body(self.text, 'function CMFCZApply()')
        self.assertIn('if (index != cmfczSent[i])', body)
        self.assertIn('if (marks != cmfczMarks)', body)

    def test_off_after_a_send_withdraws_each_target(self):
        drop = function_body(self.text, 'function CMFCZDropRow(')
        self.assertRegex(drop, r'CMFRegister\(CMFCZProvider\(\), 40, ')
        self.assertIn('CMFCZProps(row)', drop)
        self.assertIn('CMFCZTargets(row, targets)', drop)
        props = cases(function_body(self.text, 'function CMFCZProps('))
        self.assertEqual(props[0], '51')
        self.assertEqual(props[3], '52')
        self.assertEqual(props[4], '28,13')
        self.assertEqual(props[10], '53')
        self.assertEqual(function_body(self.text, 'function CMFCZProps(').count('"36,9"'), 1)

    def test_marks_follow_set_rows(self):
        marks = function_body(self.text, 'function CMFCZMarks()')
        for needle in ('"28"', '"36"', '"53"'):
            self.assertIn(needle, marks)
        # 51 and 52 add together, like hides (9) and Never labels (13): none of them is marked
        self.assertNotRegex(marks, r'"(9|10|13|32|51|52)"')
        # Never (labels index 2) adds the 13 claim: no mark for it
        self.assertIn('cmfczSent[4] == 1 || cmfczSent[4] == 3', marks)
        self.assertIn('cmfczSent[10] > 0', marks)
        # Always hide (3) is the hide claim, not a zoom range: only 1 and 2 mark 36
        self.assertIn('cmfczSent[i] == 1 || cmfczSent[i] == 2', marks)
        self.assertLess(marks.index('"28"'), marks.index('"36"'))
        self.assertLess(marks.index('"36"'), marks.index('"53"'))
        # size, growth and hide rows never reach the mark list
        for i in (0, 1, 2, 3):
            self.assertNotIn('cmfczSent[%d]' % i, marks)

    def test_size_rows_send_factors(self):
        one = function_body(self.text, 'function CMFCZSendOne(')
        self.assertIn("CMFRegister(CMFCZProvider(), 51, pin, '', \"\", value)", one)
        self.assertIn("CMFRegister(CMFCZProvider(), 52, pin, '', \"\", value)", one)
        self.assertIn("CMFRegister(CMFCZProvider(), 53, pin, '', \"\", 1)", one)
        self.assertNotRegex(self.text, r"CMFRegister\(CMFCZProvider\(\), (10|32), ")

    def test_most_specific_row_per_type(self):
        targets = function_body(self.text, 'function CMFCZTargets(')
        # row 1 is the overall claim, rows 2 and 3 are type claims of their own: a quest type has the quest row's claim,
        # and with that row Off only the overall claim covers it
        self.assertRegex(targets, r"row == 0 \|\| row == 3 \|\| row == 4 \|\| row == 10\)\s*\{\s*list\.PushBack\(''\);")
        self.assertRegex(targets, r'row == 1\)\s*\{\s*CMFCZAddQuest\(list\);')
        self.assertRegex(targets, r'row == 2\)\s*\{\s*CMFCZAddUnknown\(list\);')
        apply = function_body(self.text, 'function CMFCZApply()')
        self.assertIn('CMFCZDropRow(i)', apply)

    def test_standard_row(self):
        value = function_body(self.text, 'function CMFCZValue(')
        self.assertIn('row == 10 && index == 1', value)
        targets = function_body(self.text, 'function CMFCZTargets(')
        self.assertIn('row == 10', targets)

    def test_labels_row_values(self):
        one = function_body(self.text, 'function CMFCZSendOne(')
        self.assertIn('CMFRegister(CMFCZProvider(), 13, pin, \'\', "pin", 1)', one)
        self.assertRegex(one, r'CMFRegister\(CMFCZProvider\(\), 28, pin, \'\', "", (0|label)\)')
        send = function_body(self.text, 'function CMFCZSendOne(')
        self.assertIn('value == 3', send)
        # switching drops the old claim: the whole row's properties go (28 and 13)
        apply = function_body(self.text, 'function CMFCZApply()')
        self.assertLess(apply.index('CMFCZDropRow(i)'), apply.index('CMFCZSendRow(i, index)'))

    def test_factor_range(self):
        for percent in SIZES + GROWTH:  # factors, percent of the pack's size
            self.assertTrue(25 <= percent <= 400)

    def test_register_before_wrapped_method_in_config_ui(self):
        body = function_body(self.text, 'function OnConfigUI()')
        self.assertLess(body.index('theGame.CMFCZApply()'), body.index('wrappedMethod()'))
        self.assertIn('@wrapMethod(CR4MapMenu)', self.text)

    def test_old_cmf_sends_nothing(self):
        ready = function_body(self.text, 'function CMFCZReady()')
        self.assertIn("CMFHasAbility('claims', 'playerSetting')", ready)
        self.assertIn("CMFHasAbility('claims', 'scaleFactor')", ready)
        self.assertIn('customizer needs CMF API 19', ready)
        apply = function_body(self.text, 'function CMFCZApply()')
        self.assertLess(apply.index('CMFCZReady()'), apply.index('CMFCZSendRow'))
        self.assertIn('CMFCZReady()', apply[:apply.index('GetVarValue')])

    def test_declares_provider_and_name_once(self):
        body = function_body(self.text, 'function OnGameStarted(')
        self.assertEqual(body.count('CMFDeclareProvider'), 1)
        self.assertEqual(body.count('CMFSetProviderName'), 1)
        self.assertIn('"CMF Customizer"', body)
        self.assertIn('wrappedMethod(restored)', body)

    def test_compile_traps(self):
        text = self.text
        text.encode('ascii')
        self.assertNotIn('\r', text)
        self.assertNotRegex(text, r'(?m)^ +\S', 'tabs only')
        # no bare return in an event / wrapped event
        for header in ('function OnConfigUI()', 'function OnGameStarted('):
            body = function_body(text, header)
            self.assertNotRegex(body, r'\breturn\s*;')
        # var declarations come first in every function body
        for m in re.finditer(r'\nfunction [^\n]*\n\{', text):
            body = function_body(text, text[m.start() + 1:m.end()])
            seen_statement = False
            for line in body.splitlines()[1:]:
                line = line.strip()
                if not line or line.startswith('//') or line in ('{', '}'):
                    continue
                if line.startswith('var '):
                    self.assertFalse(seen_statement, line)
                else:
                    seen_statement = True
        # no assignment through a function result, no string escapes
        self.assertNotRegex(text, r'\)\s*\.[A-Za-z]+\s*=[^=]')
        self.assertNotIn('\\"', text)
        # function bodies stay short (the compiler damages very long text in one function)
        for m in re.finditer(r'\nfunction [^\n]*\n\{', text):
            self.assertLess(len(function_body(text, text[m.start() + 1:m.end()])), 2600)
        code = '\n'.join(l for l in text.splitlines() if not l.lstrip().startswith('//'))
        self.assertNotRegex(code, r'\b(state|abstract|enum|class|struct|extends)\b')

    def test_uses_only_existing_cmf_calls(self):
        calls = set(re.findall(r'\b(CMF[A-Za-z]+)\(', script()))
        own = set(re.findall(r'function (CMF[A-Za-z_0-9]+)\(', script()))
        for name in calls - own:
            if name.startswith('CMFCZ'):
                self.fail(name)
            if name == 'CMFHasAbility':
                self.assertIn("if (part == 'claims')", CORE)
                continue
            self.assertIn('function %s(' % name, CORE, name)

    def test_against_the_real_core(self):
        """With the Player setting core merged: the abilities exist, the marks are accepted and the factors are not."""
        if 'function PlayerSettingRefusal(' not in CORE:
            self.skipTest('the Player setting core (claude/player-setting) is not in this tree')
        for ability in ('playerSetting', 'scaleFactor', 'scaleStandard'):
            self.assertIn(ability, CORE)
        refusal = CORE[CORE.index('function PlayerSettingRefusal('):]
        refusal = refusal[:refusal.index('return "";')]
        for added in ('id == 51', 'id == 52'):
            self.assertIn(added, refusal)
        self.assertRegex(CORE, r'function CMFPropertyPlayerSetting\(\) : int \{ return 50; \}')
        self.assertRegex(CORE, r'function CMFPropertyPinScaleFactor\(\) : int \{ return 51; \}')
        self.assertRegex(CORE, r'function CMFPropertyPinScaleStandard\(\) : int \{ return 53; \}')
        # the marked ids (28, 36, 53) are not in the "added" list
        for marked in ('id == 28', 'id == 36', 'id == 53)'):
            self.assertNotIn(marked, refusal)

    def test_never_writes_cmf_settings(self):
        text = self.text
        self.assertNotIn('SetVarValue', text)
        self.assertNotIn('CMFPick_', text)


def cases_names(body):
    return {int(n): v for n, v in re.findall(r"case (\d+):\s*return '([A-Za-z_]+)';", body)}


class MenuTests(unittest.TestCase):
    def setUp(self):
        self.tree = ET.parse(MENU_FILE)
        self.text = script()

    def test_xml_parses(self):
        group = self.tree.getroot().findall('Group')
        self.assertEqual([g.get('id') for g in group], ['CMFCustomizer'])

    def test_menu_vars_match_script(self):
        group = self.tree.getroot().find('Group')
        variables = group.find('VisibleVars').findall('Var')
        options = [v for v in variables if v.get('displayType') == 'OPTIONS']
        self.assertEqual([v.get('id') for v in options], VARS)
        counts = {}
        for name in ('Size', 'Quest', 'Unknown'):
            counts['CMFCZ_' + name] = 1 + len(SIZES)
        counts['CMFCZ_Standard'] = 2
        counts['CMFCZ_Selected'] = 1 + len(GROWTH)
        counts['CMFCZ_Labels'] = 1 + 3
        for g in GROUPS:
            counts['CMFCZ_Far_' + g] = 4
        for v in options:
            opts = v.find('OptionsArray').findall('Option')
            self.assertEqual(len(opts), counts[v.get('id')], v.get('id'))
            self.assertEqual(v.get('value'), '0')
            for i, o in enumerate(opts):
                self.assertEqual(o.get('id'), str(i))
                self.assertEqual(o.find('Entry').get('value'), str(i))
                self.assertEqual(o.find('Entry').get('varId'), v.get('id'))
            want_off = 'cmf_customizer_default' if v.get('id').startswith('CMFCZ_Far_') else 'cmf_customizer_off'
            self.assertEqual(opts[0].get('displayName'), want_off)

    def test_every_display_name_has_a_string(self):
        keys = {s['key'] for s in json.loads(STRINGS_FILE.read_text(encoding='utf-8'))['strings']}
        for el in self.tree.getroot().iter():
            value = el.get('displayName')
            if value and el.tag != 'Group':
                self.assertIn(value, keys, value)
        group = self.tree.getroot().find('Group').get('displayName')
        self.assertEqual(group, 'Mods.cmf_customizer')
        self.assertIn('panel_cmf_customizer', keys)

    def test_string_ids_in_own_block(self):
        data = json.loads(STRINGS_FILE.read_text(encoding='utf-8'))
        self.assertEqual(data['idBase'], 2000250000)
        ids = [s['id'] for s in data['strings']]
        self.assertEqual(ids, list(range(2000250001, 2000250001 + len(ids))))
        self.assertLess(max(ids), 2000260000)
        for s in data['strings']:
            self.assertTrue(s['key'].startswith('cmf_customizer_') or s['key'] == 'panel_cmf_customizer', s['key'])
            self.assertTrue(s['text']['en'])
        keys = [s['key'] for s in data['strings']]
        self.assertEqual(len(keys), len(set(keys)))

    def test_help_does_not_ask_for_a_cmf_pick(self):
        data = json.loads(STRINGS_FILE.read_text(encoding='utf-8'))
        help_text = [s for s in data['strings'] if s['key'] == 'cmf_customizer_help'][0]['text']['en']
        self.assertNotRegex(help_text.lower(), r'pick (this|the) (add-on|mod)|set .* in cmf')
        self.assertNotIn('Pin size row', help_text)

    def test_rows_and_separators_carry_the_display_name_tags(self):
        # As Map Quest Insight's page: the game looks the plain keys up only with these tags (PC, 2026-11-06).
        group = self.tree.getroot().find('Group')
        for v in group.find('VisibleVars').findall('Var'):
            tags = v.get('tags', '').split(';')
            self.assertIn('customDisplayName', tags, v.get('id'))
            if v.get('displayType') == 'OPTIONS':
                self.assertIn('customNames', tags, v.get('id'))

    def test_zoom_rows(self):
        group = self.tree.getroot().find('Group')
        for g in GROUPS:
            far = [v for v in group.find('VisibleVars').findall('Var') if v.get('id') == 'CMFCZ_Far_' + g][0]
            names = [o.get('displayName') for o in far.find('OptionsArray').findall('Option')]
            self.assertEqual(names, ['cmf_customizer_default', 'cmf_customizer_zoom_far', 'cmf_customizer_zoom_out',
                                     'cmf_customizer_zoom_hide'])
        zoom = function_body(script(), 'function CMFCZZoomRange(')
        self.assertEqual(re.findall(r'return "([^"]*)";', zoom), ['2.75,1000', '4.7,1000'])
        # Always hide hides the group at every zoom with the hide claim (9); a range cannot (the core refuses min above max)
        one = function_body(script(), 'function CMFCZSendOne(')
        self.assertRegex(one, r"else if \(value == 3\)\s*\{\s*CMFRegister\(CMFCZProvider\(\), 9, pin, '', \"\", 1\);")

    def test_help_row_first_and_headers(self):
        group = self.tree.getroot().find('Group')
        variables = group.find('VisibleVars').findall('Var')
        self.assertEqual(variables[0].get('displayType'), 'SEPARATOR')
        self.assertEqual(variables[0].get('displayName'), 'cmf_customizer_help')  # the XML keeps the bare names
        seps = [v.get('displayName') for v in variables if v.get('displayType') == 'SEPARATOR']
        self.assertEqual(seps, ['cmf_customizer_help', 'cmf_customizer_far_header'])
        texts = {s['key']: s['text']['en'] for s in json.loads(STRINGS_FILE.read_text(encoding='utf-8'))['strings']}
        for key in seps:
            # a long heading is truncated and the description panel draws over it (first launch, 2026-11-06)
            self.assertLessEqual(len(texts[key]), 45, key)


if __name__ == '__main__':
    unittest.main()
