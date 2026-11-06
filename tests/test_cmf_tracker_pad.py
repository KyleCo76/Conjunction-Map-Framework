"""The info box avoids the tracker's frame, not only its text box (1.12.0 Start 1 finding B)."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
MENU = EDITS['red/game/witcher3/menus/worldmap/MapMenu.as']


def edit_with(text):
    found = [i for i, e in enumerate(MENU) if text in e['replace']]
    return found


class TrackerPad(unittest.TestCase):
    def test_two_appended_edits_after_the_stretch_code(self):
        push = [i for i, e in enumerate(MENU) if e['find'] == '               avoid.push(found[n].box);\n']
        fn = [i for i, e in enumerate(MENU) if e['find'] == '      protected function cmfClearTooltip() : void\n' and 'cmfAvoidBox' in e['replace']]
        self.assertEqual(len(push), 1)
        self.assertEqual(len(fn), 1)
        self.assertGreater(push[0], max(edit_with('avoid.push(found[n].box);')[:-1] or [0]))
        for i in push + fn:
            self.assertEqual(MENU[i]['count'], 1)

    def test_finds_come_from_the_latest_definition_only(self):
        for f in ('               avoid.push(found[n].box);\n', '      protected function cmfClearTooltip() : void\n'):
            last = [i for i, e in enumerate(MENU) if f in e['replace'] and f != e['find']][-1]
            later = [i for i, e in enumerate(MENU) if i > last and (f in e['replace'] or f in e['find']) and e['find'] != f]
            self.assertEqual(later, [], f[:40])

    def test_only_the_tracker_gets_30_units_more_height(self):
        e = [x for x in MENU if 'function cmfAvoidBox' in x['replace']][0]['replace']
        self.assertIn('if(part != "tracker" || !box) { return box; }', e)
        self.assertIn('box.height + 30', e)
        use = [x for x in MENU if x['find'] == '               avoid.push(found[n].box);\n'][0]['replace']
        self.assertIn('avoid.push(this.cmfAvoidBox(parts[k],found[n].box));', use)

    def test_quest_list_rects_are_untouched(self):
        # the movie rectangles still come straight from cmfMovieRects (hard blocks), not through the pad
        self.assertEqual(sum(1 for e in MENU if 'cmfAvoidBox(' in e['replace'] and 'hard = this.cmfMovieRects();' in e['replace']), 0)


if __name__ == '__main__':
    unittest.main()
