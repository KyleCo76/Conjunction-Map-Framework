"""API version 11, step one, "one pin" (plans/2026-10-24-cmf-expose-everything-rev11.md in the shared project folder,
group A without A3, A7, A8 and A9): colour and frames by tag, art while undiscovered or completed, the info box title
and text, the info box height per pin, level variants, place claims, the player's markers, the game's own legend rows,
whole hidden tabs and the pin list log.

Static checks of cmfCore.ws, the map file edits, the core's settings menu, the pack tool and the test pack, plus a Python
mirror of which claim wins on a pin. Only a launch shows the game runs them.
"""
from pathlib import Path
import json
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
SETTINGS = ROOT/'source/core/content/scripts/local/cmfSettings.ws'
CORE_MENU = ROOT/'source/settings/menus/mod0000_ConjunctionMapFramework.xml'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
PACK = ROOT/'source/providers/modCMFTestOnePin'
sys.path.insert(0, str(ROOT/'tools'))
import cmf_menu_addon as addon
import cmf_pack
import cmf_pin_types

NEW_PROPERTIES = {'CMFPropertyInfoTitle': 18, 'CMFPropertyInfoText': 19, 'CMFPropertyIconUndiscovered': 29,
                  'CMFPropertyIconCompleted': 30, 'CMFPropertyTabHidden': 37}


def body(source, head):
    start = source.index(head)
    i = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += {'{': 1, '}': -1}.get(source[i], 0)
        i += 1
    return source[start:i]


def choice_keys(core):
    return ''.join(re.findall(r'"([^"]*)"', body(core, 'function CMFChoiceKeys() : string'))).split(',')


def replaced(path):
    data = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/' + path]
    return ''.join(e['replace'] for e in data)


def covers(claim, pin, max_level=3, radius=2.0):
    """Python mirror of CMFCore.Covers for the pin being written (SetPinContext)."""
    level = claim['level']
    if level > max_level:
        return False
    if level == 0:
        return True
    if level == 1:
        if claim['type'] == pin['key']:
            return True
        return max_level >= 3 and pin['variant'] != '' and claim['type'] == pin['variant']
    if level == 2:
        return pin['tag'] != '' and claim['tag'] == pin['tag']
    if level == 3:
        if claim['type'] not in (pin['key'], pin['variant']):
            return False
        return (claim['x'] - pin['x']) ** 2 + (claim['y'] - pin['y']) ** 2 <= radius * radius
    return False


def specific(claim, pin):
    """Python mirror of CMFCore.Specific."""
    if claim['level'] == 1:
        return 3 if pin['variant'] != '' and claim['type'] == pin['variant'] else 2
    return {2: 6, 3: 4}.get(claim['level'], 0)


def pin_context(key, own, tag='', x=0.0, y=0.0):
    """Python mirror of CMFCore.SetPinContext."""
    return {'key': key, 'variant': own if own != key and own.startswith(key) else '', 'tag': tag, 'x': x, 'y': y}


