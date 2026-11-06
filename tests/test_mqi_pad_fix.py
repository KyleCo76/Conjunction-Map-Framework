"""MQI adapter 2.5.5 (pad fix): a D-pad press arrives twice (its own code, then the arrow code); the stick arrives once with
fromJoystick true. The Quest List acts on each press once. Event pairs from a player's log: up 142 dpad_up then 38 up; down 143
then 40; left 144 then 37; right 145 then 39; the stick's directions alone as 37 to 40 with fromJoystick true.
The model mirrors handleInput's new lines; nothing here ran in the game.
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AS = (ROOT / 'source/adapters/map-quest-insight/movie-src/MqiAdapterQuestList.as').read_text()
QL = (ROOT / 'source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_questlist.ws').read_text()
CORE = (ROOT / 'source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_cmf.ws').read_text()
TWIN_MS = 30


def func(name, text=AS):
    m = re.search(r'function\s+' + name + r'\s*\(', text)
    assert m, name
    start = text.index('{', m.start())
    depth = 0
    for i in range(start, len(text)):
        depth += text[i] == '{'
        depth -= text[i] == '}'
        if depth == 0:
            return text[m.start():i + 1]


def pad_dir(code, nav):
    for c, n, d in ((142, 'dpad_up', 'up'), (143, 'dpad_down', 'down'), (144, 'dpad_left', 'left'), (145, 'dpad_right', 'right')):
        if code == c or nav == n:
            return d
    return ''


def arrow_dir(code):
    return {38: 'up', 40: 'down', 37: 'left', 39: 'right'}.get(code, '')


class List:
    """Model of the new handleInput lines for keyDown events on a quest row or a header."""

    def __init__(self, row='quest'):
        self.row, self.dpad_dir, self.dpad_at, self.acts = row, '', 0, []

    def key(self, code, nav, joy, t):
        pad, arrow = pad_dir(code, nav), arrow_dir(code)
        stick = arrow != '' and joy
        if stick and arrow != '':
            self.acts.append('declined-' + arrow)         # stickDeclines: the key goes on to the map
            return
        if pad != '':
            self.dpad_dir, self.dpad_at = pad, t
        elif arrow != '' and not stick and arrow == self.dpad_dir and t - self.dpad_at <= TWIN_MS:
            return
        if pad == 'up' or arrow == 'up':
            self.acts.append('up')
        elif pad == 'down' or arrow == 'down':
            self.acts.append('down')
        elif code in (37, 39) or nav in ('dpad_left', 'dpad_right'):
            d, dpad = (pad, True) if pad else (arrow, False)
            if self.row == 'quest':
                if dpad and d == 'left':
                    return
                self.acts.append('toggle' if d == 'right' else 'close-objs')
            else:
                self.acts.append('fold')


class Model(unittest.TestCase):
    def press(self, lst, code, nav, joy, t):
        """A D-pad press is two events: its code, then the direction code."""
        lst.key(code, nav, joy, t)

    def test_dpad_up_down_step_once(self):
        l = List()
        l.key(142, 'dpad_up', False, 1000); l.key(38, 'up', False, 1004)
        l.key(143, 'dpad_down', False, 2000); l.key(40, 'down', False, 2008)
        self.assertEqual(l.acts, ['up', 'down'])

    def test_dpad_right_toggles_once(self):
        l = List()
        l.key(145, 'dpad_right', False, 1000); l.key(39, 'right', False, 1005)
        self.assertEqual(l.acts, ['toggle'])

    def test_dpad_left_does_nothing_on_a_quest_row_and_folds_a_header(self):
        l = List()
        l.key(144, 'dpad_left', False, 1000); l.key(37, 'left', False, 1005)
        self.assertEqual(l.acts, [])
        h = List('header')
        h.key(144, 'dpad_left', False, 1000); h.key(37, 'left', False, 1005)
        h.key(145, 'dpad_right', False, 3000); h.key(39, 'right', False, 3003)
        self.assertEqual(h.acts, ['fold', 'fold'])

    def test_the_stick_never_moves_the_list(self):
        l = List()
        l.key(38, 'up', True, 1000); l.key(40, 'down', True, 1100)
        l.key(39, 'right', True, 1200); l.key(37, 'left', True, 1300)
        self.assertEqual(l.acts, ['declined-up', 'declined-down', 'declined-right', 'declined-left'])
        h = List('header')
        h.key(39, 'right', True, 1000)
        self.assertEqual(h.acts, ['declined-right'])    # no fold from the stick: Y folds

    def test_keyboard_arrows_are_unchanged(self):
        l = List()
        l.key(38, 'up', False, 1000); l.key(40, 'down', False, 1010); l.key(39, 'right', False, 1020); l.key(37, 'left', False, 1030)
        self.assertEqual(l.acts, ['up', 'down', 'toggle', 'close-objs'])

    def test_a_stick_press_right_after_a_dpad_press_goes_to_the_map(self):
        l = List()
        l.key(142, 'dpad_up', False, 1000); l.key(38, 'up', True, 1005)
        self.assertEqual(l.acts, ['up', 'declined-up'])

    def test_a_late_arrow_is_not_a_twin(self):
        l = List()
        l.key(142, 'dpad_up', False, 1000); l.key(38, 'up', False, 1000 + TWIN_MS + 1)
        self.assertEqual(l.acts, ['up', 'up'])

    def test_a_different_direction_arrow_is_not_a_twin(self):
        l = List()
        l.key(142, 'dpad_up', False, 1000); l.key(40, 'down', False, 1005)
        self.assertEqual(l.acts, ['up', 'down'])


class Source(unittest.TestCase):
    def test_handle_input_text(self):
        h = func('handleInput')
        self.assertIn('pad = padDirOf(code,nav);', h)
        self.assertIn('arrow = arrowDirOf(code);', h)
        self.assertIn('stick = arrow != "" && details.fromJoystick == true;', h)
        self.assertIn('if(pad != "") { dpadDir = pad; dpadAt = getTimer(); }', h)
        self.assertIn('else if(arrow != "" && !stick && arrow == dpadDir && getTimer() - dpadAt <= TWIN_MS)', h)
        self.assertIn('padLog("twin dropped "', h)
        self.assertNotIn('isStick', AS)
        self.assertIn('private static const TWIN_MS:int = 30;', AS)
        # the twin test sits after the key-up branch and before every action
        self.assertLess(h.index('"keyUp"'), h.index('dpadDir = pad'))
        self.assertLess(h.index('dpadDir = pad'), h.index('move(selected - 1)'))
        # R3 and X still decline first
        self.assertLess(h.index('return false;'), h.index('"keyUp"'))

    def test_stick_decline_is_one_isolated_function(self):
        s = func('stickDeclines')
        self.assertIn('if(stick) { return arrow != ""; }', s)
        self.assertIn('details.type == "axis"', s)
        self.assertIn('Math.abs(Number(v.xvalue)) >= 0.6 || Math.abs(Number(v.yvalue)) >= 0.6', s)
        self.assertEqual(AS.count('stickDeclines('), 2)
        h = func('handleInput')
        self.assertIn('declines = stickDeclines(details,arrow,stick) || aDeclines;', h)
        self.assertIn('if(code == 88 || nav == "gamepad_R3" || declines)', h)
        self.assertEqual(h.count('return false;'), 1)
        self.assertNotIn('stickSide', AS)

    def test_axis_decline_model(self):
        def declines(x, y):
            return abs(x) >= 0.6 or abs(y) >= 0.6
        self.assertTrue(declines(0.9, 0.1))
        self.assertTrue(declines(-0.78, -0.51))   # partly vertical: the map's
        self.assertFalse(declines(0.3, 0.1))      # a small push is nobody's
        self.assertTrue(declines(0.7, 0.9))
        self.assertTrue(declines(0.0, 1.0))

    def test_y_still_folds_headers(self):
        self.assertIn('code == 67 || nav == "gamepad_Y"', func('handleInput'))
        self.assertIn('fold(selected)', func('handleInput'))

    def test_compile_audit(self):
        for name in ('handleInput', 'sideKey', 'stickDeclines', 'padDirOf', 'arrowDirOf', 'padLog', 'logDecline'):
            body = func(name)
            lines = [l.strip() for l in body.split('\n')[2:]]
            seen = False
            for l in lines:
                if l.startswith('var '):
                    self.assertFalse(seen, '%s: var after a statement: %s' % (name, l))
                elif l and not l.startswith('//'):
                    seen = True
            self.assertFalse(re.search(r'\)\s*\.\s*\w+\s*=[^=]', body), name)
            self.assertEqual(body.count('{'), body.count('}'), name)
            self.assertEqual(body.count('('), body.count(')'), name)
            for word in ('var in:', 'var is:', 'var as:', 'var new:', 'var function:', 'var default:', 'var class:', 'var var:', 'var dir:Array'):
                self.assertNotIn(word, body)
        # names new in 2.5.5 do not clash with an existing member
        for name in ('dpadDir', 'dpadAt', 'padDirOf', 'arrowDirOf', 'stickDeclines', 'TWIN_MS'):
            self.assertEqual(len(re.findall(r'(?:var|function|const)\s+' + name + r'\b', AS)), 1, name)
        # a local called pad, arrow or stick must not shadow a member
        for name in ('pad', 'arrow', 'stick'):
            members = re.findall(r'private var ' + name + r'\b', AS)
            self.assertLessEqual(len(members), 1)

    def test_no_model_names(self):
        for w in ('opus', 'sonnet', 'claude'):
            self.assertNotIn(w, AS.lower().replace('claude', '', 0))


class PadLog(unittest.TestCase):
    def test_log_lines_in_the_movie_and_the_adapter(self):
        h = func('handleInput')
        self.assertIn('padLog((pad != "" ? "dpad " + pad : "stick " + arrow) + " code=" + code + " nav=" + nav + " taken");', h)
        self.assertIn('if(declines && !aDeclines) { logDecline(details,arrow); }', h)
        self.assertEqual(func('padLog').count('note("padlog",text)'), 1)
        d = func('logDecline')
        self.assertIn('"axis declined x="', d)
        self.assertIn('"stick " + arrow + " declined code="', d)
        self.assertIn('if(!axisDeclined)', d)           # the axis is logged once per push, not per event
        ql = func('MqiAdapterQlEvent', QL)
        self.assertIn('if (eventName == "padlog")', ql)
        self.assertIn('LogChannel(\'CMF\', "CMF mqi adapter questlist pad " + value);', ql)

    def test_keyboard_presses_are_not_logged(self):
        h = func('handleInput')
        self.assertIn('details.value == "keyDown" && (pad != "" || stick)', h)


class StretchTry(unittest.TestCase):
    def test_stretch_max_800_rides_the_stretch_switch(self):
        send = func('MqiAdapterSendBeside', CORE)
        self.assertIn("CMFStyle(\"modMapQuestInsight\", 'tooltip', types[i], 'stretchMax', on, 800);", send)
        self.assertGreater(send.index("'stretchMax'"), send.index("'stretch', on, 1"))
        self.assertLess(send.index("'stretchMax'"), send.index('\n\t\t}\n\t}\n}'))
        self.assertIn("CMFHasAbility('tooltip', 'stretch')", send)
        # off withdraws it with the rest: the same `on` text as the stretch key
        self.assertIn('on = "unset";', send)


if __name__ == '__main__':
    unittest.main()
