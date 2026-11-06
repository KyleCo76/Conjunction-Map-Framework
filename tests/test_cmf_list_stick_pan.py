"""The left stick pans the map in every direction while the Quest List holds focus (panel part).

A screen movie may decline the LEFT stick's axis (handleInput returns false, the API 17 mechanism); the router then lets it reach
the map and stamps HubMap.cmfStickPanAt; HubMap.cmfMovieStickPan lets that push pan in every direction while the movie holds the pan lock.
Text checks and a Python model; the cloud cannot run the panel.
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
MAP = EDITS['red/game/witcher3/menus/worldmap/MapMenu.as']
HUB = EDITS['red/game/witcher3/menus/worldmap/HubMap.as']


def balanced(text, start):
    i = text.index('{', start)
    depth = 0
    for k in range(i, len(text)):
        depth += text[k] == '{'
        depth -= text[k] == '}'
        if depth == 0:
            return text[start:k + 1]


def router():
    r = next(e['replace'] for e in MAP if 'public function cmfMovieInput' in e['replace'])
    return balanced(r, r.index('public function cmfMovieInput'))


def pan_fn():
    r = next(e['replace'] for e in HUB if 'function cmfMovieStickPan' in e['replace'])
    return balanced(r, r.index('private function cmfMovieStickPan'))


WINDOW = 150


def route(event_type, left_stick_code, movie_declines):
    """Model of the router's decline for an axis event: True = the event goes on to the map."""
    declined = movie_declines
    if declined and event_type == 'axis':
        if left_stick_code:
            return True, 'stamp'
        declined = False
    return declined, None


def stick_pan(locked, x, y, now, stamped_at):
    """Model of cmfMovieStickPan: returns (x, y) given to scrollMap, or None."""
    if not locked:
        return (x, y)
    if (x != 0 or y != 0) and now - stamped_at <= WINDOW:
        return (x, y)
    return None


class Model(unittest.TestCase):
    def test_left_stick_axis_declined_reaches_the_map(self):
        self.assertEqual(route('axis', True, True), (True, 'stamp'))

    def test_right_stick_axis_stays_with_the_movie(self):
        self.assertEqual(route('axis', False, True), (False, None))

    def test_a_movie_that_does_not_decline_keeps_the_event(self):
        self.assertEqual(route('axis', True, False), (False, None))

    def test_key_declines_are_unchanged(self):
        self.assertEqual(route('key', False, True), (True, None))
        self.assertEqual(route('key', False, False), (False, None))

    def test_unlocked_map_pans_as_before(self):
        self.assertEqual(stick_pan(False, 3, 4, 1000, -100000), (3, 4))

    def test_locked_map_pans_every_direction_for_a_stamped_push(self):
        self.assertEqual(stick_pan(True, 3, 4, 1000, 900), (3, 4))
        self.assertEqual(stick_pan(True, -3, 0, 1000, 900), (-3, 0))

    def test_locked_map_does_not_pan_without_a_fresh_stamp(self):
        self.assertIsNone(stick_pan(True, 3, 4, 1000, 800))
        self.assertIsNone(stick_pan(True, 3, 4, 1000, -100000))

    def test_locked_map_pans_a_vertical_stamped_push(self):
        self.assertEqual(stick_pan(True, 0, 5, 1000, 990), (0, 5))
        self.assertIsNone(stick_pan(True, 0, 5, 1000, 800))
        self.assertIsNone(stick_pan(True, 0, 0, 1000, 990))


