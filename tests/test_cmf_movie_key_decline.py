"""CMF API 17: a focused screen movie can decline a key (handleInput returns false); the MQI Quest List declines the
quest info box's Show more / Show less keys (adapter 2.5.2). Source and rule-model tests; the launch runs it in game."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text())['classes']
MAPMENU = ''.join(e['replace'] for e in EDITS['red/game/witcher3/menus/worldmap/MapMenu.as'])
CORE = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='ascii')
AS = (ROOT / 'source/adapters/map-quest-insight/movie-src/MqiAdapterQuestList.as').read_text()


def input_body():
    start = MAPMENU.index('public function cmfMovieInput(event:InputEvent) : Boolean')
    return MAPMENU[start:MAPMENU.index('private function cmfFailScreenMovie', start)]


def model(returned, marker_before, key_down, one_hold=False):
    """The panel's rule: (handled, marker kept) for one key event given what the movie returned."""
    added = (not marker_before) and key_down
    markers = marker_before or added
    if returned is False:
        if added:
            markers = False
        return False, markers
    return True, markers


class PanelDecline(unittest.TestCase):
    def test_only_an_exact_false_declines(self):
        body = input_body()
        self.assertIn('declined = fn(event) === false;', body)
        self.assertIn('var declined:Boolean = false;', body)

    def test_a_declined_key_is_not_handled_and_not_stopped(self):
        body = input_body()
        tail = body[body.index('if(declined)'):]
        declined = tail[:tail.index('event.handled = true;')]
        self.assertIn('return false;', declined)
        self.assertNotIn('stopImmediatePropagation', declined)
        self.assertNotIn('handled = true', declined)
        # The usual path after the movie still handles and stops the event.
        usual = tail[tail.index('event.handled = true;'):]
        self.assertIn('event.stopImmediatePropagation();', usual)
        self.assertIn('return true;', usual)

    def test_the_marker_added_for_this_press_is_dropped(self):
        body = input_body()
        self.assertIn('var added:Boolean = false;', body)
        self.assertIn('++this._cmfMovieKeyCount;\n               added = true;', body)
        drop = body[body.index('if(declined)'):]
        drop = drop[:drop.index('return false;')]
        self.assertIn('if(added && this._cmfMovieKeys && key in this._cmfMovieKeys)', drop)
        self.assertIn('delete this._cmfMovieKeys[key];', drop)
        self.assertIn('if(--this._cmfMovieKeyCount == 0) { this._cmfMovieKeys = null; }', drop)

    def test_the_call_to_the_movie_is_unchanged(self):
        body = input_body()
        self.assertIn('fn = state.loader.content["handleInput"] as Function;', body)
        self.assertIn('this.cmfFailScreenMovie(state,"input " + error.message);', body)

    def test_rule_model(self):
        # A movie that returns nothing: handled, marker kept (unchanged).
        self.assertEqual(model(None, False, True), (True, True))
        self.assertEqual(model(True, False, True), (True, True))
        # A declined press: not handled, no marker, so the release reaches the movie again and may decline too.
        self.assertEqual(model(False, False, True), (False, False))
        self.assertEqual(model(False, False, False), (False, False))


class CoreAbility(unittest.TestCase):
    def test_ability_and_version(self):
        self.assertIn("if (part == 'screen' && key == 'keyDecline') { return true; }", CORE)
        self.assertIn("if (part == 'screen' && key == 'button') { return true; }", CORE)
        self.assertIn('function CMFGetVersion() : int { return 19; }', CORE)

    def test_documented(self):
        guide = (ROOT / 'docs/authors/own-screen-movie.md').read_text()
        self.assertIn("CMFHasAbility('screen', 'keyDecline')", guide)
        notes = (ROOT / 'tools/cmf_author_docs.py').read_text()
        self.assertIn("keyDecline", notes)


class QuestListDeclines(unittest.TestCase):
    def test_declines_the_fold_keys_press_and_release(self):
        m = re.search(r'public function handleInput\(event:Object\) : \*\n.*?\n      \}\n', AS, re.S)
        body = m.group(0)
        self.assertIn('if(code == 88 || nav == "gamepad_R3" || declines)', body)
        # After learnDevice and the opened/focused test, before the key-up branch and every other key.
        decline = body.index('return false;')
        self.assertGreater(decline, body.index('if(!opened || !focused) { return; }'))
        self.assertLess(decline, body.index('details.value == "keyUp"'))
        self.assertNotIn('return false;', body[decline + 20:])
        # No key of the list uses X or R3 itself.
        keys = body[body.index('if(code == 70'):]
        self.assertNotIn('code == 88', keys)
        self.assertNotIn('gamepad_R3', keys)


if __name__ == '__main__':
    unittest.main()
