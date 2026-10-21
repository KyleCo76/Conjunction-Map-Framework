"""Spreading stacked pins: the spread theme part, the SpreadRank pin property (22) and the panel code that acts on them.

Design: Map Quest Insight 1.6.1's stacked-marker spreading, research/2026-10-20-map-remastered-wild-monster-hunt-
and-version-recheck.md section 7.3 in the project's shared folder (values and behaviour only; no Map Quest Insight
code). Static checks and a model of the panel's row layout and pick; nothing here compiled or ran in game.
"""
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
GUIDE = ROOT/'docs/authors/icon-pack-guide.md'
WORLDMAP = 'red/game/witcher3/menus/worldmap/'
SPREAD_KEYS = ['on', 'anyPin', 'enterRadius', 'stackDistance', 'gap', 'maxPins', 'openMs', 'closeMs', 'lockRadius',
               'keepRadius']
# The panel's defaults are the research values (section 7.3); spreading itself is off until a theme sets on.
DEFAULTS = {'on': 0, 'anyPin': 0, 'enterRadius': 20, 'stackDistance': 24, 'gap': 48, 'maxPins': 8, 'openMs': 150,
            'closeMs': 120, 'lockRadius': 24, 'keepRadius': 48}
RANGES = {'on': 'switch', 'anyPin': 'switch', 'maxPins': (2, 16), 'openMs': (0, 2000), 'closeMs': (0, 2000),
          'gap': (8, 400), 'enterRadius': (0, 400), 'stackDistance': (0, 400), 'lockRadius': (0, 400),
          'keepRadius': (0, 400)}


def body(text, signature):
    start = text.index(signature)
    end = text.index('\n}', start) if text[start - 1] == '\n' else text.index('\n\t}', start)
    return text[start:end]


def as_body(text, signature):
    """One ActionScript method of the edited panel, from its signature to its closing brace."""
    start = text.index(signature)
    return text[start:text.index('\n      }\n', start)]


def joined(edits, path):
    return ''.join(e['replace'] for e in edits['classes'][path])


def spread_ranges(core):
    """CMFThemeSpreadValueOk as a table: key -> 'switch' or (lowest, highest), plus its default range."""
    code = body(core, 'function CMFThemeSpreadValueOk(key : name, number : float) : bool')
    table, pending = {}, []
    for line in code.splitlines():
        line = line.strip()
        case = re.match(r"case '(\w+)':", line)
        if case:
            pending.append(case.group(1))
        elif line.startswith('return number') and pending:
            if line == 'return number == 0 || number == 1;':
                value = 'switch'
            else:
                value = tuple(int(n) for n in re.match(r'return number >= (\d+) && number <= (\d+);', line).groups())
            table.update(dict.fromkeys(pending, value))
            pending = []
    default = re.search(r'\}\n\treturn number >= (\d+) && number <= (\d+);', code)
    return table, (int(default.group(1)), int(default.group(2)))