def winner(claims, pin, max_level=3):
    """The first most specific covering claim, as Find walks winners (already in folder order)."""
    best, rank = None, -1
    for claim in claims:
        if covers(claim, pin, max_level) and specific(claim, pin) > rank:
            best, rank = claim, specific(claim, pin)
    return best


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_version_and_header(self):
        self.assertIn('function CMFGetVersion() : int { return 11; }', self.core)
        self.assertRegex(self.core.split('function CMFGetVersion')[0], r'[Vv]ersion 11')

    def test_new_properties_are_declared_known_and_in_the_pack_tool(self):
        has = body(self.core, 'function CMFHasProperty(')
        for name, number in NEW_PROPERTIES.items():
            self.assertIn('function %s() : int { return %d; }' % (name, number), self.core)
            self.assertIn('%s()' % name, has)
            self.assertEqual(cmf_pack.PROPERTY_IDS[name], number)
            self.assertIn(number, cmf_pack.KNOWN_PROPERTIES)
        for line in ('function CMFInfoReplace() : int { return 0; }', 'function CMFInfoAdd() : int { return 1; }',
                     'function CMFLevelPlace() : int { return 3; }'):
            self.assertIn(line, self.core)
        self.assertRegex(self.core, r'function CMFPlaceRadius\(\) : float \{ return 2(\.0)?; \}')
        self.assertTrue({'CMFRegisterForPlace', 'CMFPropertyInfoTitle', 'CMFPropertyTabHidden'} <= cmf_pack.VERSION11)

    def test_one_pin_properties_match_the_pack_tool(self):
        one = body(self.core, 'function CMFOnePinProperty(')
        for call in ('CMFPropertyIcon()', 'CMFPropertyTint()', 'CMFPropertyDisabled()', 'CMFPropertyHidden()',
                     'CMFPropertyPinScale()', 'CMFPropertyTabHide()', 'CMFPropertyLabelColor()',
                     'CMFIsClickProperty(propertyId)', 'CMFPropertySpreadRank()', 'CMFPropertyHoverName()',
                     'CMFPropertyInfoTitle()', 'CMFPropertyInfoText()', 'CMFPropertyIconUndiscovered()',
                     'CMFPropertyIconCompleted()'):
            self.assertIn(call, one)
        self.assertNotIn('CMFPropertyTabHidden()', one)
        self.assertEqual(cmf_pack.ONE_PIN_PROPERTIES, {1, 3, 5, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
                                                       28, 29, 30})
        for head in ('function CMFRegisterForTag(', 'function CMFRegisterForPlace('):
            self.assertIn('if (!CMFOnePinProperty(propertyId))', body(self.core, head))

    def test_place_claims_carry_their_place_and_level(self):
        place = body(self.core, 'function CMFRegisterForPlace(')
        for line in ('claim.level = CMFLevelPlace();', 'claim.placeX = x;', 'claim.placeY = y;',
                     'return theGame.CMFGetCore().Upsert(claim);'):
            self.assertIn(line, place)
        self.assertIn('a.placeX == b.placeX && a.placeY == b.placeY', body(self.core, 'private function SameSlot('))

    def test_choice_keys_and_owners(self):
        keys = choice_keys(self.core)
        self.assertEqual(keys[69:], ['Reserved69', 'Icons_Undiscovered', 'Look_InfoText'])
        choice = body(self.core, 'public function PropertyChoice(propertyId : int, pinType : string) : int')
        for case, value in (('29', 70), ('30', 14), ('19', 71), ('37', 35)):
            self.assertRegex(choice, r'case %s:\n(\t+case \d+:\n)*\t+return %d;' % (case, value))
        owner = body(self.core, 'function CMFOwnerField(')
        for case, field in ((14, 'cmfDescMaxHBy'), (18, 'cmfInfoTitleBy'), (19, 'cmfInfoTextBy'), (29, 'cmfIconBy'),
                            (30, 'cmfIconBy')):
            self.assertRegex(owner, r'case %d:\n(\t+case \d+:\n)*\t+return "%s";' % (case, field))

    def test_settings_switch_and_menu(self):
        self.assertIn("GetVarValue('CMFSettings', 'CMFLogPins')", SETTINGS.read_text(encoding='ascii'))
        menu = CORE_MENU.read_text(encoding='utf-8')
        for var in ('CMFFile_Icons_Undiscovered', 'CMFFile_Look_InfoText', 'CMFLogPins'):
            self.assertRegex(menu, r'<Var id="%s" value=""' % var)
        self.assertNotIn('CMFFile_Reserved69', menu)

    def test_markers_take_type_claims_only(self):
        markers = body(self.core, 'private function WriteMarkerFields(')
        for word in ('"Player"', '"User"', 'CMFPropertyIcon()', 'CMFPropertyTint()', 'CMFPropertyPinScale()'):
            self.assertIn(word, markers)
        self.assertNotIn('CMFLevelPlace()', markers)

    def test_pin_list_log_has_every_field(self):
        line = body(self.core, 'private function NoteListPin(')
        for word in ('pin list area=', ' type=', ' kind=', ' filteredType=', ' tag=', ' id=', ' label=', ' x=', ' y='):
            self.assertIn(word, line)


