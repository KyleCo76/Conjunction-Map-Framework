"""API version 9 (plans/2026-10-23-cmf-rev9-build-contract.md in the shared project folder): world overview and button
pictures (ids 24 to 27, cmf.map.world), choice-only claims, the player marker as a hide target, the map's view
(OnMapView, OnMapOpening, CMFSetOpeningView, cmf.map.view) and the menu add-on 1.2.0 rows.

Static checks of cmfCore.ws, cmfMenu.ws, the menu tables and the pack tool, plus a Python mirror of the choice-only
rule and the opening view winner. Only a launch shows the game runs them.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
MENU_WS = ROOT/'source/menu/content/scripts/local/cmfMenu.ws'
VANILLA_MAP = Path('/mnt/user-data/uploads/menus/mapMenu.ws')
sys.path.insert(0, str(ROOT/'tools'))
import cmf_menu_addon as addon
import cmf_pack


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


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_version_and_property_ids(self):
        self.assertIn('function CMFGetVersion() : int { return 11; }', self.core)
        self.assertRegex(self.core.split('function CMFGetVersion')[0], r'version 9: world overview pictures')
        ids = {'CMFPropertyWorldPainting': 24, 'CMFPropertyWorldCrest': 25, 'CMFPropertyButtonPicture': 26,
               'CMFPropertyWorldMarker': 27}
        for name, number in ids.items():
            self.assertIn('function %s() : int { return %d; }' % (name, number), self.core)
            self.assertEqual(cmf_pack.PROPERTY_IDS[name], number)
            self.assertIn(number, cmf_pack.KNOWN_PROPERTIES)
            self.assertIn(name, cmf_pack.VERSION9)
        self.assertIn('CMFIsPictureProperty(propertyId)', body(self.core, 'function CMFHasProperty('))
        self.assertNotIn('Picture', body(self.core, 'function CMFPropertyTextFree('))
        # Picture claims are type claims only: CMFRegisterForTag's list does not take them.
        self.assertNotIn('Picture', body(self.core, 'function CMFRegisterForTag('))

    def test_named_calls(self):
        heads = [
            'function CMFRegisterWorldPainting(provider : string, url : string) : bool',
            'function CMFRegisterWorldPaintingTiles(provider : string, url : string, columns : int, rows : int) : bool',
            'function CMFRegisterWorldCrest(provider : string, region : name, url : string) : bool',
            'function CMFRegisterWorldMarker(provider : string, marker : name, url : string) : bool',
            'function CMFRegisterButtonPicture(provider : string, family : name, button : string, url : string) : bool',
            'function CMFRegisterChoiceOnly(provider : string, choiceKey : string) : bool',
            'function CMFSetOpeningView(provider : string, area : name, x : float, y : float, zoom : float, '
            'keepPlace : bool) : bool',
            'function CMFSetOpeningWorld(provider : string, area : name, worldX : float, worldY : float, zoom : float) '
            ': bool']
        for head in heads:
            self.assertIn(head, self.core)
            self.assertIn(re.match(r'function (\w+)', head).group(1), cmf_pack.API)
        tiles = body(self.core, 'function CMFRegisterWorldPaintingTiles(')
        self.assertIn('if (columns < 1 || columns > 8 || rows < 1 || rows > 8)', tiles)
        self.assertIn("'painting', '', url, columns * 10 + rows);", tiles)
        self.assertIn('target = CMFButtonTarget(family, button);',
                      body(self.core, 'function CMFRegisterButtonPicture('))

    def test_targets_and_withdrawal(self):
        upsert = body(self.core, 'public function Upsert(claim : SCMFClaim) : bool')
        picture = upsert[upsert.index('if (CMFIsPictureProperty(incoming.propertyId))'):]
        # The target is checked first, then text "" withdraws, then the number; all before the empty-text rejection.
        order = [picture.index(s) for s in ('reason=target', 'if (incoming.text == "")', 'claims.Erase(i);',
                                             'reason=range')]
        self.assertEqual(order, sorted(order))
        self.assertLess(upsert.index('if (CMFIsPictureProperty(incoming.propertyId))'), upsert.index('reason=empty'))
        target = body(self.core, 'function CMFPictureTargetOk(')
        self.assertIn('return target == "painting";', target)
        self.assertIn('CMFListHas("xbox,ps4,ps5,steam,switch", family)', target)
        self.assertIn('return target == "player" || target == "quest";', target)
        self.assertEqual(cmf_pack.BUTTON_FAMILIES, ('xbox', 'ps4', 'ps5', 'steam', 'switch'))
        issues = cmf_pack.picture_issues
        self.assertEqual(issues(24, 'painting', 'a.png', '0'), [])
        self.assertEqual(issues(24, 'painting', 'a_{x}_{y}.png', '22'), [])
        self.assertEqual(issues(25, 'skellige', '', '0'), [])
        self.assertEqual(issues(26, 'xbox_gamepad_Y', 'y.png', '0'), [])
        self.assertEqual(issues(27, 'quest', 'q.png', '0'), [])
        for case in ((24, 'world', 'a.png', '0'), (24, 'painting', 'a.png', '19'), (25, '', 'a.png', '0'),
                     (26, 'gamepad', 'y.png', '0'), (26, 'wii_gamepad_Y', 'y.png', '0'), (26, 'xbox_', 'y.png', '0'),
                     (27, 'horse', 'h.png', '0'), (25, 'skellige', 'a.png', '1')):
            self.assertTrue(issues(*case), case)

        def tiles_ok(number):
            return number == 0 or (1 <= number // 10 <= 8 and 1 <= number % 10 <= 8)
        self.assertIn('number == 0 || (number / 10 >= 1 && number / 10 <= 8 && number % 10 >= 1 && number % 10 <= 8)',
                      body(self.core, 'function CMFPaintingTilesOk('))
        self.assertTrue(all(tiles_ok(c * 10 + r) for c in range(1, 9) for r in range(1, 9)))
        self.assertFalse(any(tiles_ok(n) for n in (1, 9, 10, 19, 90, 91, 100, -11)))

    def test_choice_keys_and_property_choices(self):
        keys = choice_keys(self.core)
        self.assertEqual(keys[59:62], ['Painting_World', 'Painting_Crests', 'Movement_View'])
        choice = body(self.core, 'public function PropertyChoice(propertyId : int, pinType : string) : int')
        self.assertIn('case 24:\n\t\t\t\treturn 59; // Painting_World', choice)
        self.assertIn('case 25:\n\t\t\tcase 27:\n\t\t\t\treturn 60; // Painting_Crests', choice)
        self.assertIn('case 26:\n\t\t\t\treturn 42; // Look_Hints', choice)
        self.assertIn('NoteOfferFor(61, openingViews[i].provider);', body(self.core, 'private function PrepareOffers()'))
        # The new pieces are ordinary pieces: only 56 to 58 are Drawings leave-out slots.
        self.assertIn('(choice >= 56 && choice <= 58)', body(self.core, 'public function Offers('))
        self.assertIn('(i >= 56 && i <= 58)', body(self.core, 'private function ReportChoices()'))
        self.assertNotRegex(self.core, r'>= 56\)')

    def test_world_hand_off(self):
        theme = body(self.core, 'public function SendTheme(storage : CScriptedFlashValueStorage)')
        self.assertLess(theme.index('storage.SetFlashArray("cmf.map.theme", flashArray);'), theme.index('SendWorld(storage);'))
        world = body(self.core, 'private function SendWorld(storage : CScriptedFlashValueStorage)')
        self.assertIn("Find(winners[i].propertyId, NameToString(winners[i].pinType), '', 1, claim)", world)
        for field in ('"t"', '"y"', '"s"', '"c"', '"r"', '"p"'):
            self.assertIn('SetMemberFlash', world.split(field)[0].splitlines()[-1])
        for kind in ('"painting"', '"crest"', '"marker"', '"button"'):
            self.assertIn('kind = %s;' % kind, world)
        self.assertIn('storage.SetFlashArray("cmf.map.world", flashArray);', world)
        self.assertIn('CMFLog("world sent painting=" + painting + " crests=" + crests + " markers=" + markers + '
                      '" buttons=" + buttons);', world)
        note = body(self.core, 'event OnCMFPictureNote(line : string)')
        self.assertIn('CMFLog(line);', note)
        self.assertIn('@addMethod(CR4MapMenu)\nevent OnCMFPictureNote(line : string)', self.core)

    def test_choice_only_reaches_claims_parts_and_views(self):
        register = body(self.core, 'public function RegisterChoiceOnly(provider : string, choiceKey : string) : bool')
        self.assertIn('"choice only rejected provider=" + provider + " key=" + choiceKey + " reason=key"', register)
        self.assertIn('"choice only provider=" + provider + " key=" + choiceKey', register)
        skips = body(self.core, 'private function ChoiceOnlySkips(choice : int, provider : string) : bool')
        self.assertIn('(choiceOnlyChoices[i] == choice || choiceOnlyChoices[i] == feature)', skips)
        self.assertIn('return menuChoices[choice] != provider && menuChoices[feature] != provider && '
                      'fileChoices[choice] != provider &&\n\t\t\tfileChoices[feature] != provider;', skips)
        prepare = body(self.core, 'public function Prepare()')
        self.assertLess(prepare.index('ChoiceOnlySkips(PropertyChoice('), prepare.index('CMFPropertyHidden()'))
        self.assertIn('!ChoiceOnlySkips(keyChoice, themeEntries[i].provider)',
                      body(self.core, 'private function ThemeStyleOwner('))
        self.assertIn('ChoiceOnlySkips(61, openingViews[i].provider)', body(self.core, 'private function OpeningViewWinner('))
        self.assertIn('choiceOnly = " choiceonly=" + skipped;', body(self.core, 'private function ReportProviders()'))
        # Offers still come from every claim, so the menu lists a choice-only provider.
        self.assertNotIn('ChoiceOnlySkips', body(self.core, 'private function PrepareOffers()'))

    def test_player_hide(self):
        owner = body(self.core, 'private function PlayerHideOwner(mapContext : name) : string')
        self.assertIn("hideClaims[i].level == 1 && hideClaims[i].pinType == 'Player'", owner)
        self.assertNotIn('Exempt', owner)
        sweep = body(self.core, 'private function RemoveHiddenPins(flashArray : CScriptedFlashArray, area : name, '
                                'mapContext : name)')
        self.assertIn('CMFLog("hide player provider=" + playerOwner + " context=" + NameToString(mapContext));', sweep)
        self.assertIn('playerOwner = "";', sweep.split('hide player provider=')[1])
        self.assertIn('RemoveHiddenPins(flashArray, area, mapContext);', self.core)
        # Every-pin and tag hides still never reach the player marker.
        self.assertIn('if (dataObject.GetMemberFlashBool("isPlayer") || dataObject.GetMemberFlashBool("isUserPin"))',
                      body(self.core, 'private function HideOwner('))

    def test_view_hooks_and_opening(self):
        self.assertIn('public function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, '
                      'worldY : float,\n\t\tzoom : float, reason : name)\n\t{\n\t}', self.core)
        self.assertIn('public function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)\n\t{\n\t}',
                      self.core)
        for hook in ('OnMapView', 'OnMapOpening'):
            self.assertIn(hook, cmf_pack.HOOKS)
            self.assertIn(hook, cmf_pack.HOOKS9)
        view = body(self.core, 'public function MapView(')
        self.assertIn('"map view area=" + NameToString(area) + " reason=" + NameToString(reason) + " x="', view)
        opening = body(self.core, 'public function MapOpening(')
        self.assertLess(opening.index('OnMapOpening(menu, area, mapContext);'), opening.index('OpeningViewWinner('))
        self.assertIn('storage.SetFlashObject("cmf.map.view", item);', opening)
        for field in ('"s"', '"x"', '"y"', '"z"', '"k"', '"w"'):
            self.assertIn('item.SetMemberFlash', opening.split(field)[0].splitlines()[-1])
        self.assertIn('"map opening area=" + NameToString(area) + " context=" + NameToString(mapContext) + " view="',
                      opening)
        self.assertIn('if (view.worldPlace)', opening)
        self.assertIn('return StoreOpeningView(provider, area, x, y, zoom, keepPlace, false);',
                      body(self.core, 'public function SetOpeningView('))
        self.assertIn('return StoreOpeningView(provider, area, worldX, worldY, zoom, false, true);',
                      body(self.core, 'public function SetOpeningWorld('))
        store = body(self.core, 'private function StoreOpeningView(')
        self.assertIn('if (!keepPlace || zoom > 0)', store)
        self.assertIn('view.worldPlace = worldPlace;', store)
        self.assertIn('openingViews[i].provider == provider && openingViews[i].area == area', store)
        self.assertIn('theGame.CMFGetCore().MapView(this, m_shownArea, x, y, worldX, worldY, zoom, \'still\');',
                      body(self.core, 'event OnCMFMapView(x : float, y : float, worldX : float, worldY : float, zoom : float)'))
        self.assertIn('theGame.CMFGetCore().MapOpening(this, m_shownArea, CMFMapContext(), GetMenuFlashValueStorage());',
                      body(self.core, 'event OnCMFMapOpening()'))
        report = body(self.core, 'function CMFReportView(reason : name)')
        self.assertIn('menuFlash.GetMemberFlashBool("cmfViewOk")', report)
        for member in ('cmfViewX', 'cmfViewY', 'cmfViewWX', 'cmfViewWY', 'cmfViewZoom'):
            self.assertIn('GetMemberFlashNumber("%s")' % member, report)

    def test_region_shown_again_drops_the_last_answer(self):
        # Picking the shown region on the overview runs only ReinitializeMap: the last showing's view must not be
        # applied before the script answers again (rerun 6 log, Space then Velen).
        import json
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))
        menu = edits['classes']['red/game/witcher3/menus/worldmap/MapMenu.as']
        menu = menu if isinstance(menu, list) else menu['edits']
        reinit = [e for e in menu if e.get('find') == '         this.mcHubMap.ReinitializeMap();\n']
        self.assertEqual(len(reinit), 1)
        lines = [l.strip() for l in reinit[0]['replace'].splitlines() if not l.strip().startswith('//')]
        self.assertLess(lines.index('this.cmfViewRegion();'), lines.index('this.mcHubMap.ReinitializeMap();'))
        region = next(e['replace'] for e in menu if 'protected function cmfViewRegion() : void' in e.get('replace', ''))
        self.assertIn('this.mcHubMap.cmfNewRegion();', body(region, 'protected function cmfViewRegion() : void'))

    def test_zoom_only_view_sets_the_zoom_before_the_game_places(self):
        # Start B (Annoying Map): a zoom-only view applied after the game's placing on a region switch asked for the
        # map squares twice in one go and left them blurry.
        import json
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))
        hub = edits['classes']['red/game/witcher3/menus/worldmap/HubMap.as']
        hub = hub if isinstance(hub, list) else hub['edits']
        place = next(e['replace'] for e in hub if e['find'].startswith('      private function setInitMapPosition() : *'))
        self.assertLess(place.index('this.cmfSetZoom(Number(this.cmfViewWanted.z));'), place.index('this.CenterOnPin('))
        self.assertLess(place.index('this.UpdateLod(false);'), place.index('this.CenterOnPin('))
        self.assertIn('int(this.cmfViewWanted.k) != 0', place)

    def test_wrappers_match_the_game(self):
        switch = body(self.core, '@wrapMethod(CR4MapMenu)\nfunction SwitchToHubMap(area : name, onStartup : bool)')
        self.assertLess(switch.index("CMFReportView('region');"), switch.index('wrappedMethod(area, onStartup);'))
        self.assertIn('shown != m_shownArea', switch)
        closing = body(self.core, '@wrapMethod(CR4MapMenu)\nfunction OnClosingMenu()')
        self.assertEqual(closing.count('wrappedMethod('), 1)
        self.assertLess(closing.index("CMFReportView('close');"), closing.index('wrappedMethod();'))
        self.assertLess(closing.index('wrappedMethod();'), closing.index('CMFMapCheckClose();'))
        if VANILLA_MAP.is_file():
            vanilla = VANILLA_MAP.read_text(encoding='utf-8', errors='replace')
            self.assertIn('function SwitchToHubMap( area : name, onStartup : bool )', vanilla)
            self.assertRegex(vanilla, r'event\s+OnClosingMenu\(\)')


class Mirror:
    """Mirror of ChoiceOnlySkips and OpeningViewWinner (answer = decideAnswer[61] when choices are active)."""

    def __init__(self, keys, menu=None, files=None, choice_only=(), fall_vanilla=False, order=None):
        self.keys = keys
        self.menu = menu or {}
        self.files = files or {}
        self.choice_only = list(choice_only)
        self.fall_vanilla = fall_vanilla
        self.order = order or []

    def feature(self, key):
        return key.split('_')[0]

    def skips(self, key, provider):
        feature = self.feature(key)
        if not any(p == provider and k in (key, feature) for p, k in self.choice_only):
            return False
        return provider not in (self.menu.get(key), self.menu.get(feature), self.files.get(key), self.files.get(feature))

    def answer(self, key):
        feature = self.feature(key)
        for value in (self.menu.get(key), self.menu.get(feature), self.files.get(key), self.files.get(feature)):
            if value:
                return value
        return ''

    def piece_beats(self, a, b):
        for pick in (self.menu.get('Movement_View'), self.menu.get('Movement'), self.files.get('Movement_View'),
                     self.files.get('Movement')):
            if pick and pick != 'vanilla' and pick in (a, b):
                return pick == a
        return (self.order.index(a) if a in self.order else 99, a.lower()) < (
            self.order.index(b) if b in self.order else 99, b.lower())

    def view_winner(self, views, area):
        answer = self.answer('Movement_View')
        if answer == 'vanilla':
            return None
        best = picked = None
        for view in views:
            provider, view_area = view
            if (view_area and view_area != area) or self.skips('Movement_View', provider):
                continue
            if best is None or (bool(view_area) != bool(best[1]) and bool(view_area)) or (
                    bool(view_area) == bool(best[1]) and self.piece_beats(provider, best[0])):
                best = view
            if answer and provider == answer and (picked is None or view_area):
                picked = view
        if picked:
            return picked
        if best is None or (answer and self.fall_vanilla):
            return None
        return best


class MirrorTests(unittest.TestCase):
    def setUp(self):
        self.keys = choice_keys(CORE.read_text(encoding='ascii'))

    def test_contract_test_packs(self):
        # Contract section 6: B's crests are choice-only, A has none for White Orchard, so the game's crest shows
        # there until B is picked on the crests row.
        model = Mirror(self.keys, choice_only=[('modCMFTestWorldB', 'Painting_Crests')])
        self.assertTrue(model.skips('Painting_Crests', 'modCMFTestWorldB'))
        self.assertFalse(model.skips('Painting_World', 'modCMFTestWorldB'))
        self.assertFalse(model.skips('Painting_Crests', 'modCMFTestWorldA'))
        for menu in ({'Painting_Crests': 'modCMFTestWorldB'}, {'Painting': 'modCMFTestWorldB'}):
            self.assertFalse(Mirror(self.keys, menu=menu, choice_only=model.choice_only).skips(
                'Painting_Crests', 'modCMFTestWorldB'))
        self.assertFalse(Mirror(self.keys, files={'Painting_Crests': 'modCMFTestWorldB'},
                                choice_only=model.choice_only).skips('Painting_Crests', 'modCMFTestWorldB'))
        # A feature key covers its pieces.
        self.assertTrue(Mirror(self.keys, choice_only=[('modB', 'Painting')]).skips('Painting_World', 'modB'))

    def test_opening_view_winner(self):
        views = [('modA', ''), ('modB', 'AN_Skellige_ArdSkellig'), ('modC', '')]
        model = Mirror(self.keys)
        self.assertEqual(model.view_winner(views, 'AN_Skellige_ArdSkellig'), ('modB', 'AN_Skellige_ArdSkellig'))
        self.assertEqual(model.view_winner(views, 'AN_NMLandNovigrad'), ('modA', ''))
        self.assertEqual(Mirror(self.keys, order=['modC']).view_winner(views, 'AN_NMLandNovigrad'), ('modC', ''))
        self.assertIsNone(Mirror(self.keys, menu={'Movement_View': 'vanilla'}).view_winner(views, 'AN_NMLandNovigrad'))
        self.assertIsNone(Mirror(self.keys, menu={'Movement': 'vanilla'}).view_winner(views, 'AN_NMLandNovigrad'))
        self.assertEqual(Mirror(self.keys, menu={'Movement_View': 'modC'}).view_winner(
            views, 'AN_Skellige_ArdSkellig'), ('modC', ''))
        self.assertIsNone(Mirror(self.keys, menu={'Movement_View': 'modGone'}, fall_vanilla=True).view_winner(
            views, 'AN_NMLandNovigrad'))
        self.assertEqual(Mirror(self.keys, choice_only=[('modA', 'Movement_View')]).view_winner(
            views, 'AN_NMLandNovigrad'), ('modC', ''))
        self.assertIsNone(Mirror(self.keys).view_winner([], 'AN_NMLandNovigrad'))

    def test_core_winner_follows_the_mirror(self):
        winner = body(CORE.read_text(encoding='ascii'), 'private function OpeningViewWinner(')
        for line in ('answer = decideAnswer[61];', 'if (answer == "vanilla")',
                     '(IsNameValid(openingViews[i].area) && openingViews[i].area != area)',
                     '(picked < 0 || IsNameValid(openingViews[i].area))',
                     'if (best < 0 || (answer != "" && fallVanilla))'):
            self.assertIn(line, winner)
        beats = body(CORE.read_text(encoding='ascii'), 'private function OpeningViewBeats(')
        self.assertIn('return IsNameValid(a.area);', beats)
        self.assertIn('return PieceBeats(61, a.provider, b.provider);', beats)


class MenuTests(unittest.TestCase):
    def setUp(self):
        self.script = MENU_WS.read_text(encoding='ascii')

    def test_three_rows_and_their_who_wins_rows(self):
        pages = {group: rows for group, _p, _t, rows in addon.PAGES}
        self.assertIn(('pick', 'Painting_World', 'World overview'), pages['CMFMenuAdvPainting'])
        self.assertIn(('pick', 'Painting_Crests', 'Region crests and markers'), pages['CMFMenuAdvPainting'])
        self.assertIn(('pick', 'Movement_View', 'Opening view'), pages['CMFMenuAdvMovement'])
        self.assertIn(('win', 'Painting_World', 'World overview'), pages['CMFMenuWinPainting'])
        self.assertIn(('win', 'Painting_Crests', 'Region crests and markers'), pages['CMFMenuWinPainting'])
        self.assertIn(('win', 'Movement_View', 'Opening view'), pages['CMFMenuWinMovement'])

    def test_rows_newer_than_cmf_are_left_out(self):
        page = body(self.script, 'function CMFMenuFillPage(')
        for call in ('CMFMenuFillPick(', 'CMFMenuFillWin('):
            self.assertIn('rows.RemoveElement(i);', page.split('if (!' + call)[1].split('}')[0])
        for head in ('function CMFMenuFillPick(', 'function CMFMenuFillWin('):
            fill = body(self.script, head)
            self.assertIn('choice = core.ChoiceIndex(key);\n\tif (choice < 0)\n\t{\n\t\treturn false;\n\t}', fill)
            self.assertTrue(fill.rstrip('}').rstrip().endswith('return true;'), head)
        hand_over = body(self.script, '@wrapMethod(CMFCore) function ReadMenuChoices()')
        self.assertIn('value != "" && ChoiceIndex(StrAfterFirst(varText, "CMFName_")) >= 0', hand_over)
        # 1.1.1's title-screen greying stays.
        self.assertIn('remembered || (!offeredAny && stored == "")', self.script)


if __name__ == '__main__':
    unittest.main()


class GameCompileRuleTests(unittest.TestCase):
    """Rules the game's compiler enforces that the static checks once missed (rev 9 launches, 2026-10-23)."""

    SCRIPTS = ['source/core/content/scripts/local/cmfCore.ws', 'source/menu/content/scripts/local/cmfMenu.ws',
               'source/providers/modCMFTestWorldA/content/scripts/local/modcmftestworlda_cmf.ws',
               'source/providers/modCMFTestWorldB/content/scripts/local/modcmftestworldb_cmf.ws']

    def code(self, path):
        text = (ROOT/path).read_text(encoding='utf-8')
        text = re.sub(r'//[^\n]*', '', text)
        return re.sub(r'"(\\.|[^"\\])*"', '""', text)

    def test_name_literals_hold_only_letters_digits_and_underscore(self):
        for path in self.SCRIPTS:
            bad = [m for m in re.findall(r"'([^'\n]*)'", self.code(path)) if re.search(r'[^A-Za-z0-9_]', m)]
            self.assertEqual(bad, [], path)

    def test_no_text_to_name_call(self):
        # The game has NameToString but no way back ("Could not find function 'StringToName'").
        for path in self.SCRIPTS:
            self.assertNotIn('StringToName', self.code(path), path)

    def test_button_table_covers_every_family_and_button(self):
        table = body((ROOT/self.SCRIPTS[0]).read_text(encoding='utf-8'), 'function CMFButtonTarget(')
        for family in cmf_pack.BUTTON_FAMILIES:
            for button in cmf_pack.BUTTON_NAMES:
                line = '(button == "%s") { return \'%s_%s\'; }' % (button, family, button.replace('-', '_'))
                if family == 'steam' and button in cmf_pack.BUTTON_NAMES_NOT_STEAM:
                    self.assertNotIn(line, table)
                else:
                    self.assertIn(line, table)