def row(bases, ranks, cursor, gap=48, max_pins=8, reach=24, anchor=0):
    """Mirrors HubMap.cmfSpreadFind, cmfSpreadStackOf and cmfSpreadLayout for one stack: the members (every base
    chained within reach of another, starting from the anchor; past max_pins the ones nearest the stack's middle),
    their offsets once open, and the pick (highest rank, then nearest the cursor)."""
    members = [anchor]
    rest = [i for i in range(len(bases)) if i != anchor]
    j = 0
    while j < len(members):
        for i in list(rest):
            if (bases[i][0] - bases[members[j]][0]) ** 2 + (bases[i][1] - bases[members[j]][1]) ** 2 <= reach * reach:
                members.append(i)
                rest.remove(i)
        j += 1
    mx = sum(bases[i][0] for i in members) / len(members)
    my = sum(bases[i][1] for i in members) / len(members)
    near = sorted(members, key=lambda i: (bases[i][0] - mx) ** 2 + (bases[i][1] - my) ** 2)
    near = sorted(near[:max_pins], key=lambda i: bases[i][0])
    cx = sum(bases[i][0] for i in near) / len(near)
    cy = sum(bases[i][1] for i in near) / len(near)
    half = (len(near) - 1) * gap / 2
    offsets = {i: (cx - half + k * gap - bases[i][0], cy - bases[i][1]) for k, i in enumerate(near)}
    pick = None
    for i in near:
        d = (bases[i][0] - cursor[0]) ** 2 + (bases[i][1] - cursor[1]) ** 2
        if pick is None or ranks[i] > ranks[pick[0]] or ranks[i] == ranks[pick[0]] and d < pick[1]:
            pick = (i, d)
    return near, offsets, pick[0]


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_spread_rank_is_property_22(self):
        self.assertIn('function CMFPropertySpreadRank() : int { return 22; }', self.core)
        self.assertEqual(cmf_pack.PROPERTY_IDS['CMFPropertySpreadRank'], 22)
        self.assertIn(22, cmf_pack.KNOWN_PROPERTIES)
        self.assertIn('CMFPropertySpreadRank', cmf_pack.VERSION6)
        # Accepted by CMFRegister, CMFRegisterForTag and CMFStylePin like ids 10-17, with no text.
        self.assertIn('propertyId == CMFPropertySpreadRank() || CMFIsClickProperty(propertyId);',
                      body(self.core, 'function CMFHasProperty(propertyId : int) : bool'))
        self.assertIn('propertyId != CMFPropertySpreadRank())',
                      body(self.core, 'function CMFRegisterForTag('))
        self.assertIn('propertyId == CMFPropertySpreadRank();', body(self.core, 'function CMFPropertyTextFree('))
        self.assertIn('case 22:\n\t\t\treturn "cmfSpreadRankBy";', body(self.core, 'function CMFOwnerField('))
        self.assertIn('WriteSlot(dataObject, CMFPropertySpreadRank(), pinKey, legendKey, pinTag, maxLevel);', self.core)
        self.assertIn('case 22:\n\t\t\t\tdataObject.SetMemberFlashInt("cmfSpreadRank", number);', self.core)
        # The same range in the registry, the per-pin call and the pack tool.
        self.assertIn('(incoming.propertyId == CMFPropertySpreadRank() && (incoming.number < 0 || incoming.number > '
                      '1000))', self.core)
        self.assertIn('(propertyId == CMFPropertySpreadRank() && (number < 0 || number > 1000))', self.core)
        self.assertEqual(cmf_pack.n4_issues(22, '', '1000'), [])
        self.assertEqual(len(cmf_pack.n4_issues(22, '', '1001')), 1)

    def test_spread_part_and_keys(self):
        self.assertIn(',opening,spread"', body(self.core, 'function CMFThemeParts() : string'))
        self.assertIn('return "%s";' % ','.join(SPREAD_KEYS), body(self.core, 'function CMFThemeSpreadKeys() : string'))
        self.assertIn("case 'spread':\n\t\t\treturn CMFThemeSpreadKeys();", self.core)
        self.assertEqual(list(cmf_pack.THEME_PART_KEYS['spread']), SPREAD_KEYS)
        # A behaviour part: won key by key, "unset" withdraws a key, never a drawing anchor.
        self.assertIn("part == 'opening' || part == 'spread';", body(self.core, 'private function ThemeStyleOwner('))
        self.assertIn('",navigation,opening,spread", NameToString(anchor)', self.core)
        self.assertIn("if (part == 'spread')\n\t{\n\t\treturn CMFThemeSpreadValueOk(key, number);\n\t}",
                      body(self.core, 'function CMFThemeValueOk(part : name, key : name, text : string, number : '
                                      'float) : bool'))

    def test_ranges(self):
        table, default = spread_ranges(self.core)
        self.assertEqual(default, (0, 400))
        for key, expected in RANGES.items():
            self.assertEqual(table.get(key, default), expected, key)
        # The research values sit inside the ranges.
        for key, value in DEFAULTS.items():
            expected = RANGES[key]
            self.assertTrue(value in (0, 1) if expected == 'switch' else expected[0] <= value <= expected[1], key)

    def test_version_stays_six(self):
        self.assertIn('function CMFGetVersion() : int { return 6; }', self.core)