class WinnerTests(unittest.TestCase):
    """Which claim wins on one pin: tag, then place, then the variant type, then the type, then every pin."""

    CLAIMS = [{'level': 0, 'type': '', 'tag': '', 'x': 0, 'y': 0, 'id': 'every'},
              {'level': 1, 'type': 'MonsterNest', 'tag': '', 'x': 0, 'y': 0, 'id': 'type'},
              {'level': 1, 'type': 'MonsterNest_2', 'tag': '', 'x': 0, 'y': 0, 'id': 'variant'},
              {'level': 3, 'type': 'MonsterNest', 'tag': '', 'x': 100.0, 'y': 200.0, 'id': 'place'},
              {'level': 2, 'type': '', 'tag': 'nest_a', 'x': 0, 'y': 0, 'id': 'tag'}]

    def test_order(self):
        pin = pin_context('MonsterNest', 'MonsterNest_2', 'nest_a', 100.5, 200.5)
        self.assertEqual(winner(self.CLAIMS, pin)['id'], 'tag')
        pin['tag'] = 'nest_b'
        self.assertEqual(winner(self.CLAIMS, pin)['id'], 'place')
        pin['x'] = 103.0
        self.assertEqual(winner(self.CLAIMS, pin)['id'], 'variant')
        self.assertEqual(winner(self.CLAIMS, pin_context('MonsterNest', 'MonsterNest_1'))['id'], 'type')
        self.assertEqual(winner(self.CLAIMS, pin_context('RoadSign', 'RoadSign'))['id'], 'every')

    def test_legend_lookups_never_see_place_or_variant_claims(self):
        pin = pin_context('MonsterNest', 'MonsterNest_2', '', 100.0, 200.0)
        self.assertEqual(winner(self.CLAIMS, pin, max_level=1)['id'], 'type')

    def test_core_ranks_match_the_mirror(self):
        core = CORE.read_text(encoding='ascii')
        rank = body(core, 'private function Specific(')
        self.assertEqual(re.findall(r'return (\d+);', rank), ['3', '2', '6', '4', '0'])
        self.assertIn('dx * dx + dy * dy <= CMFPlaceRadius() * CMFPlaceRadius()', body(core, 'private function Covers('))


class PanelTests(unittest.TestCase):
    def test_new_fields_and_tab_drop(self):
        data = replaced('data/StaticMapPinData.as')
        for field in ('public var cmfDescMaxH:Number = 0;', 'public var cmfDescMaxHBy:String = "";',
                      'public var cmfInfoTitleBy:String = "";', 'public var cmfInfoTextBy:String = "";'):
            self.assertIn(field, data)
        panel = replaced('menus/worldmap/HubMapPinPanel.as')
        self.assertIn('public var cmfHiddenTabs:String = "";', panel)
        self.assertIn('tabName != ALL_PINS_CATEGORY && hidden.indexOf(tabName.toLowerCase()) >= 0', panel)
        self.assertIn('if(Boolean(_loc9_) && param1.cmfLegendPriority > 0 && !param1.isQuest)', panel)
        menu = replaced('menus/worldmap/MapMenu.as')
        self.assertIn('public var cmfDescMaxAll:Number = 0;', menu)
        self.assertIn('event.mapppinData.cmfDescMaxH > 0', menu)


class PackToolTests(unittest.TestCase):
    def run_script(self, lines):
        report, claims, calls = cmf_pack.Report(), [], set()
        text = '\n'.join(lines) + '\n'
        cmf_pack.check_script('x.ws', text, 'modAcmeIcons', report, claims, calls)
        cmf_pack.check_claims('modAcmeIcons', claims, {}, report, cmf_pin_types.known_types())
        return report

    def test_new_calls_pass(self):
        report = self.run_script([
            'CMFRegisterForTag("modAcmeIcons", 3, \'seven_cats_inn\', \'\', "", 65535);',
            'CMFRegisterForTag("modAcmeIcons", 18, \'seven_cats_inn\', \'\', "Title", 0);',
            'CMFRegister("modAcmeIcons", 19, \'RoadSign\', \'\', "Line", 1);',
            'CMFRegister("modAcmeIcons", 29, \'MonsterNest\', \'\', "frame:Blacksmith", 0);',
            'CMFRegister("modAcmeIcons", 14, \'RoadSign\', \'\', "", 300);',
            'CMFRegister("modAcmeIcons", 37, \'Buffs\', \'\', "", 1);',
            'CMFRegister("modAcmeIcons", 1, \'Player\', \'\', "frame:Herbalist", 0);',
            'CMFRegisterForPlace("modAcmeIcons", 10, \'RoadSign\', 10.5, -20.0, "", 200);'])
        self.assertEqual(report.errors, [])

    def test_bad_values_fail(self):
        for line in ('CMFRegister("modAcmeIcons", 18, \'RoadSign\', \'\', "Title", 2);',
                     'CMFRegister("modAcmeIcons", 19, \'RoadSign\', \'\', "", 0);',
                     'CMFRegister("modAcmeIcons", 1, \'RoadSign\', \'\', "frame:", 0);',
                     'CMFRegisterForPlace("modAcmeIcons", 6, \'RoadSign\', 1.0, 2.0, "Quests", 1);'):
            self.assertNotEqual(self.run_script([line]).errors, [], line)

    def test_the_test_pack_is_clean(self):
        report = cmf_pack.check_pack(PACK)[0]
        self.assertEqual(report.errors, [])
        script = (PACK/'content/scripts/local/modcmftestonepin_cmf.ws').read_text(encoding='ascii')
        self.assertIn('CMFRequireVersion("modCMFTestOnePin", 11)', script)


