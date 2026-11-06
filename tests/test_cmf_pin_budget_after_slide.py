"""pinBudgetAfterSlideMs: an additive `opening` key, the pin placement budget for the ticks after the menu slide.

The panel VM tests run the compiled bundle, which only the release session can rebuild, so the loop is pinned by
edit-text checks plus a small model of its budget rule; the game launch confirms it.
"""
from pathlib import Path
import json
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
sys.path.insert(0, str(ROOT/'tests'))
import cmf_pack
from test_cmf_smooth_map import CORE, EDITS, motion_ranges
from rev13_legacy_source import theme_environment

HUB = 'red/game/witcher3/menus/worldmap/HubMap.as'
KEY = 'pinBudgetAfterSlideMs'
AFTER = 'MapMenu.cmfNum("opening","pinBudgetAfterSlideMs",0)'


def loop_budget(param1, anim_completed, after_slide, pin_budget):
    """Mirrors the three-line rule in HubMap's placement loop (the edit text is pinned below)."""
    budget = 0 if param1 else pin_budget
    if not param1 and anim_completed and after_slide > 0:
        budget = after_slide
    return budget


class EditTextTests(unittest.TestCase):
    def setUp(self):
        edits = json.loads(EDITS.read_text(encoding='utf-8'))
        self.hub = ''.join(e['replace'] for e in edits['classes'][HUB])

    def test_loop_reads_the_key_only_after_the_slide(self):
        rule = ('var cmfBudget:Number = param1 ? 0 : MapMenu.cmfNum("opening","pinBudgetMs",0);\n'
                '         if(!param1 && this._menuAnimCompleted && ' + AFTER + ' > 0)\n'
                '         {\n'
                '            cmfBudget = ' + AFTER + ';\n'
                '         }\n')
        self.assertEqual(self.hub.count(rule), 1)
        self.assertEqual(self.hub.count('pinBudgetAfterSlideMs'), 3)  # the loop reads it twice, cmfPinBatch once

    def test_pin_batch_checks_both_keys(self):
        self.assertIn('return MapMenu.cmfNum("opening","pinBudgetMs",0) > 0 || ' + AFTER + ' > 0 ? 100000 : 30000;',
                      self.hub)


class BudgetModelTests(unittest.TestCase):
    def test_unset_or_zero_is_todays_budget_everywhere(self):
        for param1 in (True, False):
            for done in (True, False):
                for pin_budget in (0, 8):
                    today = 0 if param1 else pin_budget
                    self.assertEqual(loop_budget(param1, done, 0, pin_budget), today)

    def test_set_applies_only_after_the_slide_and_never_for_param1(self):
        for pin_budget in (0, 8):
            self.assertEqual(loop_budget(False, True, 25, pin_budget), 25)
            self.assertEqual(loop_budget(False, False, 25, pin_budget), pin_budget)
            for done in (True, False):
                self.assertEqual(loop_budget(True, done, 25, pin_budget), 0)


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_range_zero_to_1000(self):
        table, default = motion_ranges(self.core)
        low, high = table.get(KEY, default)
        self.assertEqual((low, high), (0, 1000))
        accepted = [n for n in (-1, 0, 1000, 1001) if low <= n <= high]
        self.assertEqual(accepted, [0, 1000])

    def test_key_is_listed_and_packed(self):
        env = theme_environment(self.core)
        opening = env['CMFThemeOpeningKeys']().split(',')
        self.assertEqual(opening[opening.index('pinBudgetMs') + 1], KEY)
        self.assertIn(KEY, cmf_pack.THEME_PART_KEYS['opening'])

    def test_core_version_is_unchanged(self):
        self.assertIn('function CMFGetVersion() : int { return 19; }', self.core)


if __name__ == '__main__':
    unittest.main()
