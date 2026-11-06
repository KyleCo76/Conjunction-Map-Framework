"""API 19: the Player setting level (property 50). A Python model of the chain plus text tests of the WitcherScript.

The model mirrors Beats (slot arbitration) and Find (per pin) in source/core/content/scripts/local/cmfCore.ws;
the text tests check that the script has the same branch order.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import re
import unittest

from ws_text import core_text, ws_function

CORE = core_text()
SPECIFIC = {0: 0, 1: 2, 2: 6}


def provider_beats(order, a, b):
    ra = order.index(a) if a in order else -1
    rb = order.index(b) if b in order else -1
    if ra != rb:
        if ra < 0:
            return False
        if rb < 0:
            return True
        return ra < rb
    return a.lower() < b.lower()


def beats(a, b, ctx):
    """Slot arbitration (Beats): menu pick, then setter, then the order."""
    if a['provider'] == b['provider']:
        return a['order'] < b['order']
    pick = ctx.get('pick', '')
    if pick and pick != 'vanilla':
        if a['provider'] == pick:
            return True
        if b['provider'] == pick:
            return False
    setters = ctx.get('setters', {})
    ma = a['prop'] in setters.get(a['provider'], ())
    mb = b['prop'] in setters.get(b['provider'], ())
    if setters and ma != mb:
        return ma
    return provider_beats(ctx['order'], a['provider'], b['provider'])


def prepare(claims, ctx):
    winners = []
    for n, c in enumerate(claims):
        c = dict(c, order=n)
        for w, old in enumerate(winners):
            if (old['prop'], old['level'], old['type']) == (c['prop'], c['level'], c['type']):
                if beats(c, old, ctx):
                    winners[w] = c
                break
        else:
            winners.append(c)
    return winners


def find(winners, prop, pin_type, ctx):
    """Find: the pin's answer, with the Player setting step 4."""
    pick = ctx.get('pick', '')
    fall_vanilla = ctx.get('fall_vanilla', False)
    answer = pick
    if answer == 'vanilla':
        return None
    setters = ctx.get('setters', {})
    marked = any(prop in v for v in setters.values())
    set_on = marked and pin_type != 'Player' and not re.fullmatch(r'User\d', pin_type)
    best = picked = set_best = None
    best_rank = picked_rank = set_rank = -1
    for w in winners:
        if w['prop'] != prop:
            continue
        if not (w['level'] == 0 or (w['level'] == 1 and w['type'] == pin_type)):
            continue
        rank = SPECIFIC[w['level']]
        if best is None or rank > best_rank:
            best, best_rank = w, rank
        if answer and w['provider'] == answer and (picked is None or rank > picked_rank):
            picked, picked_rank = w, rank
        if set_on and prop in setters.get(w['provider'], ()):
            if set_best is None or (w['provider'] != set_best['provider'] and
                                    provider_beats(ctx['order'], w['provider'], set_best['provider'])) or \
                    (w['provider'] == set_best['provider'] and rank > set_rank):
                set_best, set_rank = w, rank
    if set_best is not None:
        best, best_rank = set_best, set_rank
    chosen = None
    if picked is not None and picked_rank == 0 and best_rank > 0:
        chosen = best
    elif picked is not None:
        chosen = picked
    elif not (best is None or (answer and fall_vanilla)):
        chosen = best
    return chosen['provider'] if chosen else None


def claim(provider, level, type_, prop, value):
    return {'provider': provider, 'level': level, 'type': type_, 'prop': prop, 'value': value}


def answer_for(claims, prop, pin_type, **ctx):
    ctx.setdefault('order', [])
    return find(prepare(claims, ctx), prop, pin_type, ctx)