class OpeningSpeedTests(unittest.TestCase):
    # Kyle's rule: CMF keeps the game's map-opening speed. Rev 11 launch (2026-10-24) measured 1.4.1 at 840 ms and
    # rev 11 at 704 ms once lookups skip what no provider asked for.
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def body(self, start, end):
        return self.core[self.core.index(start):self.core.index(end, self.core.index(start))]

    def test_lookups_return_early_for_unclaimed_properties(self):
        self.assertIn('!propertyWon[propertyId]', self.body('private function Find(', '\n\t}\n'))
        for start in ('private function FindOwn(', 'private function DisabledIndex('):
            self.assertIn('PropertyWon(', self.body(start, '\n\t}\n'))

    def test_pins_no_claim_reaches_skip_the_field_writing(self):
        write = self.body('public function WritePinFields', 'private function WriteStateIcon')
        self.assertLess(write.index('PinCovered(pinKey, pinKey, pinTag)'), write.index('WriteFields('))
        late = self.body('public function FillMissingPinFields', 'private function WritePinInfo')
        self.assertLess(late.index('PinCovered(pinType, filtered, pinTag)'), late.index('WriteFields('))
        self.assertIn('PropertyWon(CMFPropertyInfoTitle())', late)
        covered = self.body('private function PinCovered', 'private function PropertyWon')
        for part in ('everyPinClaims > 0', 'placeClaims > 0', 'claimedTypes.Contains(pinKey)',
                     'claimedTypes.Contains(legendKey)', 'claimedTypes.Contains(variantNow)', 'tagNames[i] == pinTag'):
            self.assertIn(part, covered)

    def test_info_box_pass_runs_only_for_pins_an_info_claim_reaches(self):
        info = self.body('private function WritePinInfo', 'private function LateTag')
        self.assertLess(info.index('InfoCovered(pinType, filtered, own, pinTag)'), info.index('WriteInfo('))
        covered = self.body('private function InfoCovered', '\n\t}\n')
        for part in ('infoEveryOrPlace', 'infoTypes.Contains(own)', 'infoTags[i] == pinTag'):
            self.assertIn(part, covered)

    def test_place_is_read_only_with_place_claims(self):
        context = self.body('private function SetPinContext', 'private function ClearPinContext')
        self.assertIn('placeOk = placeClaims > 0;', context)


class BuildTimingTests(unittest.TestCase):
    # Kyle 2026-10-24 17:04Z: with All Quest Markers (~1,850 pins) the opening still locks up ~1 s with CMF only.
    def test_late_pass_reads_the_kind_flags_once(self):
        fill = body(CORE.read_text(encoding='ascii'), '\tpublic function FillMissingPinFields(')
        self.assertEqual(fill.count('GetMemberFlashBool("isPlayer")'), 1)
        self.assertEqual(fill.count('GetMemberFlashBool("isUserPin")'), 1)
        self.assertIn('if (!isPlayer && !isUser && !dataObject.GetMemberFlashBool("cmfDone"))', fill)

    def test_build_steps_are_stamped(self):
        core = CORE.read_text(encoding='ascii')
        data = body(core, 'function UpdateData(optional ignoreSelectionChange : bool)')
        order = [data.index(x) for x in ('CMFStamp("data");', 'wrappedMethod(ignoreSelectionChange);', 'CMFStamp("sent");',
                                          'CatchLatePins(', 'CMFStamp("caught");', 'CMFStamp("end");')]
        self.assertEqual(order, sorted(order))
        pins = body(core, 'function UpdateUserMapPins(')
        self.assertLess(pins.index('CMFStamp("late");'), pins.index('FillMissingPinFields('))
        self.assertLess(pins.index('FillMissingPinFields('), pins.index('CMFStamp("lateEnd:" + flashArray.GetLength());'))
        stamp = body(core, 'function CMFStamp(step : string)')
        self.assertIn('GetMemberFlashFunction("cmfStamp")', stamp)
        self.assertIn('stamp.InvokeSelfOneArg(FlashArgString(step));', stamp)
        menu = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']
        code = ''.join(e['replace'] for e in menu)
        self.assertIn('public function cmfStamp(param1:String) : void', code)
        self.assertIn('this._cmfStamps = "build open+" + (now - this._cmfOpenedAt) + "ms";', code)


