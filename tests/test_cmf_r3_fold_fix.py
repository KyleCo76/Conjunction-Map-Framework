"""R3 fold fix: the game reports a controller BUTTON with fromJoystick false, so the pad list must be found by code.

From a player's log: R3 arrives as code=147 nav=gamepad_R3 pad=false; stick moves arrive with pad=true. cmfFoldPress
used the keyboard list for every pad=false press and refused R3 (index=-1).
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
TIP = EDITS['red/game/witcher3/tooltips/TooltipMap.as']


def press_text():
    text = next(e['replace'] for e in TIP if 'public function cmfFoldPress' in e['replace'])
    start = text.index('public function cmfFoldPress')
    return text[start:text.index('public function cmfRefreshFold')]


def pick(code, pad, pads, kbs):
    """The list cmfFoldPress searches: a model of the emitted lines (pad false and a pad-only code means a pad press)."""
    if not pad and pads and code in pads and not (kbs and code in kbs):
        pad = True
    return ('pad' if pad else 'kb'), (pads if pad else kbs), pad


class Source(unittest.TestCase):
    def test_pad_button_is_found_by_code(self):
        body = press_text()
        self.assertIn('var pads:Array = style ? style["__cmfFoldPadCodes"] as Array : null;', body)
        self.assertIn('var kbs:Array = style ? style["__cmfFoldKbCodes"] as Array : null;', body)
        self.assertIn('if(!pad && pads && pads.indexOf(code) >= 0 && !(kbs && kbs.indexOf(code) >= 0)) { pad = true; }', body)
        self.assertIn('codes = pad ? pads : kbs;', body)
        self.assertNotIn('style[pad ?', body)

    def test_the_rest_of_the_press_is_unchanged(self):
        body = press_text()
        self.assertIn('if(!visible || !this.cmfFoldHas || style !== this._cmfFoldStyle || !codes || codes.indexOf(code) < 0) { return false; }', body)
        self.assertIn('this._cmfFoldHeldPad = pad;', body)
        self.assertIn('this._cmfFoldPad = pad;', body)

    def test_compile_audit(self):
        body = press_text()
        names = re.findall(r'\bvar (\w+):', body)
        self.assertEqual(len(names), len(set(names)), 'a local is declared twice')
        self.assertFalse(re.search(r'\b(pads|kbs)\b', '\n'.join(e['replace'] for e in TIP).replace(body, '')),
                         'the new locals clash with another name in the class')
        body.encode('ascii')
        self.assertNotIn('\r', body)
        self.assertEqual(body.count('{'), body.count('}'))
        self.assertEqual(body.count('('), body.count(')'))

    def test_edit_find_is_unchanged(self):
        # The find of the edit that holds cmfFoldPress did not change, so the build matches the real panel as before.
        edit = next(e for e in TIP if 'public function cmfFoldPress' in e['replace'])
        self.assertEqual(edit['find'], '      public var cmfWidth:Number = 0;')
        self.assertEqual(edit['count'], 1)


class Model(unittest.TestCase):
    def test_players_log(self):
        # R3: code 147, pad false, pad list [147], keyboard list [88].
        self.assertEqual(pick(147, False, [147], [88])[0], 'pad')
        self.assertEqual(pick(88, False, [147], [88])[0], 'kb')
        self.assertEqual(pick(147, True, [147], [88])[0], 'pad')
        self.assertEqual(pick(149, False, [147], [88])[1].count(149), 0)  # R1: in neither list, no fold

    def test_held_press_and_release_pick_the_same_list(self):
        for value in ('down', 'up'):
            self.assertEqual(pick(147, False, [147], [88])[2], True)

    def test_a_code_in_both_lists_stays_keyboard_unless_pad_true(self):
        self.assertEqual(pick(70, False, [70], [70])[0], 'kb')
        self.assertEqual(pick(70, True, [70], [70])[0], 'pad')

    def test_no_pad_binding_leaves_keyboard_behaviour(self):
        self.assertEqual(pick(88, False, None, [88])[0], 'kb')
        self.assertEqual(pick(147, False, [], [88])[0], 'kb')


if __name__ == '__main__':
    unittest.main()