class ScriptFacts(unittest.TestCase):
    def test_version_19_and_property_50(self):
        self.assertIn('function CMFGetVersion() : int { return 19; }', CORE)
        self.assertIn('function CMFPropertyPlayerSetting() : int { return 50; }', CORE)
        self.assertIn('propertyId <= 53);', ws_function(CORE, 'function CMFHasProperty('))
        self.assertIn('pictureFit,playerSetting,scaleFactor,scaleStandard"', ws_function(CORE, 'function CMFHasAbility('))

    def test_mark_handled_before_property_check(self):
        reg = ws_function(CORE, 'function CMFRegister(')
        at = reg.index('propertyId == CMFPropertyPlayerSetting()')
        self.assertLess(reg.index('propertyId == CMFPropertyGridKeepEpoch()'), at)
        self.assertLess(at, reg.index('!CMFHasProperty(propertyId)'))
        branch = reg[at:reg.index('!CMFHasProperty(propertyId)')]
        self.assertIn('SetPlayerSettings(provider, text)', branch)
        self.assertNotIn('claims.PushBack', branch)

    def test_mark_replaces_and_clears(self):
        body = ws_function(CORE, 'public function SetPlayerSettings(')
        self.assertEqual(body.count('dirty = true;'), 3)
        self.assertIn('playerSetters.Erase(at);', body)
        self.assertIn('playerSetterIds[at] != clean', body)
        release = ws_function(CORE, 'public function ReleaseProvider(')
        self.assertIn('playerSetters.Erase(i);', release)

    def test_added_together_properties_refused(self):
        body = ws_function(CORE, 'private function PlayerSettingRefusal(')
        for needle in ('id == 5', 'CMFPropertyHidden()', 'CMFPropertyLabelHide()', 'CMFPropertyTabHide()',
                       'CMFPropertyTabHidden()', 'CMFPropertyPinClickHint()', 'CMFPropertyPinClickButton()'):
            self.assertIn(needle, body)
        self.assertIn('return "added";', body)
        self.assertIn('player setting refused provider=', ws_function(CORE, 'public function SetPlayerSettings('))

    def test_no_setter_is_today_in_the_script(self):
        beats = ws_function(CORE, 'private function Beats(')
        self.assertIn('anySetter && SetterDecides(', beats)
        tag = ws_function(CORE, 'private function TagBeats(')
        self.assertIn('anySetter && SetterDecides(', tag)
        find_fn = ws_function(CORE, 'private function Find(')
        self.assertIn('setterOn = anySetter && setterMarked[propertyId]', find_fn)
        # nothing else in Find reads the new state
        self.assertEqual(len(re.findall(r'anySetter', find_fn)), 1)

    def test_beats_order_pick_then_setter_then_order(self):
        beats = ws_function(CORE, 'private function Beats(')
        self.assertLess(beats.index('MenuPickDecides('), beats.index('SetterDecides('))
        self.assertLess(beats.index('SetterDecides('), beats.index('PieceBeats('))
        self.assertLess(beats.index('PieceBeats('), beats.index('ProviderBeats('))

    def test_status_level_name_and_order(self):
        self.assertIn('case 8:\n\t\t\t\treturn "Player setting";', ws_function(CORE, 'public function LevelName('))
        win = ws_function(CORE, 'public function WinnerOf(')
        self.assertLess(win.index('l == 3 && anySetter'), win.index('if (l == skipLevel)'))
        self.assertIn('level = 8;', win)

    def test_piece_beats_unchanged_for_other_callers(self):
        body = ws_function(CORE, 'public function PieceBeats(')
        self.assertIn('MenuPickDecides(choice, a, b, result)', body)
        for needle in ('OrderDecides(menuOrder', 'PickDecides(fileChoices[choice]', 'PickDecides(fileChoices[feature]',
                       'return ProviderBeats(a, b);'):
            self.assertIn(needle, body)
        helper = ws_function(CORE, 'private function MenuPickDecides(')
        self.assertLess(helper.index('menuChoices[choice]'), helper.index('menuChoices[feature]'))

    def test_memo_valid_with_setters(self):
        find_fn = ws_function(CORE, 'private function Find(')
        # the memo key is level, type and property; the setter step reads only per-preparation state and the pin type
        self.assertIn('memoAt = (maxLevel * typeKeys.Size() + t) * 64 + propertyId;', find_fn)
        self.assertLess(find_fn.index('setterOn ='), find_fn.index('memoState[memoAt] = chosen + 2;'))
        self.assertNotIn('timingPins', ws_function(CORE, 'private function SetterDecides('))

    def test_compile_traps(self):
        new = ''.join(ws_function(CORE, h) for h in (
            'private function PlayerSettingRefusal(', 'public function SetPlayerSettings(', 'private function PrepareSetters(',
            'private function IsSetter(', 'private function SetterDecides(', 'private function IsOwnMarkerType(',
            'private function SetterOffers(', 'private function MenuPickDecides(', 'private function Beats(',
            'private function TagBeats(', 'private function SetterClaimBeats('))
        self.assertTrue(new.isascii())
        self.assertNotRegex(new, r'theGame\.CMFGetCore\(\)\.\w+(\.\w+)* =')
        self.assertNotRegex(new, r'\n *return;')
        self.assertNotIn('StrSplit', new)
        self.assertNotIn('StringToName', new)
        for head in ('public function SetPlayerSettings(', 'private function PrepareSetters(', 'private function SetterOffers(',
                     'private function Beats(', 'private function TagBeats('):
            body = ws_function(CORE, head)
            body = body[body.index('{') + 1:]
            seen_statement = False
            for line in body.split('\n'):
                text = line.strip()
                if text.startswith('var '):
                    self.assertFalse(seen_statement, head + ': var after a statement: ' + text)
                elif text and text not in ('{', '}') and not text.startswith('//'):
                    seen_statement = True


