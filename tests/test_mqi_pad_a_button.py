"""The controller's A with the Quest List open: a pin under the reticle takes A to the map; otherwise A acts on the row,
except on a section header where it does nothing (Y folds). Model plus source text; nothing here ran in the game.
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AS = (ROOT / 'source/adapters/map-quest-insight/movie-src/MqiAdapterQuestList.as').read_text()
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
HUB = EDITS['red/game/witcher3/menus/worldmap/HubMap.as']
MM = EDITS['red/game/witcher3/menus/worldmap/MapMenu.as']


def func(name):
    m = re.search(r'function\s+' + name + r'\s*\(', AS)
    start = AS.index('{', m.start())
    depth = 0
    for i in range(start, len(AS)):
        depth += AS[i] == '{'
        depth -= AS[i] == '}'
        if depth == 0:
            return AS[m.start():i + 1]


class A:
    """Model of the A lines. pin_under: map.pinAtReticle. Returns the action taken."""

    def __init__(self, row, pin_under, device_pad=True):
        self.row, self.pin, self.pad, self.to_map = row, pin_under, device_pad, False

    def press(self, value, code=13, nav='enter-gamepad_A'):
        pad_a = self.pad and nav == 'enter-gamepad_A' and code != 69
        if pad_a and value == 'keyDown':
            self.to_map = self.pin
        declines = pad_a and self.to_map
        if pad_a and value == 'keyUp':
            self.to_map = False
        if declines:
            return 'map'
        if value != 'keyDown':
            return 'ignored'
        if pad_a and self.row == 'header':
            return 'nothing'
        return 'activate'


class Model(unittest.TestCase):
    def test_pin_under_reticle_goes_to_the_map_press_hold_release(self):
        a = A('header', True)
        self.assertEqual([a.press('keyDown'), a.press('keyHold'), a.press('keyUp')], ['map', 'map', 'map'])

    def test_quest_row_without_a_pin_tracks_as_before(self):
        self.assertEqual(A('quest', False).press('keyDown'), 'activate')

    def test_header_without_a_pin_does_nothing(self):
        self.assertEqual(A('header', False).press('keyDown'), 'nothing')

    def test_the_decision_is_made_at_the_press(self):
        a = A('quest', True)
        self.assertEqual(a.press('keyDown'), 'map')
        a.pin = False                       # the pin goes away while A is held
        self.assertEqual(a.press('keyUp'), 'map')
        self.assertEqual(a.press('keyDown'), 'activate')

    def test_keyboard_is_untouched(self):
        self.assertEqual(A('header', True, device_pad=False).press('keyDown', 13), 'activate')
        self.assertEqual(A('quest', True).press('keyDown', 69), 'activate')


class Source(unittest.TestCase):
    def test_handle_input_lines(self):
        h = func('handleInput')
        self.assertIn('padA = this.pad && nav == "enter-gamepad_A" && code != 69;', h)
        self.assertIn('aToMap = reticlePin();', h)
        self.assertIn('aDeclines = padA && aToMap;', h)
        self.assertIn('if(padA && details.value != "keyDown" && details.value != "keyHold") { aToMap = false; }', h)
        self.assertIn('declines = stickDeclines(details,arrow,stick) || aDeclines;', h)
        self.assertIn('if(declines && !aDeclines) { logDecline(details,arrow); }', h)
        self.assertIn('if(padA && selected >= 0 && selected < rows.length && rows[selected].type == ROW_CAT) {', h)
        self.assertIn('padLog("A on a section header does nothing, Y folds")', h)
        self.assertIn('padLog("A acts on the highlighted row " + selected)', h)
        self.assertEqual(h.count('return false;'), 1)
        self.assertLess(h.index('aDeclines = padA && aToMap;'), h.index('if(code == 88 || nav == "gamepad_R3" || declines)'))

    def test_reads_the_flag_safely(self):
        self.assertIn('return map != null && map.pinAtReticle === true;', func('reticlePin'))

    def test_the_keyboard_and_mouse_paths_are_unchanged(self):
        self.assertIn('else if(code == 13 || code == 69 || nav == "enter-gamepad_A")', func('handleInput'))
        self.assertIn('case ROW_CAT:\n               fold(row);', func('activate'))


class Reticle(unittest.TestCase):
    def test_center_moves_the_crosshair_with_the_roam_maths(self):
        r = '\n'.join(e['replace'] for e in HUB)
        self.assertIn('private function cmfMovieReticle(x:Number,y:Number,z:Number,seconds:Number) : void', r)
        self.assertIn('if(!this.cmfRoamOn || MapMenu.IsUsingMouse() || !(z > 0) || isNaN(x) || isNaN(y)) { return; }', r)
        self.assertIn('ex = Math.max(this.cmfRoamLeft,Math.min(this.cmfRoamRight,z * (cont.GetRestrictedX(x) - x)));', r)
        self.assertIn('ey = Math.max(this.cmfRoamTop,Math.min(this.cmfRoamBottom,z * (cont.GetRestrictedY(y) - y)));', r)
        self.assertIn('this.cmfRoamSlide(ex,ey,seconds > 0,seconds,true);', r)
        self.assertIn('this.cmfNote("roam center crosshair=" + Math.round(ex) + "," + Math.round(ey) + " movie");', r)

    def test_both_center_branches_call_it_and_the_ends_come_first(self):
        s = HUB[92]['replace']
        i = s.index('public function cmfMovieCenter(')
        body = s[i:s.index('private function cmfMovieCenterFrame')]
        self.assertLess(body.index('endX = -this.WorldXToMapX(x);'), body.index('if(seconds == 0)'))
        self.assertEqual(body.count('this.cmfMovieReticle('), 2)
        self.assertIn('this.cmfMovieReticle(endX,endY,zoom,0);', body)
        self.assertIn('this.cmfMovieReticle(endX,endY,zoom,seconds);', body)

    @staticmethod
    def model(roam_on, mouse, restricted, target, z, box):
        if not roam_on or mouse:
            return None
        lo, hi = box
        return max(lo, min(hi, z * (restricted - target)))

    def test_model(self):
        self.assertIsNone(self.model(True, True, 10, 0, 1, (-100, 100)))
        self.assertEqual(self.model(True, False, 0, 0, 1, (-100, 100)), 0)        # no limit: reticle at the pin's own centred spot
        self.assertEqual(self.model(True, False, 30, 0, 2, (-100, 100)), 60)      # limit: the reticle takes the rest
        self.assertEqual(self.model(True, False, 300, 0, 1, (-100, 100)), 100)    # held to the box


class Panel(unittest.TestCase):
    def test_the_flag_is_the_reticles_pin_only(self):
        t = '\n'.join(e['replace'] for e in HUB)
        self.assertIn('private var _cmfMovieSelIdx:int = -1;', t)
        self.assertIn('if(key == "pinAtReticle") { return this._selectedMapPinIndex > -1 && this._selectedMapPinIndex < this._staticMapPins.length && this._selectedMapPinIndex != this._cmfMovieSelIdx; }', t)
        self.assertIn('this.SelectPin(i);\n               this._cmfMovieSelIdx = i;', t)
        self.assertIn('this._cmfMovieSelIdx = -1;\n         this.cmfCancelHold();', HUB[119]['replace'])

    def test_the_movie_facade_has_the_getter(self):
        self.assertIn('public function get pinAtReticle() : * { return this.readValue("pinAtReticle"); }', MM[306]['replace'])


if __name__ == '__main__':
    unittest.main()
