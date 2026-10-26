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
        self.assertIn('function CMFGetVersion() : int { return 13; }', self.core)

    def test_tooltip_takes_the_clear_keys(self):
        keys = body(self.core, 'function CMFThemePartKeys(')
        tooltip = keys[keys.index("case 'tooltip':"):keys.index("case 'preview':")]
        for key in CLEAR:
            self.assertIn(key, tooltip)
            self.assertIn(key, cmf_pack.THEME_PART_KEYS['tooltip'])

    def test_box_kinds_take_min_part_height(self):
        from rev13_legacy_source import theme_environment
        env = theme_environment(self.core)
        self.assertIn('CMFThemeHoverKeys() + ",minPartHeight,', body(self.core, 'function CMFThemeShapeKeys('))
        for kind in ('rect', 'ring', 'ellipse', 'polygon', 'band', 'text', 'movie'):
            self.assertIn('minPartHeight', cmf_pack.THEME_KIND_KEYS[kind])
            self.assertIn('minPartHeight', env['CMFThemeShapeKeys'](kind).split(','))
        for kind in ('line',):
            self.assertNotIn('minPartHeight', cmf_pack.THEME_KIND_KEYS[kind])
            self.assertNotIn('minPartHeight', env['CMFThemeShapeKeys'](kind).split(','))

    def test_values(self):
        text = body(self.core, 'function CMFThemeTextKey(')
        self.assertIn('listenFields,clearView,clearSide,', text)
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
        self.assertIn('listen,listenFields,clearView,clearSide,wideAnchor,";', self.menu)

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
        # Version 12: a box the tall* keys placed (TallPlaceTests) stays; the clear placement leaves it be.
        below = body(self.menu, 'protected function cmfTipBelow(')
        self.assertIn('for(key in this._cmfLayers)', below)


class TallPlaceTests(unittest.TestCase):
    """API version 12: the info box height only makes the text scroll; a tall box moves aside only through the
    tooltip keys tallMinHeight and the tall* places (Kyle 2026-10-25 05:33Z, "Separate position from height")."""

    def setUp(self):
        edits = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']
        self.place = next(e['replace'] for e in edits if '"tallMinHeight"' in e['replace'])
        self.back = next(e['replace'] for e in edits if 'if(this._cmfTallPlaced)' in e['replace'])
        self.core = CORE.read_text(encoding='ascii')

    def test_height_alone_keeps_the_games_place(self):
        place = self.place
        self.assertIn('if(this.cmfDescMaxH <= 0 && MapMenu.cmfNum("tooltip","tallMinHeight",0) <= 0)', place)
        self.assertIn('if(MapMenu.cmfNum("tooltip","tallMinHeight",0) <= 0 || _loc1_ <= '
                      'MapMenu.cmfNum("tooltip","tallMinHeight",0))', place)
        game = place[place.index('if(MapMenu.cmfNum("tooltip","tallMinHeight",0) <= 0 ||'):place.index('this._cmfTallPlaced = true;')]
        self.assertIn('this.tooltipInstance.x = this._cmfTooltipX;', game)
        self.assertIn('this.tooltipInstance.y = this.TOOLTIP_POS - _loc1_;', game)
        self.assertNotIn('mcHubMapPinPanel', game)
        # The scroll still follows the height alone.
        self.assertLess(place.index('if(this.cmfDescMaxH > 0)'), place.index('this.cmfScrollTooltip(0,0);'))

    def test_tall_places_come_from_the_keys(self):
        place = self.place
        tall = place[place.index('this._cmfTallPlaced = true;'):]
        self.assertIn('if(MapMenu.cmfNum("tooltip","tallUnderLegend",0) == 1 && ', tall)
        for key, default in (('tallAltX', 112), ('tallAltTop', 206), ('tallAltBottom', 1006), ('tallX', 1300),
                             ('tallTop', 130), ('tallBottom', 906)):
            self.assertIn('MapMenu.cmfNum("tooltip","%s",%d)' % (key, default), tall)
        self.assertIn('if(this._cmfTallPlaced)\n         {\n            return;', self.back)

    def test_core_files_the_keys_under_the_dodge_piece(self):
        keys = body(self.core, 'function CMFThemePartKeys(')
        tooltip = keys[keys.index("case 'tooltip':"):keys.index("case 'preview':")]
        choice = body(self.core, 'public function PartKeyChoice(')
        for key in ('tallMinHeight', 'tallX', 'tallTop', 'tallBottom', 'tallAltX', 'tallAltTop', 'tallAltBottom',
                    'tallUnderLegend', 'tallClear'):
            self.assertIn(key, tooltip)
            self.assertIn(key, choice)
            self.assertIn(key, cmf_pack.THEME_PART_KEYS['tooltip'])
            self.assertEqual(cmf_pack.THEME_KEY_ROWS[('tooltip', key)], 'Map behaviour > Info box moves out of the way')
        values = body(self.core, 'function CMFThemeValueOk(')
        self.assertIn('if (k == "tallUnderLegend" || k == "tallClear")\n\t{\n\t\treturn number == 0 || number == 1;', values)

    def test_tall_clear_keeps_the_place_off_the_panels(self):
        # Launch 2026-10-25 line 3: Map Quest Insight's places cover CMF's legend and overview (Kyle's pick "Both").
        place = self.place
        tall = place[place.index('this._cmfTallPlaced = true;'):]
        self.assertIn('if(MapMenu.cmfNum("tooltip","tallUnderLegend",0) == 1 && this.getChildIndex(this.tooltipInstance) > '
                      'this.getChildIndex(this.mcHubMapPinPanel))', tall)
        self.assertLess(tall.index('_loc5_ = this.cmfTallSpan(_loc2_,_loc3_,_loc4_);'), tall.index('if(_loc1_ > _loc4_ - _loc3_)'))
        span = tall[tall.index('protected function cmfTallSpan('):]
        self.assertIn('var parts:Array = ["legend","tracker","preview","worldButton","worldHint","title"];', span)
        self.assertIn('bottom = Math.min(bottom,r.top - 12);', span)
        self.assertIn('top = Math.max(top,r.bottom + 12);', span)
        self.assertIn('if(bottom - top < 120)', span)


if __name__ == '__main__':
    unittest.main()