class ChainModel(unittest.TestCase):
    ORDER = ['modMQI', 'modInkAndIron', 'modFogOfWar']

    def test_no_setter_is_today(self):
        claims = [claim('modInkAndIron', 0, '', 10, 150), claim('modMQI', 1, 'SideQuest', 10, 120),
                  claim('modFogOfWar', 0, '', 10, 90)]
        self.assertEqual(answer_for(claims, 10, 'Gear', order=self.ORDER), 'modInkAndIron')
        self.assertEqual(answer_for(claims, 10, 'SideQuest', order=self.ORDER), 'modMQI')
        self.assertIsNone(answer_for(claims, 10, 'Gear', order=self.ORDER, pick='vanilla'))

    def test_setter_beats_mod_order(self):
        claims = [claim('modMQI', 0, '', 10, 100), claim('modInkAndIron', 0, '', 1, 'ink'),
                  claim('modCMFPinSettings', 0, '', 10, 150), claim('modFogOfWar', 0, '', 28, 1),
                  claim('modCMFPinSettings', 0, '', 28, 1)]
        setters = {'modCMFPinSettings': (10, 28)}
        self.assertEqual(answer_for(claims, 10, 'Gear', order=self.ORDER, setters=setters), 'modCMFPinSettings')
        self.assertEqual(answer_for(claims, 28, 'Gear', order=self.ORDER, setters=setters), 'modCMFPinSettings')
        self.assertEqual(answer_for(claims, 1, 'Gear', order=self.ORDER, setters=setters), 'modInkAndIron')

    def test_setter_every_pin_beats_pack_type_and_tag_claims(self):
        claims = [claim('modMQI', 1, 'SideQuest', 10, 120), claim('modCMFPinSettings', 0, '', 10, 150)]
        setters = {'modCMFPinSettings': (10,)}
        self.assertEqual(answer_for(claims, 10, 'SideQuest', order=self.ORDER, setters=setters), 'modCMFPinSettings')
        self.assertEqual(answer_for(claims, 10, 'SideQuest', order=self.ORDER), 'modMQI')

    def test_setter_own_type_claim_beats_own_every_pin(self):
        claims = [claim('modCMFPinSettings', 0, '', 10, 150), claim('modCMFPinSettings', 1, 'SideQuest', 10, 200)]
        setters = {'modCMFPinSettings': (10,)}
        winners = prepare(claims, {'order': self.ORDER, 'setters': setters})
        pin = find(winners, 10, 'SideQuest', {'order': self.ORDER, 'setters': setters})
        self.assertEqual(pin, 'modCMFPinSettings')
        picked = [w for w in winners if w['level'] == 1][0]['value']
        self.assertEqual(picked, 200)

    def test_pick_vanilla_beats_setter(self):
        claims = [claim('modCMFPinSettings', 0, '', 10, 150)]
        self.assertIsNone(answer_for(claims, 10, 'Gear', setters={'modCMFPinSettings': (10,)}, pick='vanilla'))

    def test_pick_other_mod_beats_setter_where_it_has_claims(self):
        claims = [claim('modMQI', 1, 'SideQuest', 10, 120), claim('modCMFPinSettings', 0, '', 10, 150)]
        setters = {'modCMFPinSettings': (10,)}
        self.assertEqual(answer_for(claims, 10, 'SideQuest', order=self.ORDER, setters=setters, pick='modMQI'), 'modMQI')

    def test_pick_other_mod_then_setter_on_the_rest(self):
        claims = [claim('modMQI', 1, 'SideQuest', 10, 120), claim('modCMFPinSettings', 0, '', 10, 150)]
        setters = {'modCMFPinSettings': (10,)}
        self.assertEqual(answer_for(claims, 10, 'Gear', order=self.ORDER, setters=setters, pick='modMQI'),
                         'modCMFPinSettings')

    def test_pick_other_mod_fall_vanilla_shows_game_look(self):
        claims = [claim('modMQI', 1, 'SideQuest', 10, 120), claim('modCMFPinSettings', 0, '', 10, 150)]
        setters = {'modCMFPinSettings': (10,)}
        self.assertIsNone(answer_for(claims, 10, 'Gear', order=self.ORDER, setters=setters, pick='modMQI',
                                     fall_vanilla=True))

    def test_two_setters_follow_the_order(self):
        claims = [claim('modB', 0, '', 10, 1), claim('modA', 0, '', 10, 2)]
        setters = {'modA': (10,), 'modB': (10,)}
        self.assertEqual(answer_for(claims, 10, 'Gear', order=['modB', 'modA'], setters=setters), 'modB')
        self.assertEqual(answer_for(claims, 10, 'Gear', order=['modA', 'modB'], setters=setters), 'modA')

    def test_setter_skips_player_and_user_markers(self):
        claims = [claim('modPack', 1, 'Player', 10, 120), claim('modCMFPinSettings', 0, '', 10, 150)]
        setters = {'modCMFPinSettings': (10,)}
        self.assertEqual(answer_for(claims, 10, 'Player', order=self.ORDER, setters=setters), 'modPack')
        self.assertEqual(answer_for([claim('modPack', 1, 'User3', 10, 90)] + claims[1:], 10, 'User3',
                                    order=self.ORDER, setters=setters), 'modPack')
        find_fn = ws_function(CORE, 'private function Find(')
        self.assertIn('!IsOwnMarkerType(pinType)', find_fn)

    def test_unmarked_property_of_a_setter_follows_the_order(self):
        claims = [claim('modCMFPinSettings', 0, '', 1, 'a'), claim('modMQI', 0, '', 1, 'b')]
        setters = {'modCMFPinSettings': (10,)}
        self.assertEqual(answer_for(claims, 1, 'Gear', order=self.ORDER, setters=setters), 'modMQI')