class InfoBoxPlaceTests(unittest.TestCase):
    # Kyle 2026-10-24 15:05Z: CMF exposes moving the info box; it never moves it on its own.
    def test_tooltip_x_and_y_move_the_box_from_the_games_place(self):
        core = CORE.read_text(encoding='ascii')
        keys = core[core.index("case 'tooltip':\n\t\t\t// Version 7"):]
        self.assertIn('clearRight,clearBottom,x,y,"', keys[:700])
        self.assertIn('x', cmf_pack.THEME_PART_KEYS['tooltip'])
        self.assertIn('y', cmf_pack.THEME_PART_KEYS['tooltip'])
        menu = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes'][
            'red/game/witcher3/menus/worldmap/MapMenu.as']
        code = ''.join(e['replace'] for e in menu)
        self.assertIn('this._cmfTooltipX += MapMenu.cmfNum("tooltip","x",0);', code)
        self.assertEqual(code.count('this.tooltipInstance.y += MapMenu.cmfNum("tooltip","y",0);'), 2)

    def test_x_and_y_go_with_the_placement_not_the_look(self):
        # Start D (2026-10-24 16:37Z): the test pack sent only x and y, sorted first and took the info box look from
        # Ink and Iron, so the game's plate showed under Ink and Iron's frame. x and y now answer the placement piece.
        core = CORE.read_text(encoding='ascii')
        choice = body(core, 'public function PartKeyChoice(part : name, key : name) : int')
        tip = choice[choice.index("case 'tooltip':"):choice.index("case 'pinLabel':")]
        self.assertIn('clearCursorWeight,x,y", NameToString(key)))', tip)
        self.assertIn('return 63; // Behaviour_InfoBoxDodge', tip)
        for key in ('x', 'y'):
            self.assertEqual(cmf_pack.THEME_KEY_ROWS[('tooltip', key)], 'Map behaviour > Info box moves out of the way')

    # Ink and Iron live placement plan (plans/2026-10-24-ink-and-iron-live-placement.md): a wider cursor area and a
    # wider search, all off by default.
    PICK_KEYS = ('clearCursorAbove', 'clearCursorBelow', 'clearCursorTitle', 'clearPadX', 'clearPadY', 'clearGap',
                 'clearBoxPad', 'clearPick', 'clearCursorWeight')

    def test_pick_keys_are_known_everywhere(self):
        core = CORE.read_text(encoding='ascii')
        keys = core[core.index("case 'tooltip':\n\t\t\t// Version 7"):][:900]
        choice = body(core, 'public function PartKeyChoice(part : name, key : name) : int')
        for key in self.PICK_KEYS:
            self.assertIn(key, keys)
            self.assertIn(key, choice[:600])
            self.assertIn(key, cmf_pack.THEME_PART_KEYS['tooltip'])
            self.assertEqual(cmf_pack.THEME_KEY_ROWS[('tooltip', key)], 'Map behaviour > Info box moves out of the way')
        self.assertIn('if (k == "clearCursorTitle" || k == "clearPick")\n\t{\n\t\treturn number == 0 || number == 1;',
                      core)
        guide = (ROOT/'docs/authors/theme-parts-and-keys.md').read_text(encoding='utf-8')
        for key in self.PICK_KEYS:
            self.assertIn('`%s`' % key, guide)

    def panel_code(self):
        menu = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']
        return ''.join(e['replace'] for e in menu)

    def test_panel_pick_keeps_the_place_when_no_key_is_set(self):
        code = self.panel_code()
        self.assertIn('best = this.cmfClearPick(box,cx,cy,gap,limit,avoid,best);', code)
        self.assertIn('if(above == 0 && below == 0 && padX == 0 && padY == 0 && space == 0 && boxPad == 0 && pick == 0 && '
                      'weight == 10)\n         {\n            return best;', code)
        for key in self.PICK_KEYS:
            self.assertIn('MapMenu.cmfNum("tooltip","%s",' % key, code)

    @staticmethod
    def pick(box, cx, cy, gap, limit, avoid, title_w, above=0, below=0, title=0, padx=0, pady=0, space=0, boxpad=0,
             pick=0, weight=10):
        # Mirror of cmfClearPick; rectangles are (x, y, w, h).
        def overlap(a, b):
            w = min(a[0]+a[2], b[0]+b[2]) - max(a[0], b[0])
            h = min(a[1]+a[3], b[1]+b[3]) - max(a[1], b[1])
            return w*h if w > 0 and h > 0 else 0
        area = [cx-gap, cy-gap, 2*gap, 2*gap]
        if above > 0 or below > 0:
            w = max(2*gap, title_w) if title == 1 else 2*gap
            x0, y0 = min(area[0], cx-w/2), min(area[1], cy-above)
            x1, y1 = max(area[0]+area[2], cx+w/2), max(area[1]+area[3], cy+below)
            area = [x0, y0, x1-x0, y1-y0]
        area = [area[0]-padx, area[1]-pady, area[2]+2*padx, area[3]+2*pady]
        b = [box[0]-boxpad, box[1]-boxpad, box[2]+2*boxpad, box[3]+2*boxpad]
        lx, ly, lw, lh = limit
        if pick == 1:
            xs = [area[0]+area[2]+space, area[0]-space-b[2], b[0]]
            ys = [b[1], ly, ly+lh-b[3]] + [y for a in avoid for y in (a[1]-8-b[3], a[1]+a[3]+8)]
            pairs = [(x, y) for x in xs for y in ys]
        else:
            pairs = [(area[0]+area[2]+space, cy-b[3]/2), (area[0]-space-b[2], cy-b[3]/2),
                     (cx-b[2]/2, area[1]-space-b[3]), (cx-b[2]/2, area[1]+area[3]+space)]
        best, score = None, None
        for x, y in pairs:
            r = [max(lx, min(x, lx+lw-b[2])), max(ly, min(y, ly+lh-b[3])), b[2], b[3]]
            s = weight*overlap(r, area) + sum(overlap(r, a) for a in avoid)
            if score is None or s < score:
                best, score = r, s
        return (best[0]+boxpad, best[1]+boxpad, box[2], box[3]), area

    def test_ink_and_iron_values_keep_the_pin_and_its_level_tag_clear(self):
        # A tracked quest pin with its level tag above it, the legend on the left and the tracker on the right.
        legend, tracker = (40, 200, 380, 700), (1500, 120, 380, 300)
        box = (760, 400, 420, 300)
        placed, area = self.pick(box, 960, 540, 70, (0, 0, 1920, 1080), [legend, tracker], 260, above=20, below=90,
                                 title=1, padx=12, pady=20, space=6, boxpad=28, pick=1, weight=12)
        inner = (placed[0]-28, placed[1]-28, placed[2]+56, placed[3]+56)
        self.assertFalse(inner[0] < area[0]+area[2] and area[0] < inner[0]+inner[2] and
                         inner[1] < area[1]+area[3] and area[1] < inner[1]+inner[3])
        for panel in (legend, tracker):
            self.assertFalse(placed[0] < panel[0]+panel[2] and panel[0] < placed[0]+placed[2] and
                             placed[1] < panel[1]+panel[3] and panel[1] < placed[1]+placed[3])