class Source(unittest.TestCase):
    def test_router_text(self):
        r = router()
        self.assertIn('if(declined && details.type == "axis")', r)
        self.assertIn('if(code == KeyCode.PAD_LEFT_STICK_AXIS && this.mcHubMap) { this.mcHubMap.cmfStickPanStamp(); }', r)
        self.assertIn('else { declined = false; }', r)
        # after the movie's handleInput ran and before the key marker is dropped and the event returned
        self.assertLess(r.index('declined = fn(event) === false'), r.index('if(declined && details.type == "axis")'))
        self.assertLess(r.index('if(declined && details.type == "axis")'), r.index('if(declined)\n'))

    def test_pan_text(self):
        p = pan_fn()
        self.assertIn('if(!this.cmfMoviePanLocked)', p)
        self.assertIn('return this.cmfMoviePan(x,y);', p)
        self.assertIn('if((x != 0 || y != 0) && getTimer() - this.cmfStickPanAt <= 150)', p)
        self.assertIn('this.cmfNote("list stick pan x="', p)
        self.assertIn('this.cmfNote("list stick pan end")', p)
        self.assertIn('if(!this.cmfStickPanLive)', p)
        text = '\n'.join(e['replace'] for e in HUB)
        self.assertIn('this.cmfNote("list stick pan stamp")', text)
        self.assertIn('return this.scrollMap(x,y);', p)
        self.assertIn('this.cmfNavMark("pad");', p)

    def test_the_pan_lock_function_is_unchanged(self):
        r = next(e['replace'] for e in HUB if 'private function cmfMoviePan(' in e['replace'])
        self.assertIn('return this.cmfMoviePanLocked ? false : this.scrollMap(x,y);', r)
        # the keyboard and mouse callers still use the plain lock
        text = '\n'.join(e['replace'] for e in HUB)
        self.assertIn('this._isScrolling = this.cmfMoviePan(dx,dy);', text)
        self.assertIn('this._isScrolling = this.cmfMoviePan(_loc3_,_loc2_);', text)

    def test_only_the_pad_callers_use_the_stick_pan(self):
        text = '\n'.join(e['replace'] for e in HUB)
        self.assertEqual(text.count('this.cmfMovieStickPan('), 3)        # two pad call sites and the roam path
        self.assertIn('this._isScrolling = this.cmfMovieStickPan(this.cmfPadX * 0.5 * f,this.cmfPadY * 0.5 * f);', text)
        self.assertIn('this._isScrolling = this.cmfMovieStickPan(this._gamepadScrollX * 0.5,this._gamepadScrollY * 0.5);', text)
        self.assertIn('scrolled = this.cmfMovieStickPan(param1,param2);', text)

    def test_the_edit_finds_did_not_change(self):
        self.assertEqual(HUB[98]['find'], 'this._isScrolling = this.scrollMap(this.cmfPadX * 0.5 * f,this.cmfPadY * 0.5 * f);')
        self.assertEqual(HUB[100]['find'], 'this._isScrolling = this.scrollMap(this._gamepadScrollX * 0.5,this._gamepadScrollY * 0.5);')
        self.assertEqual(HUB[135]['find'], 'return this.cmfMoviePanLocked ? false : this.scrollMap(x,y);')
        for n in (98, 100, 135):
            self.assertEqual(HUB[n]['count'], 1)

    def test_roam_still_runs_on_the_stick_path(self):
        t = '\n'.join(e['replace'] for e in HUB)
        self.assertIn('this.cmfRoamStick = this.cmfRoamOn;\n         scrolled = this.cmfMovieStickPan(param1,param2);', t)

    def test_compile_audit(self):
        for text in (pan_fn(), router()):
            self.assertEqual(text.count('{'), text.count('}'))
            self.assertEqual(text.count('('), text.count(')'))
        p = pan_fn()
        lines = [l.strip() for l in p.split('\n')[2:]]
        seen = False
        for l in lines:
            if l.startswith('var '):
                self.assertFalse(seen)
            elif l:
                seen = True
        self.assertFalse(re.search(r'\)\s*\.\s*\w+\s*=[^=]', p))
        t = '\n'.join(e['replace'] for e in HUB)
        self.assertEqual(len(re.findall(r'function cmfMovieStickPan\(', t)), 1)
        self.assertEqual(len(re.findall(r'var cmfStickPanAt\b', t)), 1)

    def test_no_model_names(self):
        for text in (pan_fn(), router()):
            for w in ('opus', 'sonnet'):
                self.assertNotIn(w, text.lower())


if __name__ == '__main__':
    unittest.main()
