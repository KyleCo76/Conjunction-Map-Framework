"""The pin info box keeps off the bottom hints strip (panel part): the strip joins the parts the box avoids, in the clearing place
(cmfClearTooltip) and in the tall place (cmfTallSpan). Text checks only; nothing here ran in the game.
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MM = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']


class Hints(unittest.TestCase):
    def test_both_part_lists_hold_the_hints_strip(self):
        self.assertIn('var parts:Array = ["legend","tracker","preview","worldButton","title","hints"];', MM[393]['replace'])
        self.assertIn('var parts:Array = ["legend","tracker","preview","worldButton","worldHint","title","hints"];', MM[15]['replace'])

    def test_finds_are_unchanged(self):
        self.assertEqual(MM[393]['find'], '         var parts:Array = ["legend","tracker","preview","worldButton","title"];\n')
        self.assertEqual(MM[393]['count'], 1)

    def test_the_hints_part_is_measured_only_while_visible(self):
        text = '\n'.join(e['replace'] for e in MM)
        i = text.index('case "hints":')
        self.assertIn('if(Boolean(this.cmfHintCopy) && this.cmfHintCopy.visible)', text[i:i + 200])
        self.assertIn('r = this.cmfKeyBox(this.cmfHintCopy.buttonsContainer,0);', text[i:i + 300])

    def test_the_rect_is_noted_once_per_distinct_rectangle(self):
        s = MM[390]['replace']
        self.assertIn('protected function cmfNoteHintsRect(best:Rectangle) : void', s)
        self.assertIn('if(text == this._cmfHintsNoted) { return; }', s)
        self.assertIn('"info box hints strip rect=" + text + " covered="', s)
        self.assertIn('this.cmfNoteHintsRect(best);', MM[389]['replace'])
        self.assertLess(MM[389]['replace'].index('this.cmfNoteMovieAvoid(best);'), MM[389]['replace'].index('this.cmfNoteHintsRect(best);'))

    def test_model_the_box_moves_up_when_the_strip_is_in_its_way(self):
        def clear(box_h, strip_top, limit_bottom, free_top=120):
            bottom = limit_bottom
            if bottom > strip_top - 8:        # the strip, grown by 8, blocks the lower candidate
                bottom = strip_top - 8
            top = bottom - box_h
            return top if top >= free_top else None
        self.assertEqual(clear(480, 1055, 1124), 567)     # Kyle's box: 480 tall, strip at 1055
        self.assertIsNone(clear(980, 1055, 1124))         # too tall for the space: today's place stands


if __name__ == '__main__':
    unittest.main()