class PanelTests(unittest.TestCase):
    def setUp(self):
        self.edits = json.loads(EDITS.read_text(encoding='utf-8'))
        self.hub = joined(self.edits, WORLDMAP + 'HubMap.as')
        self.pin = joined(self.edits, WORLDMAP + 'StaticMapPinDescribed.as')
        self.data = joined(self.edits, 'red/game/witcher3/data/StaticMapPinData.as')

    def test_off_unless_a_theme_sets_on(self):
        for key, value in DEFAULTS.items():
            self.assertRegex(self.hub, r'MapMenu\.cmfNum\("spread","%s",%s\)' % (key, value), key)
        find = as_body(self.hub, '      private function cmfSpreadFind() : void')
        self.assertIn('if(!this.cmfSpreadOn || this._staticMapPins.length == 0)\n         {\n            return;', find)
        self.assertIn('this.cmfApplySpread();', self.hub)
        self.assertIn('if(!this.cmfSpreadOn)\n         {\n            this.cmfSpreadReset();', self.hub)

    def test_pins_keep_their_place(self):
        # The offset rides on top of the game's position; the real position is never changed.
        self.assertIn('x = param1 + this.cmfFanX;\n         y = param2 + this.cmfFanY;', self.pin)
        self.assertIn('x = this.cmfBaseX + this.cmfFanX;', self.pin)
        self.assertIn('public var cmfSpreadRank:int = 0;', self.data)
        self.assertIn('public var cmfSpreadRankBy:String = "";', self.data)
        self.assertNotIn('SetWorldPosition', as_body(self.hub, '      private function cmfSpreadFind() : void'))
        # The selected pin's copy follows its pin.
        self.assertIn('this._selectedPinAvatar.cmfSetFan(this._staticMapPins[this._selectedMapPinIndex].cmfFanX,', self.hub)

    def test_hooks_reset_and_timing(self):
        edits = self.edits['classes'][WORLDMAP + 'HubMap.as']
        replaces = [e['replace'] for e in edits]
        self.assertTrue(any('this.cmfSpreadTick();\n         if(this.cmfTimed)' in r for r in replaces))
        self.assertTrue(any('this.cmfSpreadFind();\n         this.UpdatePositionOfPinAvatar(_loc4_);' in r for r in replaces))
        self.assertTrue(any('protected function ClearPins() : void\n      {\n         var _loc2_:StaticMapPinDescribed = '
                            'null;\n         this.cmfSpreadReset();' in r for r in replaces))
        self.assertTrue(any('var _loc12_:Dictionary = null;\n         this.cmfSpreadReset();' in r for r in replaces))
        tick = as_body(self.hub, '      private function cmfSpreadTick() : void')
        self.assertIn('now = getTimer();', tick)
        self.assertIn('ms / this.cmfSpreadOpenMs', tick)
        self.assertIn('ms / this.cmfSpreadCloseMs', tick)
        # The controller does not snap the map to a pin of an open row.
        self.assertTrue(any('param2 = param2 && !this.cmfSpreadHas(this._closestPinIndex);' in r for r in replaces))

    def test_one_note_per_open_and_close(self):
        self.assertEqual(self.hub.count('cmfNote("spread '), 3)
        self.assertIn('this.cmfNote("spread open n=" + this.cmfSpreadPins.length + " rank=" + rank);',
                      as_body(self.hub, '      private function cmfSpreadFind() : void'))
        close = as_body(self.hub, '      private function cmfSpreadClose(param1:String) : void')
        self.assertIn('" why=" + param1 + " drift="', close)
        self.assertIn('this.WorldXToMapX(w.x) * s', close)
        keep = as_body(self.hub, '      private function cmfSpreadKeep() : String')
        self.assertIn('return "pins";', keep)
        self.assertIn('return "cursor";', keep)
        self.assertIn('return "";', keep)
        # A kept row's middle moving more than 2 px at one zoom gets one note.
        self.assertIn('this.cmfNote("spread moved n=" + this.cmfSpreadPins.length + " dx="', keep)
        self.assertIn('if(this.GetScale() != this.cmfSpreadNoteS)', keep)

    def test_the_row_is_placed_from_the_pins_own_place(self):
        # Launch D3: a kept row crept up and left, because each update took a pin's own place back from its
        # rounded drawn position. The place the map gives a pin is now kept and the offset applied to it.
        self.assertIn('this.cmfBaseX = param1;\n         this.cmfBaseY = param2;', self.pin)
        fan = as_body(self.pin, '      public function cmfSetFan(param1:Number, param2:Number) : void')
        self.assertIn('x = this.cmfBaseX + param1;', fan)
        self.assertNotIn('x +=', fan)
        base = as_body(self.hub, '      private function cmfSpreadBase(')
        self.assertIn('new Point(param1.cmfBaseX,param1.cmfBaseY)', base)
        # The selected pin's copy takes its pin's own place while the pin is in a row.
        avatar = next(e['replace'] for e in self.edits['classes'][WORLDMAP + 'HubMap.as']
                      if e['find'].startswith('            _loc2_ = this._selectedPinAvatar.GetWorldPosition();'))
        self.assertIn('this.cmfSpreadPins.indexOf(this._staticMapPins[this._selectedMapPinIndex]) >= 0', avatar)
        self.assertIn('this._selectedPinAvatar.UpdateMapPosition2(this._staticMapPins[this._selectedMapPinIndex].cmfBaseX,', avatar)
        self.assertIn('this._selectedPinAvatar.UpdateMapPosition2(this.WorldXToMapX(_loc2_.x) * param1,', avatar)

    def test_a_selected_pin_hides_its_label_drawing(self):
        replaces = [e['replace'] for e in self.edits['classes'][WORLDMAP + 'HubMap.as']]
        self.assertTrue(any('_loc2_.tfLabel.visible = false;\n         _loc2_.cmfTagShown(false);\n' in r for r in replaces))
        self.assertTrue(any('_loc2_.tfLabel.visible = true;\n            _loc2_.cmfTagShown(true);\n' in r for r in replaces))
        self.assertIn('public function cmfTagShown(param1:Boolean) : void', self.pin)

    def test_who_joins(self):
        joins = as_body(self.hub, '      private function cmfSpreadJoins(param1:StaticMapPinDescribed) : Boolean')
        for text in ('!pinData.isPlayer', '!(pinData.radius > 0)', '!param1.isHidden()', 'param1.IsVisibleInArea()'):
            self.assertIn(text, joins)
        find = as_body(self.hub, '      private function cmfSpreadFind() : void')
        self.assertIn('(this.cmfSpreadAny || Boolean(pin.data.isQuest))', find)
        self.assertIn('this.cmfSpreadStack * this.GetScale() / this._maxZoom', find)
        self.assertIn('if(near.length < 2)', find)
        self.assertIn('near = this.cmfSpreadStackOf(anchor,from,room,reach,at);', find)
        stack = as_body(self.hub, '      private function cmfSpreadStackOf(')
        self.assertIn('if(dx * dx + dy * dy <= param4 * param4)', stack)
        self.assertIn('members.sortOn("d",Array.NUMERIC);', stack)
        self.assertIn('return members.slice(0,this.cmfSpreadMax);', stack)


