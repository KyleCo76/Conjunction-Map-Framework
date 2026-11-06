"""API 19: pin size multipliers (51, 52) and Standardize icon sizes (53).

Runs the real core functions (ScaleProduct, StandardOfList, FinishStandard ...) through the contract runner, and
checks the panel's cmfScaleOf by turning its ActionScript text into Python.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import re
import unittest

from ws_contract_runner import Array, bind, run
from ws_text import ROOT, core_text, ws_function
from test_cmf_movie_hide_panels import simulate_chain

CORE = core_text()
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
DESCRIBED = 'red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'
DATA = 'red/game/witcher3/data/StaticMapPinData.as'


class Claim:
    def __init__(self, provider, prop, number, level=0, pin_type='', tag=''):
        self.provider, self.propertyId, self.number = provider, prop, number
        self.level, self.pinType, self.pinTag = level, pin_type, tag


class Pin:
    """A pin's flash data object: named fields, with the fields CMF reads defaulting like the panel's class."""
    def __init__(self, scale=0.0, player=False, user=False):
        self.f = {'cmfIconScale': scale, 'isPlayer': player, 'isUserPin': user}

    def GetMemberFlashBool(self, name): return bool(self.f.get(name, False))
    def GetMemberFlashNumber(self, name): return float(self.f.get(name, 0.0))
    def SetMemberFlashNumber(self, name, value): self.f[name] = value


def covers(claim, pin_type, tag, level):
    if claim.level == 0:
        return True
    if claim.level == 1:
        return claim.pinType == pin_type
    return claim.level == 2 and claim.pinTag == tag


def env_for(claims, answer='', active=True, find_wins=True):
    logs = []
    env = dict(scaleClaims=Array(claims), variantNow='', NameToString=str, CMFLevelPlace=lambda: 3,
               CMFKindHidden=lambda t: False, Covers=covers, choicesActive=active,
               decideAnswer=Array([''] * 80), standardScale=0, catching=False, CMFLog=lambda *a: logs.append(a))
    env['decideAnswer'][27] = answer
    env['PropertyWon'] = lambda p: p == 53
    env['logs'] = logs
    env['Find'] = lambda *a: (find_wins, None)
    env['Find'].out_indices = (4,)
    env['Specific'] = bind(CORE, 'Specific', env, ('claim',))
    env['ScaleCovers'] = bind(CORE, 'ScaleCovers', env, ('claim', 'pinType', 'filtered', 'pinTag', 'maxLevel'))
    env['ScaleProduct'] = bind(CORE, 'ScaleProduct', env, ('propertyId', 'pinType', 'filtered', 'pinTag', 'maxLevel'))
    env['SizeIsVanilla'] = bind(CORE, 'SizeIsVanilla', env, ())
    env['ScalePercent'] = lambda scale: int(scale * 100.0 + 0.5)  # the cast the runner leaves out
    env['StandardCloser'] = bind(CORE, 'StandardCloser', env, ('a', 'b'))
    env['StandardOfList'] = bind(CORE, 'StandardOfList', env, ('flashArray',))
    env['WriteScaleFactors'] = bind(CORE, 'WriteScaleFactors', env, ('dataObject', 'pinType', 'filtered', 'pinTag', 'maxLevel'))
    env['FinishStandard'] = bind(CORE, 'FinishStandard', env, ('flashArray',), capture=('standardScale',))
    return env


class FlashList(list):
    def GetLength(self): return len(self)
    def GetElementFlashObject(self, i): return self[i]


def factor(env, prop, pin_type='Boat', tag=''):
    return env['ScaleProduct'](prop, pin_type, pin_type, tag, 3)


class Properties(unittest.TestCase):
    def test_properties_51_52_53_ranges_and_targets(self):
        self.assertIn('function CMFPropertyPinScaleFactor() : int { return 51; }', CORE)
        self.assertIn('function CMFPropertySelectedScaleFactor() : int { return 52; }', CORE)
        self.assertIn('function CMFPropertyPinScaleStandard() : int { return 53; }', CORE)
        self.assertIn('(propertyId >= 39 && propertyId <= 53)', ws_function(CORE, 'function CMFHasProperty('))
        self.assertIn('(propertyId >= 51 && propertyId <= 53)', ws_function(CORE, 'public function EveryPinProperty('))
        one = ws_function(CORE, 'function CMFOnePinProperty(')
        self.assertIn('propertyId == 51 || propertyId == 52', one)
        self.assertNotIn('53', one)
        upsert = ws_function(CORE, 'public function Upsert(')
        self.assertIn('incoming.propertyId == 51 || incoming.propertyId == 52', upsert)
        self.assertIn('(incoming.number < 25 || incoming.number > 400)', upsert)
        self.assertIn('incoming.propertyId == 53 && (incoming.number < 0 || incoming.number > 1)', upsert)
        for pid in (51, 52, 53):
            self.assertIn('case %d:' % pid, ws_function(CORE, 'public function PropertyChoice('))
        self.assertIn('scaleFactor,scaleStandard', CORE)

    def test_53_markable_and_51_52_refused_as_marks(self):
        body = ws_function(CORE, 'private function PlayerSettingRefusal(')
        self.assertIn('id == 51 || id == 52', body)
        self.assertIn('return "added";', body)
        self.assertIn('(id > 48 && id != 53)', body)

    def test_withdrawn_standard_leaves_the_slot(self):
        prepare = ws_function(CORE, 'public function Prepare(')
        self.assertIn('claims[i].propertyId == 53) &&', prepare)
        self.assertIn('scaleClaims.PushBack(claims[i]);', prepare)
        self.assertIn('scaleClaims.Clear();', prepare)


class Factors(unittest.TestCase):
    def test_factors_multiply_across_providers(self):
        env = env_for([Claim('A', 51, 150), Claim('B', 51, 200)])
        self.assertAlmostEqual(factor(env, 51), 3.0)

    def test_factor_most_specific_within_one_provider(self):
        env = env_for([Claim('A', 51, 150), Claim('A', 51, 200, 1, 'Boat'), Claim('A', 51, 50, 2, tag='t')])
        self.assertAlmostEqual(factor(env, 51, 'Boat'), 2.0)
        self.assertAlmostEqual(factor(env, 51, 'Herb'), 1.5)
        self.assertAlmostEqual(factor(env, 51, 'Boat', 't'), 0.5)

    def test_selected_factor_is_kept_apart(self):
        env = env_for([Claim('A', 51, 150), Claim('A', 52, 200)])
        self.assertAlmostEqual(factor(env, 51), 1.5)
        self.assertAlmostEqual(factor(env, 52), 2.0)

    def test_no_covering_claim_gives_zero(self):
        env = env_for([Claim('A', 51, 150, 1, 'Herb')])
        self.assertEqual(factor(env, 51, 'Boat'), 0.0)
        self.assertEqual(factor(env, 52, 'Boat'), 0.0)

    def test_factor_applies_to_pins_without_size_claims(self):
        env = env_for([Claim('A', 51, 150)])
        pin = Pin(scale=0.0)
        env['WriteScaleFactors'](pin, 'Boat', 'Boat', '', 3)
        self.assertAlmostEqual(pin.f['cmfScaleFactor'], 1.5)
        self.assertNotIn('cmfSelectedFactor', pin.f)
        self.assertEqual(pin.f['cmfIconScale'], 0.0)

    def test_vanilla_size_pick_drops_factors_and_standard(self):
        env = env_for([Claim('A', 51, 150)], answer='vanilla')
        pin = Pin()
        env['WriteScaleFactors'](pin, 'Boat', 'Boat', '', 3)
        self.assertNotIn('cmfScaleFactor', pin.f)
        pins = FlashList([Pin(1.2), Pin(1.2)])
        env['FinishStandard'](pins)
        self.assertEqual(env['standardScale'], 0)
        self.assertNotIn('cmfStandardScale', pins[0].f)

    def test_a_pick_naming_a_mod_keeps_the_factors(self):
        env = env_for([Claim('A', 51, 150)], answer='SomeMod')
        pin = Pin()
        env['WriteScaleFactors'](pin, 'Boat', 'Boat', '', 3)
        self.assertAlmostEqual(pin.f['cmfScaleFactor'], 1.5)

    def test_factors_skip_player_and_user(self):
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        block = fill[fill.index('if (!isPlayer && !isUser && !dataObject.GetMemberFlashBool("cmfDone"))'):]
        self.assertLess(block.index('WriteScaleFactors('), block.index('// Version 11: the player marker'))

    def test_no_factor_claim_writes_nothing_new_per_pin(self):
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        self.assertRegex(fill, r'if \(scaleClaims\.Size\(\) > 0\)\s*\{\s*WriteScaleFactors\(')
        self.assertRegex(fill, r'if \(!fullList && standardScale > 0\)')
        self.assertEqual(fill.count('"cmfStandardScale"'), 1)


class StandardWinner(unittest.TestCase):
    def test_a_pick_that_leaves_standardize_out_turns_it_off(self):
        env = env_for([], find_wins=False)
        pins = FlashList([Pin(1.5)])
        env['FinishStandard'](pins)
        self.assertEqual(env['standardScale'], 0)
        self.assertNotIn('cmfStandardScale', pins[0].f)

    def test_one_log_line_per_full_build(self):
        env = env_for([])
        env['FinishStandard'](FlashList([Pin(1.5), Pin(1.5)]))
        self.assertEqual(len(env['logs']), 1)
        self.assertIn('scale standard percent=', str(env['logs'][0]))
        env['catching'] = True
        env['FinishStandard'](FlashList([Pin(1.0)]))
        self.assertEqual(len(env['logs']), 1)

    def test_standardize_refused_at_any_level_but_every_pin(self):
        for name in ('private function ClaimTargetOk(', 'private function ClaimRejectReason('):
            self.assertIn('claim.propertyId == 53 && claim.level != 0', ws_function(CORE, name))


class Standard(unittest.TestCase):
    def test_percent_helper_rounds_a_fraction(self):
        self.assertIn('return (int)(scale * 100.0 + 0.5);', ws_function(CORE, 'private function ScalePercent('))

    def standard(self, scales, extra=()):
        env = env_for([])
        pins = FlashList([Pin(s) for s in scales] + list(extra))
        return env['StandardOfList'](pins)

    def test_standard_is_mode_with_ties_near_100(self):
        self.assertEqual(self.standard([1.5, 1.5, 1.0, 1.0, 1.0]), 100)
        self.assertEqual(self.standard([1.5, 1.5, 1.5, 1.0, 1.0]), 150)
        self.assertEqual(self.standard([1.5, 1.5, 0.75, 0.75]), 75)
        self.assertEqual(self.standard([1.25, 1.25, 0.75, 0.75]), 75)  # equally near 100: the smaller
        self.assertEqual(self.standard([2.0, 2.0, 0.5, 0.5]), 50)

    def test_standard_without_size_claims_is_100(self):
        self.assertEqual(self.standard([0.0, 0.0, 0.0]), 100)
        self.assertEqual(self.standard([]), 100)

    def test_standard_skips_hidden_and_player_pins(self):
        extra = [Pin(3.0, player=True), Pin(3.0, user=True), Pin(3.0, user=True)]
        self.assertEqual(self.standard([1.0, 1.0], extra), 100)
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        self.assertLess(fill.index('RemoveHiddenPins('), fill.index('FinishStandard('))

    def test_standard_sent_once_per_full_build(self):
        env = env_for([])
        pins = FlashList([Pin(1.5), Pin(1.5), Pin(1.0), Pin(0.0, player=True)])
        env['FinishStandard'](pins)
        self.assertEqual(env['standardScale'], 150)
        self.assertAlmostEqual(pins[0].f['cmfStandardScale'], 1.5)
        self.assertAlmostEqual(pins[2].f['cmfStandardScale'], 1.5)
        self.assertNotIn('cmfStandardScale', pins[3].f)
        # A pass for pins pushed late keeps the build's value and tallies nothing.
        env['catching'] = True
        late = FlashList([Pin(1.0), Pin(1.0), Pin(1.0)])
        env['FinishStandard'](late)
        self.assertEqual(env['standardScale'], 150)
        self.assertAlmostEqual(late[0].f['cmfStandardScale'], 1.5)
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        self.assertEqual(fill.count('FinishStandard('), 1)
        self.assertIn('FinishStandard(flashArray);', fill[fill.index('if (fullList)\n\t\t{\n\t\t\tRemoveHiddenPins'):])

    def test_standard_off_without_a_winner(self):
        env = env_for([])
        env['PropertyWon'] = lambda p: False
        pins = FlashList([Pin(1.5)])
        env['FinishStandard'](pins)
        self.assertEqual(env['standardScale'], 0)
        self.assertNotIn('cmfStandardScale', pins[0].f)


def to_python(function_text):
    """The small subset of ActionScript cmfScaleOf uses, as a Python function of (p, avatar, selected, extra)."""
    lines = []
    depth = 1
    pending_if = False
    for raw in function_text.split('\n')[2:-1]:
        t = raw.strip()
        if not t or t == '{':
            if t == '{' and pending_if:
                pending_if = False
            continue
        if t == '}':
            depth -= 1
            continue
        t = t.replace('param1.', 'p.').replace('this.cmfExtraPinLook(param1)', 'extra').replace('this.', '')
        t = t.replace('&&', ' and ').replace('||', ' or ')
        t = re.sub(r'!(?!=)', 'not ', t).replace('Math.max', 'max').replace('Math.min', 'min')
        m = re.match(r'if\((.*)\)$', t)
        if m:
            lines.append('    ' * depth + 'if ' + m.group(1) + ':')
            depth += 1
            continue
        m = re.match(r'var (\w+):\w+ = (.*);$', t)
        t = (m.group(1) + ' = ' + m.group(2)) if m else t.rstrip(';')
        m = re.match(r'(\w+ = |return )(.*) \? (.*) : (.*)$', t)
        if m:
            t = m.group(1) + '(' + m.group(3) + ') if (' + m.group(2) + ') else (' + m.group(4) + ')'
        lines.append('    ' * depth + t)
    src = 'def f(p, isAvatar, selected, extra):\n' + '\n'.join(lines) + '\n'
    ns = {}
    exec(src, ns)
    return ns['f']


class P:
    def __init__(self, **kw):
        self.cmfIconScale, self.cmfSelectedScale, self.cmfSelectedScaleEnabled = 1.0, 1.0, False
        self.cmfScaleFactor, self.cmfSelectedFactor, self.cmfStandardScale = 1.0, 1.0, 0.0
        self.__dict__.update(kw)


class PanelMath(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        text = next(e['replace'] for e in EDITS[DESCRIBED] if e['replace'].lstrip().startswith('private function cmfScaleOf') and 'cmfStandardScale' in e['replace'])
        cls.fn = staticmethod(to_python(text))

    def scale(self, avatar=False, selected=False, **kw):
        return self.fn(P(**kw), avatar, selected, True)

    def test_scale_of_math(self):
        self.assertEqual(self.scale(), 1.0)
        self.assertEqual(self.scale(cmfIconScale=1.5), 1.5)
        self.assertEqual(self.scale(cmfIconScale=0), 1)
        # A selected pin without a selected scale keeps its base; with one, the selected scale.
        self.assertEqual(self.scale(selected=True, cmfIconScale=1.5), 1.5)
        self.assertEqual(self.scale(selected=True, cmfIconScale=1.5, cmfSelectedScale=2.0, cmfSelectedScaleEnabled=True), 2.0)
        self.assertEqual(self.scale(cmfIconScale=1.5, cmfSelectedScale=2.0, cmfSelectedScaleEnabled=True), 1.5)
        # Standardize replaces the base; the pack's own growth ratio is kept for the selected pin.
        self.assertEqual(self.scale(cmfIconScale=1.5, cmfStandardScale=1.0), 1.0)
        self.assertAlmostEqual(self.scale(selected=True, cmfIconScale=1.5, cmfSelectedScale=3.0,
                                          cmfSelectedScaleEnabled=True, cmfStandardScale=1.0), 2.0)
        # The factors multiply; the selected factor only while selected; the clamp is 0.25 to 4.
        self.assertAlmostEqual(self.scale(cmfIconScale=1.5, cmfScaleFactor=2.0, cmfSelectedFactor=2.0), 3.0)
        self.assertAlmostEqual(self.scale(selected=True, cmfScaleFactor=1.5, cmfSelectedFactor=2.0), 3.0)
        self.assertEqual(self.scale(cmfScaleFactor=4.0, cmfIconScale=2.0), 4.0)
        self.assertEqual(self.scale(cmfScaleFactor=0.25, cmfIconScale=0.5), 0.25)
        self.assertEqual(self.scale(cmfStandardScale=1.0, cmfScaleFactor=3.0, cmfIconScale=2.0), 3.0)
        # The player's arrow never takes the standard or a factor it was not given.
        self.assertEqual(self.scale(avatar=True, cmfIconScale=1.5, cmfStandardScale=1.0), 1.5)

    def test_old_behaviour_is_byte_identical_without_the_new_fields(self):
        for icon in (0, 0.5, 1.0, 2.5):
            for sel in (False, True):
                for en, scale in ((False, 1.0), (True, 3.5)):
                    want = scale if (en and sel) else (icon if icon > 0 else 1)
                    got = self.scale(selected=sel, cmfIconScale=icon, cmfSelectedScale=scale, cmfSelectedScaleEnabled=en)
                    self.assertEqual(got, want)


class PanelEdits(unittest.TestCase):
    def test_new_finds_survive_the_whole_chain(self):
        for path, marker in ((DATA, 'cmfStandardScale'), (DESCRIBED, 'cmfStandardScale')):
            entries = EDITS[path]
            records, _ = simulate_chain(entries)
            for record in [records[i] for i, e in enumerate(entries) if marker in e['replace'] and marker not in e['find'] and 'private function cmfScaleOf' in e['replace'] + 'cmfScaleFactor:Number' ][:1]:
                self.assertFalse(record['seeded'], record['index'])
                self.assertEqual(record['matches'], 1, record['index'])

    def test_fields_declared_with_their_defaults(self):
        text = next(e['replace'] for e in EDITS[DATA] if 'cmfStandardScale' in e['replace'])
        self.assertIn('public var cmfScaleFactor:Number = 1;', text)
        self.assertIn('public var cmfSelectedFactor:Number = 1;', text)
        self.assertIn('public var cmfStandardScale:Number = 0;', text)

    def test_every_scale_read_goes_through_scale_of(self):
        reads = re.compile(r'\.cmf(IconScale|SelectedScale|StandardScale|ScaleFactor|SelectedFactor)\b(?!\s*:)')
        for path, entries in EDITS.items():
            _, text = simulate_chain(entries)
            for line in text.split('\n'):
                if reads.search(line):
                    self.assertTrue('param1.' in line or 'a.cmf' in line, path + ': ' + line.strip())
            if path == DESCRIBED:
                scale_of = text[text.index('private function cmfScaleOf('):]
                scale_of = scale_of[:scale_of.index('\n      }') + 8]
                outside = text.replace(scale_of, '')
                for line in outside.split('\n'):
                    m = reads.search(line)
                    if m:
                        self.assertTrue(line.strip().startswith('if(a.cmf'), 'read outside cmfScaleOf: ' + line.strip())

    def test_equality_check_includes_factor_fields(self):
        _, text = simulate_chain(EDITS[DESCRIBED])
        self.assertIn('a.cmfScaleFactor != b.cmfScaleFactor', text)
        self.assertIn('a.cmfSelectedFactor != b.cmfSelectedFactor', text)
        self.assertIn('a.cmfStandardScale != b.cmfStandardScale', text)


class EveryPath(unittest.TestCase):
    def test_a_game_pin_and_a_mod_pin_both_get_the_factor(self):
        env = env_for([Claim('A', 51, 150), Claim('A', 52, 200)])
        game, mod = Pin(), Pin()
        env['WriteScaleFactors'](game, 'QuestAvailable', 'QuestAvailable', '', 3)  # WritePinFields path
        env['WriteScaleFactors'](mod, 'Botanist', 'Botanist', '', 3)  # FillMissingPinFields path
        for pin in (game, mod):
            self.assertAlmostEqual(pin.f['cmfScaleFactor'], 1.5)
            self.assertAlmostEqual(pin.f['cmfSelectedFactor'], 2.0)

    def test_a_pin_through_both_paths_gets_the_factor_once(self):
        env = env_for([Claim('A', 51, 150), Claim('B', 51, 200)])
        pin = Pin()
        env['WriteScaleFactors'](pin, 'Boat', 'Boat', '', 3)
        env['WriteScaleFactors'](pin, 'Boat', 'Boat', '', 3)
        self.assertAlmostEqual(pin.f['cmfScaleFactor'], 3.0)

    def test_player_and_user_pins_get_none(self):
        env = env_for([Claim('A', 51, 150)])
        for pin in (Pin(player=True), Pin(user=True)):
            env['WriteScaleFactors'](pin, 'Player', 'Player', '', 3)
            self.assertNotIn('cmfScaleFactor', pin.f)

    def test_write_pin_fields_applies_them_before_it_ends(self):
        body = ws_function(CORE, 'public function WritePinFields(')
        self.assertRegex(body, r'if \(scaleClaims\.Size\(\) > 0\)\s*\{\s*WriteScaleFactors\(dataObject, pinKey, pinKey, pinTag, CMFLevelPlace\(\)\);\s*\}\s*ClearPinContext\(\);')

    def test_standard_counts_the_base_before_the_factors(self):
        env = env_for([Claim('A', 51, 400)])
        pins = FlashList([Pin(1.0), Pin(1.0), Pin(1.5)])
        for pin in pins:
            env['WriteScaleFactors'](pin, 'Boat', 'Boat', '', 3)
        self.assertEqual(env['StandardOfList'](pins), 100)


class DebugLine(unittest.TestCase):
    def test_scale_line_is_debug_only_and_once_per_type(self):
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        self.assertRegex(fill, r'if \(debugTiming && \(scaleClaims\.Size\(\) > 0 \|\| standardScale > 0\)\)\s*\{\s*LogScaleLines\(flashArray\);')
        body = ws_function(CORE, 'private function LogScaleLines(')
        for word in ('"scale type="', '" base="', '" factor="', '" selected="', '" standard="', '" final="', 'seen.FindFirst(kind)'):
            self.assertIn(word, body)

    def test_text_free_sizes(self):
        self.assertIn('propertyId == 51 || propertyId == 52 || propertyId == 53', ws_function(CORE, 'function CMFPropertyTextFree('))


class CompileTraps(unittest.TestCase):
    NEW = ('LogScaleLines', 'ScalePercent', 'SizeIsVanilla', 'ScaleCovers', 'ScaleProduct', 'WriteScaleFactors', 'StandardCloser', 'StandardOfList',
           'FinishStandard')

    def test_new_functions_are_short_and_plain(self):
        for name in self.NEW:
            body = ws_function(CORE, 'private function ' + name + '(')
            self.assertLess(body.count('\n'), 75, name)
            self.assertNotRegex(body, r'[^\x00-\x7f]', name)
            self.assertNotRegex(body, r'\bquest\b', name)
            self.assertNotRegex(body, r'(?<![=!<>])=\s*\w+\([^)]*\)\.\w+\s*=', name)
            # variables first: no declaration after a statement
            statements = False
            for line in body.split('\n')[2:]:
                t = line.strip()
                if t.startswith('var '):
                    self.assertFalse(statements, name + ': ' + t)
                elif t and t != '{':
                    statements = True


if __name__ == '__main__':
    unittest.main()