class MenuAddonTests(unittest.TestCase):
    def test_rows_for_the_new_pieces(self):
        rows = addon.choice_rows()
        self.assertIn('Icons_Undiscovered', rows)
        self.assertIn('Look_InfoText', rows)
        self.assertNotIn('Reserved69', rows)


class PanelSpeedTests(unittest.TestCase):
    # Start J (2026-10-24 17:51Z): with All Quest Markers (1,701 pins) tracking a quest from the map redraws every pin
    # in one frame (1,129 ms).
    def classes(self):
        return json.loads(EDITS.read_text(encoding='utf-8'))['classes']

    def test_unstyled_pins_skip_the_look_work(self):
        code = ''.join(e['replace'] for e in self.classes()['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'])
        tint = body(code, 'private function cmfApplyIconTint(param1:StaticMapPinData) : void')
        skip = ('if(!this._cmfLookSet && !param1.cmfIconTintEnabled && !param1.cmfDisabled && !param1.cmfIconPath && '
                '!this._cmfIconLoader)')
        self.assertLess(tint.index(skip), tint.index('this._cmfLookSet = true;'))
        self.assertLess(tint.index('this._cmfLookSet = true;'), tint.index('transform.colorTransform'))
        scale = body(code, 'private function cmfApplyPinScale(param1:StaticMapPinData) : void')
        self.assertLess(scale.index('if(!this._cmfBaseScales && _loc2_ == 1)'), scale.index('.scaleX ='))


if __name__ == '__main__':
    unittest.main()