class ModelTests(unittest.TestCase):
    def test_row_is_centred_and_the_highest_rank_is_picked(self):
        bases = [(100, 100), (104, 98), (98, 103)]
        near, offsets, pick = row(bases, [2, 7, 4], (100, 100))
        self.assertEqual(near, [2, 0, 1])
        shown = sorted(bases[i][0] + offsets[i][0] for i in near)
        cx = 302 / 3
        self.assertEqual([round(x, 6) for x in shown], [round(x, 6) for x in (cx - 48, cx, cx + 48)])
        self.assertEqual({round(bases[i][1] + offsets[i][1], 6) for i in near}, {round(301 / 3, 6)})
        self.assertEqual(pick, 1)

    def test_a_tie_goes_to_the_pin_nearest_the_cursor(self):
        _near, _offsets, pick = row([(100, 100), (101, 100), (120, 100)], [4, 0, 4], (119, 100))
        self.assertEqual(pick, 2)

    def test_a_loose_stack_is_the_same_from_any_of_its_pins(self):
        # Launch D2: pins 20 px apart in a chain; the far one used to stay behind and each pin the cursor reached
        # opened another subset centred elsewhere.
        bases = [(100, 100), (120, 104), (140, 108), (300, 100)]
        rows = [row(bases, [0] * 4, bases[a], anchor=a) for a in (0, 1, 2)]
        for near, offsets, _pick in rows:
            self.assertEqual(near, [0, 1, 2])
            self.assertEqual(offsets, rows[0][1])

    def test_at_most_max_pins(self):
        bases = [(100 + i, 100) for i in range(12)]
        near, _offsets, _pick = row(bases, [0] * 12, (100, 100))
        self.assertEqual(len(near), 8)


class GuideTests(unittest.TestCase):
    def test_guide_section(self):
        guide = GUIDE.read_text(encoding='utf-8')
        start = guide.index('Spreading stacked pins (API version 6)')
        section = guide[start:guide.index('\n## ', start)] if '\n## ' in guide[start:] else guide[start:]
        self.assertIn('Ran in game on 2026-10-20 with the mouse', section)
        for key in SPREAD_KEYS + ['CMFPropertySpreadRank']:
            self.assertIn(key, section)


if __name__ == '__main__':
    unittest.main()