class ReaderTable(unittest.TestCase):
    """Every function that reads a winner's answer, and what the Player setting level does there (API 19)."""
    # function -> 'honoured' (the level applies) or 'untouched' (and why: see the author guide table).
    READERS = {
        'SizeIsVanilla': 'untouched: the Pin size row reading Vanilla', 'Beats': 'honoured', 'TagBeats': 'honoured', 'Find': 'honoured', 'StyleOwnerBeats': 'honoured',
        'PieceBeats': 'untouched: the menu pick and the order, every honoured reader checks the level first',
        'WinnerOf': 'honoured', 'ReadChoices': 'untouched: reads the menu picks',
        'StyleAllowed': 'untouched: a pick row naming a mod or Vanilla still beats the level',
        'ItemStyleOwner': 'untouched', 'ComputeThemeStyleOwner': 'untouched',
        'SendWideVanilla': 'untouched', 'AnswerAllows': 'untouched', 'NoteLabelHideOffer': 'untouched',
        'OpeningViewWinner': 'untouched', 'OpeningViewBeats': 'untouched', 'StyleClick': 'untouched',
        'DecidedAnswer': 'untouched',
    }

    def readers_found(self):
        found = {}
        current = None
        for line in CORE.split('\n'):
            m = re.match(r'\t(?:public |private )?(?:function|event) (\w+)\(', line)
            if m:
                current = m.group(1)
            if 'decideAnswer[' in line or 'PieceBeats(' in line:
                found[current] = True
        return found

    def test_every_answer_reader_listed(self):
        missing = sorted(set(self.readers_found()) - set(self.READERS))
        self.assertEqual(missing, [], 'a reader of the winner answers is not in the table: ' + ', '.join(missing))

    def test_honoured_readers_ask_the_level(self):
        for name in ('Beats', 'TagBeats', 'StyleOwnerBeats'):
            body = ws_function(CORE, 'function ' + name + '(')
            self.assertIn('SetterDecides(', body, name)
        self.assertIn('setterBest', ws_function(CORE, 'function Find('))
        self.assertIn('l == 3 && anySetter', ws_function(CORE, 'function WinnerOf('))

    def test_stylepin_asks_the_level_before_the_order(self):
        body = ws_function(CORE, 'public function StylePin(')
        self.assertIn('StyleOwnerBeats(choice, propertyId, owner, provider', body)
        self.assertNotIn('PieceBeats(choice, owner, provider)', body)
        helper = ws_function(CORE, 'function StyleOwnerBeats(')
        self.assertLess(helper.index('MenuPickDecides('), helper.index('SetterDecides('))
        self.assertLess(helper.index('SetterDecides('), helper.index('return PieceBeats('))
        self.assertIn('IsOwnMarkerType(pinType)', helper)
        self.assertIn('anySetter &&', helper)

    def test_unmarked_stylepin_answers_like_piecebeats(self):
        helper = ws_function(CORE, 'function StyleOwnerBeats(')
        self.assertTrue(helper.rstrip().endswith('return PieceBeats(choice, owner, provider);\n\t}'))


if __name__ == '__main__':
    unittest.main()
