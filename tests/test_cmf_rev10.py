"""API version 10 (plans/2026-10-24-cmf-rev10-build-contract.md in the shared project folder): behaviour picked apart from
art (the Behaviour feature, its pieces and choices per theme key), the wide part, the wideAnchor drawing key, the
HoverName pin property, the opening keys readyAtFadeStart and revealEase, and CMFScreenWidth and CMFScreenHeight.

Static checks of cmfCore.ws, the core's settings menu and the pack tool, plus a Python mirror of the per-key choice
table and the one-owner-per-piece rule. Only a launch shows the game runs them.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
CORE_MENU = ROOT/'source/settings/menus/mod0000_ConjunctionMapFramework.xml'
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

NEW_KEYS = ['Behaviour', 'Behaviour_InfoBoxDodge', 'Behaviour_InfoBoxHeight', 'Movement_ZoomOut', 'Movement_Controller',
            'Behaviour_HoverNames', 'Movement_Wide']
CLEAR = ['clearMinHeight', 'clearSide', 'clearCursor', 'clearLeft', 'clearTop', 'clearRight', 'clearBottom', 'clearView']
RISE = ['rise', 'riseOffset', 'riseTracked', 'riseOffsetTracked']
ZOOM_OUT = ['zoomOutFit', 'edgeOvershoot']
CONTROLLER = ['crosshairRoam', 'safeLeft', 'safeTop', 'safeRight', 'safeBottom', 'snapSeconds', 'centerSeconds',
              'padHoldMs']


def body(source, head):
    start = source.index(head)
    i = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += {'{': 1, '}': -1}.get(source[i], 0)
        i += 1
    return source[start:i]


def choice_keys(core):
    keys = body(core, 'function CMFChoiceKeys() : string')
    return ''.join(re.findall(r'"([^"]*)"', keys)).split(',')


def part_choices(core):
    """PartChoice as a dict, read from its switch."""
    result, pending = {}, []
    for line in body(core, 'public function PartChoice(part : name) : int').splitlines():
        case = re.match(r"\s*case '(\w+)':", line)
        if case:
            pending.append(case.group(1))
        value = re.match(r'\s*return (\d+);', line)
        if value:
            for part in pending:
                result[part] = int(value.group(1))
            pending = []
    return result


def part_key_choice(parts, part, key):
    """Python mirror of PartKeyChoice (contract section 2)."""
    if part == 'tooltip' and key in CLEAR:
        return 63
    if part == 'pinLabel' and key in RISE:
        return 31
    if part == 'navigation' and key in ZOOM_OUT:
        return 65
    if part == 'navigation' and key in CONTROLLER:
        return 66
    if part == 'map' and key == 'backdrop':
        return 39
    return parts.get(part, -1)


def style_owner(entries, part, key, parts, per_key_parts=('map', 'navigation', 'opening', 'spread', 'wide')):
    """Python mirror of ThemeStyleOwner with no choices: the earliest provider among the entries that count."""
    choice = part_key_choice(parts, part, key)
    for provider, p, k in entries:
        if p != part:
            continue
        if (part in per_key_parts and k == key) or (part not in per_key_parts and part_key_choice(parts, p, k) == choice):
            return provider
    return ''


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_version_and_header(self):
        self.assertIn('function CMFGetVersion() : int { return 10; }', self.core)
        self.assertRegex(self.core.split('function CMFGetVersion')[0], r'version 10: behaviour picked apart from art')

    def test_choice_keys_and_parents(self):
        keys = choice_keys(self.core)
        self.assertEqual(keys[62:], NEW_KEYS)
        self.assertNotIn('Movement_Reserved', keys)
        parent = body(self.core, 'function CMFChoiceParent(choice : int) : int')
        self.assertIn('if (choice == 28 || choice == 29 || choice == 31)\n\t{\n\t\treturn 62; // Behaviour', parent)
        ensure = body(self.core, 'private function EnsureChoices()')
        self.assertLess(ensure.index('CMFChoiceParent(i) >= 0'), ensure.index('StrBeforeFirst(choiceKeys[i], "_")'))
        self.assertEqual([keys[i] for i in (28, 29, 31)], ['Size_Lead', 'Size_Spread', 'Labels_Place'])

    def test_property_choices(self):
        choice = body(self.core, 'public function PropertyChoice(propertyId : int, pinType : string) : int')
        self.assertIn('case 14:\n\t\t\t\treturn 64; // Behaviour_InfoBoxHeight', choice)
        self.assertIn('case 28:\n\t\t\t\treturn 67; // Behaviour_HoverNames', choice)
        self.assertIn('case 22:\n\t\t\t\treturn 28; // Size_Lead', choice)
        self.assertIn('case 11:\n\t\t\tcase 13:\n\t\t\t\treturn 31; // Labels_Place', choice)
        self.assertEqual(part_choices(self.core)['wide'], 68)

    def test_part_key_choice_table(self):
        source = body(self.core, 'public function PartKeyChoice(part : name, key : name) : int')
        for key in CLEAR + RISE + CONTROLLER:
            self.assertIn(key, source)
        self.assertIn("if (key == 'zoomOutFit' || key == 'edgeOvershoot')", source)
        self.assertIn("if (key == 'backdrop')\n\t\t\t\t{\n\t\t\t\t\treturn 39; // Look_Frames", source)
        self.assertTrue(source.rstrip().endswith('return PartChoice(part);\n\t}'))
        # Every key the mirror sends to a new piece is a key that part takes.
        for part, keys in (('tooltip', CLEAR), ('pinLabel', RISE), ('navigation', ZOOM_OUT + CONTROLLER)):
            for key in keys:
                self.assertIn(key, cmf_pack.THEME_PART_KEYS[part], key)

    def test_theme_owner_uses_the_key_choice(self):
        owner = body(self.core, 'private function ThemeStyleOwner(part : name, key : name) : string')
        self.assertIn("|| part == 'wide';", owner)
        self.assertIn('keyChoice = PartKeyChoice(part, key);', owner)
        self.assertIn('choice = keyChoice;', owner)
        self.assertIn('(!perKey && PartKeyChoice(part, themeEntries[i].key) == keyChoice)', owner)
        self.assertIn('!ChoiceOnlySkips(keyChoice, themeEntries[i].provider)', owner)
        self.assertIn('NoteOfferFor(PartKeyChoice(themeEntries[i].target, themeEntries[i].key), themeEntries[i].provider);',
                      body(self.core, 'private function PrepareOffers()'))
        self.assertIn('" piece=" +\n\t\t\t\t\t\tChoiceKey(PartKeyChoice(themeEntries[i].target, themeEntries[i].key))',
                      body(self.core, 'public function SendTheme(storage : CScriptedFlashValueStorage)'))

    def test_one_owner_per_piece(self):
        parts = part_choices(self.core)
        # A mod sending only the info box's clear keys, folder-first, no longer owns the info box's look.
        entries = [('modA', 'tooltip', 'clearMinHeight'), ('modB', 'tooltip', 'titleFont'), ('modB', 'tooltip', 'clearSide')]
        self.assertEqual(style_owner(entries, 'tooltip', 'titleFont', parts), 'modB')
        self.assertEqual(style_owner(entries, 'tooltip', 'bodyFont', parts), 'modB')
        # One provider owns all of a piece: modA's clear keys win the whole piece, never mixed with modB's.
        self.assertEqual(style_owner(entries, 'tooltip', 'clearSide', parts), 'modA')
        # Label rise goes with label place, not with the label font.
        entries = [('modA', 'pinLabel', 'font'), ('modB', 'pinLabel', 'rise')]
        self.assertEqual(style_owner(entries, 'pinLabel', 'riseOffset', parts), 'modB')
        self.assertEqual(style_owner(entries, 'pinLabel', 'size', parts), 'modA')
        # Behaviour parts stay key by key.
        entries = [('modA', 'navigation', 'stepMs'), ('modB', 'navigation', 'zoomOutFit')]
        self.assertEqual(style_owner(entries, 'navigation', 'zoomOutFit', parts), 'modB')
        self.assertEqual(style_owner(entries, 'navigation', 'stepMs', parts), 'modA')

    def test_wide_part(self):
        self.assertIn(',opening,spread,wide";', body(self.core, 'function CMFThemeParts() : string'))
        self.assertIn('return "fill,panels,maxRatio,world";', body(self.core, 'function CMFThemeWideKeys() : string'))
        self.assertEqual(list(cmf_pack.THEME_PART_KEYS['wide']), ['fill', 'panels', 'maxRatio', 'world'])
        values = body(self.core, 'function CMFThemeValueOk(')
        self.assertLess(values.index("if (part == 'wide')"), values.index("if (key == 'fill' && text == \"label\")"))
        ranges = body(self.core, 'function CMFThemeWideValueOk(key : name, number : float) : bool')
        self.assertIn("case 'fill':\n\t\tcase 'world':\n\t\t\treturn number == 0 || number == 1;", ranges)
        self.assertIn("return number >= 0 && number <= 1;", ranges)
        self.assertIn("return number == 0 || (number >= 1.78 && number <= 4);", ranges)
        self.assertIn('",navigation,opening,spread,wide", NameToString(anchor)', self.core)

    def test_wide_vanilla_and_log(self):
        theme = body(self.core, 'public function SendTheme(storage : CScriptedFlashValueStorage)')
        self.assertLess(theme.index('SendWideVanilla(storage, flashArray);'),
                        theme.index('storage.SetFlashArray("cmf.map.theme", flashArray);'))
        vanilla = body(self.core, 'private function SendWideVanilla(')
        self.assertIn('if (choicesActive && decideAnswer[68] == "vanilla")', vanilla)
        self.assertIn('item.SetMemberFlashString("t", "wide");', vanilla)
        self.assertIn('item.SetMemberFlashString("y", "fill");', vanilla)
        self.assertIn('item.SetMemberFlashNumber("n", 0);', vanilla)
        self.assertIn('item.SetMemberFlashInt("p", -1);', vanilla)
        self.assertIn('CMFLog("wide owner=vanilla");', vanilla)
        self.assertIn('owner = "CMF";', vanilla)

    def test_screen(self):
        send = body(self.core, 'public function SendScreen(storage : CScriptedFlashValueStorage)')
        self.assertIn('theGame.GetCurrentViewportResolution(w, h);', send)
        self.assertIn('storage.SetFlashObject("cmf.map.screen", item);', send)
        ready = body(self.core, 'event OnCMFMapThemeReady()')
        self.assertLess(ready.index('SendScreen('), ready.index('SendTheme('))
        self.assertIn('@addMethod(CR4MapMenu)\nevent OnCMFScreen(width : float, height : float)', self.core)
        self.assertIn('theGame.CMFGetCore().ScreenSeen(width, height);', body(self.core, 'event OnCMFScreen('))
        self.assertIn('return theGame.CMFGetCore().ScreenWidth();', body(self.core, 'function CMFScreenWidth() : float'))
        self.assertIn('return theGame.CMFGetCore().ScreenHeight();', body(self.core, 'function CMFScreenHeight() : float'))
        self.assertTrue({'CMFScreenWidth', 'CMFScreenHeight', 'CMFPropertyHoverName'} <= cmf_pack.VERSION10)

    def test_hover_name_property(self):
        self.assertIn('function CMFPropertyHoverName() : int { return 28; }', self.core)
        self.assertIn('propertyId == CMFPropertyHoverName()', body(self.core, 'function CMFHasProperty('))
        self.assertIn('propertyId == CMFPropertyHoverName()', body(self.core, 'function CMFPropertyTextFree('))
        self.assertIn('propertyId != CMFPropertyHoverName()', body(self.core, 'function CMFRegisterForTag('))
        self.assertIn('propertyId == CMFPropertyHoverName()) && !IsNameValid(target)', body(self.core, 'function CMFRegister('))
        self.assertIn('case 28:\n\t\t\treturn "cmfHoverNameBy";', body(self.core, 'function CMFOwnerField('))
        self.assertIn('WriteSlot(dataObject, CMFPropertyHoverName(), pinKey, legendKey, pinTag, maxLevel);', self.core)
        self.assertIn('case 28:\n\t\t\t\tdataObject.SetMemberFlashInt("cmfHoverName", number);', self.core)
        self.assertIn('(incoming.propertyId == CMFPropertyHoverName() && (incoming.number < 0 || incoming.number > 3))',
                      self.core)
        self.assertIn('(propertyId == CMFPropertyHoverName() && (number < 0 || number > 3))', self.core)
        self.assertEqual(cmf_pack.PROPERTY_IDS['CMFPropertyHoverName'], 28)
        self.assertIn(28, cmf_pack.KNOWN_PROPERTIES)
        self.assertEqual(cmf_pack.n4_issues(28, '', '3'), [])
        self.assertEqual(len(cmf_pack.n4_issues(28, '', '4')), 1)

    def test_drawing_and_opening_keys(self):
        self.assertIn(',minPartHeight,wideAnchor";', body(self.core, 'function CMFThemeShapeKeys('))
        self.assertIn('clearSide,wideAnchor"', body(self.core, 'function CMFThemeTextKey('))
        self.assertIn("case 'wideAnchor':\n\t\t\t\treturn text == \"edges\" || text == \"panels\" || text == \"centre\";",
                      body(self.core, 'function CMFThemeValueOk('))
        for kind in ('rect', 'ring', 'ellipse', 'polygon', 'band', 'text'):
            self.assertIn('wideAnchor', cmf_pack.THEME_KIND_KEYS[kind])
        for kind in ('line', 'movie'):
            self.assertNotIn('wideAnchor', cmf_pack.THEME_KIND_KEYS[kind])
        self.assertIn('revealSeconds,readyAtFadeStart,revealEase";', body(self.core, 'function CMFThemeOpeningKeys()'))
        motion = body(self.core, 'function CMFThemeMotionValueOk(')
        self.assertIn("case 'readyAtFadeStart':\n\t\tcase 'revealEase':\n\t\t\treturn number == 0 || number == 1;", motion)

    def test_settings_file_keys(self):
        menu = CORE_MENU.read_text(encoding='utf-8')
        for key in NEW_KEYS:
            self.assertIn('<Var id="CMFFile_%s"' % key, menu)

    def test_pack_tool_names_the_deciding_row(self):
        self.assertEqual(cmf_pack.theme_key_row('tooltip', 'clearSide'), 'Map behaviour > Info box moves out of the way')
        self.assertEqual(cmf_pack.theme_key_row('tooltip', 'titleFont'), 'Map look > Info box')
        self.assertEqual(cmf_pack.theme_key_row('navigation', 'zoomOutFit'), 'Map movement > Zoom out to the whole region')
        self.assertEqual(cmf_pack.theme_key_row('navigation', 'safeLeft'), 'Map movement > Controller crosshair')
        self.assertEqual(cmf_pack.theme_key_row('navigation', 'stepMs'), 'Map movement > Pan and zoom feel')
        self.assertEqual(cmf_pack.theme_key_row('map', 'backdrop'), 'Map look > Frames and panels')
        self.assertEqual(cmf_pack.theme_key_row('wide', 'fill'), 'Map movement > Fill wide screens')
        self.assertEqual(cmf_pack.theme_key_row('spread', 'on'), 'Map behaviour > Stacked pins spread out')
        parts = part_choices(self.core)
        names = {39: 'Map look > Frames and panels', 63: 'Map behaviour > Info box moves out of the way',
                 31: 'Map behaviour > Label place and hiding', 65: 'Map movement > Zoom out to the whole region',
                 66: 'Map movement > Controller crosshair'}
        for part, keys in cmf_pack.THEME_PART_KEYS.items():
            for key in keys:
                choice = part_key_choice(parts, part, key)
                if choice in names:
                    self.assertEqual(cmf_pack.theme_key_row(part, key), names[choice], (part, key))


class HoverNameEdgeTests(unittest.TestCase):
    # Launch 2026-10-24 (21:9 start): the hovered pin's name box ran past the right edge. The copy now keeps it on
    # screen when HubMap places or moves it, only for names on hover.
    def test_name_box_stays_on_screen(self):
        import json
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        spd = ''.join(e['replace'] for e in edits['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'])
        hub = ''.join(e['replace'] for e in edits['red/game/witcher3/menus/worldmap/HubMap.as'])
        self.assertIn('public function cmfKeepLabelOnScreen() : void', spd)
        self.assertIn('import red.game.witcher3.utils.CommonUtils;', spd)
        self.assertIn('(d.cmfHoverName & 2) != 0', spd)
        self.assertIn('rect = CommonUtils.getScreenRect();', spd)
        self.assertEqual(hub.count('this._selectedPinAvatar.cmfKeepLabelOnScreen();'), 2)


if __name__ == '__main__':
    unittest.main()
