"""API version 7: a drawing shown only on a tall part (minPartHeight) and a tall info box moved clear (clear* keys).

Static checks of cmfCore.ws, the panel edits and the pack tool; the in-game check rides the Ink and Iron 0.8.10
info-box launch (probes/2026-10-21-cmf-ink-and-iron-0-8-10/README.md).
"""
from pathlib import Path
import json
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

CLEAR = ('clearMinHeight', 'clearView', 'clearSide', 'clearCursor', 'clearLeft', 'clearTop', 'clearRight',
         'clearBottom')


def menu():
    edits = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']
    return ''.join(e['replace'] for e in edits)


def body(source, head):
    start = source.index(head)
    i = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += {'{': 1, '}': -1}.get(source[i], 0)
        i += 1
    return source[start:i]


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_version_7(self):
        self.assertIn('function CMFGetVersion() : int { return 9; }', self.core)

    def test_tooltip_takes_the_clear_keys(self):
        keys = body(self.core, 'function CMFThemePartKeys(')
        tooltip = keys[keys.index("case 'tooltip':"):keys.index("case 'preview':")]
        for key in CLEAR:
            self.assertIn(key, tooltip)
            self.assertIn(key, cmf_pack.THEME_PART_KEYS['tooltip'])

    def test_box_kinds_take_min_part_height(self):
        self.assertIn('CMFThemeHoverKeys() + ",minPartHeight";', body(self.core, 'function CMFThemeShapeKeys('))
        for kind in ('rect', 'ring', 'ellipse', 'polygon', 'band', 'text'):
            self.assertIn('minPartHeight', cmf_pack.THEME_KIND_KEYS[kind])
        for kind in ('line', 'movie'):
            self.assertNotIn('minPartHeight', cmf_pack.THEME_KIND_KEYS[kind])

    def test_values(self):
        text = body(self.core, 'function CMFThemeTextKey(')
        self.assertIn('listenFields,clearView,clearSide"', text)
        values = body(self.core, 'function CMFThemeValueOk(')
        self.assertIn("case 'view':\n\t\t\tcase 'clearView':\n\t\t\t\treturn CMFThemeWordsOk(text, \"region,interior,world\");",
                      values)
        self.assertIn("case 'clearSide':\n\t\t\t\treturn text == \"left\" || text == \"right\";", values)
        self.assertIn('if (k == "minPartHeight" || k == "clearMinHeight" || k == "clearCursor")\n\t{\n'
                      '\t\treturn number >= 0 && number <= 4000;', values)


class PanelTests(unittest.TestCase):
    def setUp(self):
        self.menu = menu()

    def test_text_keys_match_the_core(self):
        self.assertIn('listen,listenFields,clearView,clearSide,";', self.menu)

    def test_min_part_height_hides_a_drawing_on_a_shorter_part(self):
        shows = body(self.menu, 'public static function cmfShows(')
        self.assertIn('if(param1.keys.minPartHeight is Number && Number(param1.keys.minPartHeight) > 0 && '
                      '!(param2.partHeight is Number && Number(param2.partHeight) >= Number(param1.keys.minPartHeight)))',
                      shows)
        # The part's box height goes into the context wherever a part's drawings are drawn or stacked.
        self.assertIn('param4.partHeight = param3.height;', body(self.menu, 'public static function cmfDrawList('))
        self.assertIn('param4.partHeight = param3.height;', body(self.menu, 'public static function cmfStackBox('))

    def test_clear_placement(self):
        clear = body(self.menu, 'protected function cmfClearTooltip(')
        for key in CLEAR:
            self.assertIn('"%s"' % key, clear)
        self.assertIn('box = this.cmfTextBox(this.tooltipInstance,0);', clear)
        self.assertIn('if(box.height < minH)', clear)
        self.assertIn('["legend","tracker","preview","worldButton","title"]', clear)
        self.assertIn('== "left" ? ["left","right","top","bottom"] : ["right","left","top","bottom"]', clear)
        self.assertIn('score = 10 * MapMenu.cmfOverlap(r,cursor);', clear)
        self.assertIn('setChildIndex(this.tooltipInstance,top);', clear)
        # Asked for when the game shows the box, finished on a later frame if the box cannot be measured yet.
        self.assertIn('this.cmfPlaceTooltip();\n            this._cmfClearPending = true;\n'
                      '            this.cmfClearTooltip();\n', self.menu)
        frame = body(self.menu, 'protected function cmfThemeFrame(')
        self.assertLess(frame.index('this.cmfClearTooltip();'), frame.index('this.cmfPlaceLayers();'))

    def test_centred_text_is_measured_by_its_lines(self):
        # A centred description (Ink and Iron's region-map info box) is boxed from its leftmost to its rightmost
        # shown line, not trimmed from the field's left edge.
        box = body(self.menu, 'protected function cmfTextBox(')
        self.assertIn('align = t.getTextFormat().align;', box)
        self.assertIn('else if(align != TextFormatAlign.LEFT && t.width > 0 && t.scaleX != 0)', box)
        self.assertIn('m = t.getLineMetrics(n);', box)
        self.assertIn('if(m && m.width > 0)', box)
        self.assertIn('r.x += (lo - 4) * sx;', box)
        self.assertIn('import flash.text.TextLineMetrics;', self.menu)

    def test_back_to_the_games_place(self):
        back = body(self.menu, 'protected function cmfTooltipBack(')
        self.assertIn('this.tooltipInstance.x = this._cmfTooltipX;', back)
        self.assertIn('this.cmfPutAbove(this.tooltipInstance,this._cmfTipBelow);', back)
        # Map Quest Insight's scrolling box (cmfDescMaxH) places itself; the clear placement leaves it be.
        self.assertIn('if(this.cmfDescMaxH > 0)\n         {\n            return;', back)
        below = body(self.menu, 'protected function cmfTipBelow(')
        self.assertIn('for(key in this._cmfLayers)', below)


if __name__ == '__main__':
    unittest.main()
