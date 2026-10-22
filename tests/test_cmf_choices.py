"""Version 8 per-feature choices: the choice keys, their groups and index comments, the order of authority
(a Python mirror of CMFCore's WinnerOf and PieceBeats, checked against each other), and the optional menu
add-on modCMFInGameMenu (its menu file, string catalog and script).

The mirror reads the rules from cmfCore.ws by hand; it proves the two functions agree with each other and
with Kyle's order, not that the game runs them. Only a launch shows that.
"""
import itertools
import json
from pathlib import Path
import random
import re
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_menu_addon as addon

CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
MENU_WS = ROOT/'source/menu/content/scripts/local/cmfMenu.ws'
PIN_TYPES = ROOT/'tools/cmf_pin_types.json'
FEATURES = ['Icons', 'Colours', 'Size', 'Labels', 'Clicks', 'Legend', 'Hidden', 'Look', 'Movement', 'Painting',
            'Drawings']


def core_text():
    return CORE.read_text(encoding='ascii')


def function_body(text, signature):
    match = re.search(re.escape(signature) + r'\n(\t*)\{\n(.*?)\n\1\}', text, re.S)
    assert match, signature
    return match.group(2)


def choice_keys():
    body = function_body(core_text(), 'function CMFChoiceKeys() : string')
    return ''.join(re.findall(r'"([^"]*)"', body)).split(',')


def pin_group_lists():
    body = function_body(core_text(), 'function CMFPinGroupTypes(group : int) : string')
    lists = {}
    for match in re.finditer(r'case (\d):\n\t\t\treturn (.*?);', body, re.S):
        lists[int(match.group(1))] = ''.join(re.findall(r'"([^"]*)"', match.group(2))).split(',')
    return lists


def pin_group(pin_type, lists):
    """Mirror of CMFPinGroup."""
    stem = pin_type
    if len(stem) > 2 and stem[-2:] in ('_1', '_2', '_3'):
        stem = stem[:-2]
    if 'Quest' in stem or stem in ('HorseRace', 'BoatRace'):
        return 1
    if stem in lists[5]:
        return 5
    if stem.endswith('Disabled'):
        return 3
    for group in (0, 4, 2, 6):
        if stem in lists[group]:
            return group
    return 7


class ChoiceKeyTests(unittest.TestCase):
    def test_keys_are_features_then_pieces(self):
        keys = choice_keys()
        self.assertEqual(len(keys), 59)
        self.assertEqual(len(set(keys)), 59)
        self.assertEqual(keys[:11], FEATURES)
        for key in keys[11:]:
            self.assertIn(key.split('_')[0], FEATURES, key)
            self.assertRegex(key, r'^[A-Za-z]+_[A-Za-z0-9]+$')
        self.assertEqual(keys[11:19], ['Icons_' + k for k, _ in addon.GROUP_NAMES])
        self.assertEqual(keys[19:27], ['Colours_' + k for k, _ in addon.GROUP_NAMES])
        self.assertEqual(keys[36:39], ['Hidden_Ignore1', 'Hidden_Ignore2', 'Hidden_Ignore3'])
        self.assertEqual(keys[56:], ['Drawings_Ignore1', 'Drawings_Ignore2', 'Drawings_Ignore3'])

    def test_index_comments_name_the_right_keys(self):
        keys = choice_keys()
        text = core_text()
        bodies = [function_body(text, 'public function PropertyChoice(propertyId : int, pinType : string) : int'),
                  function_body(text, 'public function PartChoice(part : name) : int'),
                  function_body(text, 'private function AdditiveAllows(feature : int, provider : string) : bool')]
        seen = 0
        for body in bodies:
            for number, key in re.findall(r'(\d+)(?: \+ PinGroupOf\(pinType\))?;\s*// (\w+)', body):
                self.assertEqual(keys[int(number)], key)
                seen += 1
        self.assertGreater(seen, 25)

    def test_ignore_slot_and_painting_indices(self):
        keys = choice_keys()
        text = core_text()
        self.assertIn('(choice >= 36 && choice <= 38) || choice >= 56', function_body(
            text, 'public function Offers(choice : int, provider : string) : bool'))
        painting = function_body(text, 'function CMFPaintingChoice(area : string) : int')
        for number in re.findall(r'return (\d+);', painting):
            self.assertTrue(keys[int(number)].startswith('Painting_'), number)
        self.assertEqual(sorted(int(n) for n in re.findall(r'return (\d+);', painting)), list(range(47, 56)))

    def test_painting_rows_cover_the_game_areas(self):
        areas = {'prolog_village': 'Painting_WhiteOrchard', 'prolog_village_winter': 'Painting_WhiteOrchardWinter',
                 'novigrad': 'Painting_Velen', 'skellige': 'Painting_Skellige', 'kaer_morhen': 'Painting_KaerMorhen',
                 'wyzima_castle': 'Painting_Vizima', 'island_of_mist': 'Painting_IsleOfMists',
                 'spiral': 'Painting_Spiral', 'bob': 'Painting_Toussaint'}
        keys = choice_keys()
        body = function_body(core_text(), 'function CMFPaintingChoice(area : string) : int')
        tests = re.findall(r'if \((.*?)\)\n\t\{\n(?:\t\tif \((.*?)\)\n\t\t\{\n\t\t\treturn (\d+);\n\t\t\}\n)?'
                           r'\t\treturn (\d+);', body)

        def mirror(area):
            lowered = area.lower()
            for condition, inner, inner_value, value in tests:
                if any(word in lowered for word in re.findall(r'"([^"]+)"', condition)):
                    if inner and any(word in lowered for word in re.findall(r'"([^"]+)"', inner)):
                        return int(inner_value)
                    return int(value)
            return -1
        for area, key in areas.items():
            self.assertEqual(keys[mirror(area)], key, area)
        self.assertEqual(mirror('some_dlc_area'), -1)

    def test_pin_groups_follow_the_legend_tabs(self):
        lists = pin_group_lists()
        expected = {'General': 0, 'Quests': 1, 'NPCs': 4, 'Buffs': 5}
        types = json.loads(PIN_TYPES.read_text(encoding='utf-8'))['types']
        self.assertGreater(len(types), 150)
        for entry in types:
            name, category = entry['name'], entry.get('category')
            if category == 'Exploration':
                want = 3 if name.endswith('Disabled') else 2
            elif category is None:
                if 'Quest' in name:
                    want = 1
                elif name.startswith('PlaceOfPower'):
                    want = 5
                elif name.endswith('Disabled'):
                    want = 3
                else:
                    want = 6
            else:
                want = expected[category]
            self.assertEqual(pin_group(name, lists), want, name)
            if name[-2:] not in ('_1', '_2', '_3'):
                self.assertEqual(pin_group(name + '_2', lists), want, name)
        self.assertEqual(pin_group('MyModsOwnPin', lists), 7)

    def test_tidy_names(self):
        body = function_body(core_text(), 'function CMFTidyName(provider : string) : string')
        for line in ('StrBeginsWith(StrLower(rest), "mod")', 'StrBeginsWith(StrLower(rest), "cmfadapter") && StrLen(rest) > 10',
                     'else if (StrBeginsWith(StrLower(rest), "cmf") && StrLen(rest) > 3)',
                     'StrFindFirst("0123456789_", StrLeft(rest, 1)) >= 0',
                     'else if (previous == "" || previous == " ")', 'letter = StrUpper(letter);'):
            self.assertIn(line, body)

        def tidy(provider):
            rest = provider
            if rest.lower().startswith('mod'):
                rest = rest[3:]
            if rest.lower().startswith('cmfadapter') and len(rest) > 10:
                rest = rest[10:]
            elif rest.lower().startswith('cmf') and len(rest) > 3:
                rest = rest[3:]
            rest = rest.lstrip('0123456789_')
            if not rest:
                return provider
            out, previous = '', ''
            for letter in rest:
                if letter == '_':
                    letter = ' '
                elif previous in ('', ' '):
                    letter = letter.upper()
                elif letter.isupper() and previous.islower():
                    out += ' '
                out += letter
                previous = letter
            return out
        self.assertEqual(tidy('modExampleIconPack'), 'Example Icon Pack')
        self.assertEqual(tidy('modCMFExampleIconPack'), 'Example Icon Pack')
        self.assertEqual(tidy('modCMFAdapterInkAndIron'), 'Ink And Iron')
        self.assertEqual(tidy('modcoloured_map_marker'), 'Coloured Map Marker')
        self.assertEqual(tidy('modInkAndIronUI'), 'Ink And Iron UI')
        self.assertEqual(tidy('modsome__mod'), 'Some  Mod')
        self.assertEqual(tidy('mod0000_ConjunctionMapFramework'), 'Conjunction Map Framework')
        self.assertEqual(tidy('mod'), 'mod')

    def test_every_style_part_has_a_choice(self):
        text = core_text()
        parts = ''.join(re.findall(r'"([^"]*)"', function_body(text, 'function CMFThemeParts() : string'))).split(',')
        body = function_body(text, 'public function PartChoice(part : name) : int')
        named = set(re.findall(r"case '(\w+)':", body))
        # mapSpace is an anchor for drawings only (no style keys), and drawings answer Drawings.
        self.assertEqual(set(parts) - named, {'mapSpace'})
        self.assertEqual(named - set(parts), set())


class Authority:
    """Mirror of CMFCore's order of authority (DecideChoice levels, WinnerOf, PieceBeats, ProviderBeats)."""

    def __init__(self, keys, menu, files, menu_order, file_order, fall_vanilla, offers):
        self.keys = keys
        self.menu = menu
        self.files = files
        self.menu_order = menu_order
        self.file_order = file_order
        self.fall_vanilla = fall_vanilla
        self.offers = offers
        self.active = any(menu.values()) or any(files.values())

    def feature(self, choice):
        key = self.keys[choice]
        return self.keys.index(key.split('_')[0])

    @staticmethod
    def rank(order, provider):
        if not order or not provider:
            return -1
        found = (',' + order.lower() + ',').find(',' + provider.lower() + ',')
        return found

    def order_decides(self, order, a, b):
        if not order:
            return None
        ra, rb = self.rank(order, a), self.rank(order, b)
        if ra == rb:
            return None
        if ra < 0:
            return False
        if rb < 0:
            return True
        return ra < rb

    @staticmethod
    def folder_beats(a, b):
        la, lb = a.lower(), b.lower()
        if la != lb:
            return la < lb
        return a < b

    def provider_beats(self, a, b):
        result = self.order_decides(self.menu_order, a, b)
        if result is not None:
            return result
        ra, rb = self.rank(self.file_order, a), self.rank(self.file_order, b)
        if ra != rb:
            if ra < 0:
                return False
            if rb < 0:
                return True
            return ra < rb
        return self.folder_beats(a, b)

    @staticmethod
    def pick_decides(pick, a, b):
        if pick in ('', 'vanilla'):
            return None
        if a == pick:
            return True
        if b == pick:
            return False
        return None

    def piece_beats(self, choice, a, b):
        if self.active and a != b:
            key, feature = self.keys[choice], self.keys[self.feature(choice)]
            steps = []
            if key != feature:
                steps.append(('pick', self.menu.get(key, '')))
            steps.append(('pick', self.menu.get(feature, '')))
            steps.append(('order', self.menu_order))
            if key != feature:
                steps.append(('pick', self.files.get(key, '')))
            steps.append(('pick', self.files.get(feature, '')))
            for kind, value in steps:
                result = self.pick_decides(value, a, b) if kind == 'pick' else self.order_decides(value, a, b)
                if result is not None:
                    return result
        return self.provider_beats(a, b)

    def winner_of(self, choice, skip=0):
        key, feature = self.keys[choice], self.keys[self.feature(choice)]
        candidates = [p for p in self.offers if choice in self.offers[p]]
        if not candidates:
            return '', 0
        for level in range(1, 7):
            if level == skip:
                continue
            if level in (3, 6):
                order = self.menu_order if level == 3 else self.file_order
                ranked = [(self.rank(order, c), c) for c in candidates if self.rank(order, c) >= 0]
                if ranked:
                    return min(ranked)[1], level
                continue
            pick = ''
            if level == 1 and key != feature:
                pick = self.menu.get(key, '')
            elif level == 2:
                pick = self.menu.get(feature, '')
            elif level == 4 and key != feature:
                pick = self.files.get(key, '')
            elif level == 5:
                pick = self.files.get(feature, '')
            if not pick:
                continue
            if pick == 'vanilla' or (pick not in candidates and self.fall_vanilla):
                return 'vanilla', level
            if pick in candidates:
                return pick, level
        best = candidates[0]
        for candidate in candidates[1:]:
            if self.folder_beats(candidate, best):
                best = candidate
        return best, 7


class AuthorityTests(unittest.TestCase):
    PROVIDERS = ['modAlpha', 'modBeta', 'modGamma', 'modDelta']

    def make(self, rng, keys):
        values = ['', '', '', 'vanilla'] + self.PROVIDERS + ['modGone']
        menu = {key: rng.choice(values) if rng.random() < 0.3 else '' for key in keys}
        files = {key: rng.choice(values) if rng.random() < 0.3 else '' for key in keys}
        orders = ['', '', 'modGamma', 'modDelta,modAlpha', 'modBeta,modGamma,modAlpha']
        offers = {p: {c for c in range(len(keys)) if rng.random() < 0.6} for p in self.PROVIDERS}
        return Authority(keys, menu, files, rng.choice(orders), rng.choice(orders), rng.random() < 0.3, offers)

    def test_the_winner_beats_every_other_offer(self):
        keys = choice_keys()
        rng = random.Random(8)
        pieces = [c for c in range(len(keys)) if keys[c].split('_')[0] not in ('Hidden', 'Drawings')]
        checked = 0
        for _ in range(400):
            model = self.make(rng, keys)
            for choice in rng.sample(pieces, 12):
                winner, level = model.winner_of(choice)
                if winner in ('', 'vanilla'):
                    continue
                for other in model.offers:
                    if other != winner and choice in model.offers[other]:
                        self.assertTrue(model.piece_beats(choice, winner, other),
                                        (keys[choice], winner, other, level))
                        self.assertFalse(model.piece_beats(choice, other, winner))
                        checked += 1
        self.assertGreater(checked, 1000)

    def test_kyles_order_of_authority(self):
        keys = choice_keys()
        icons_quests = keys.index('Icons_Quests')
        offers = {'modAlpha': {icons_quests}, 'modBeta': {icons_quests}, 'modGamma': {icons_quests}}

        def winner(menu=None, files=None, menu_order='', file_order='', fall=False, skip=0):
            return Authority(keys, menu or {}, files or {}, menu_order, file_order, fall, offers).winner_of(
                icons_quests, skip)
        self.assertEqual(winner(), ('modAlpha', 7))
        self.assertEqual(winner(file_order='modGamma'), ('modGamma', 6))
        self.assertEqual(winner(files={'Icons': 'modBeta'}, file_order='modGamma'), ('modBeta', 5))
        self.assertEqual(winner(files={'Icons': 'modBeta', 'Icons_Quests': 'modGamma'}), ('modGamma', 4))
        self.assertEqual(winner(files={'Icons_Quests': 'modGamma'}, menu_order='modBeta'), ('modBeta', 3))
        self.assertEqual(winner(menu={'Icons': 'modGamma'}, menu_order='modBeta'), ('modGamma', 2))
        self.assertEqual(winner(menu={'Icons': 'modGamma', 'Icons_Quests': 'modAlpha'}), ('modAlpha', 1))
        self.assertEqual(winner(menu={'Icons': 'vanilla', 'Icons_Quests': 'modBeta'}), ('modBeta', 1))
        self.assertEqual(winner(menu={'Icons': 'vanilla'}, files={'Icons_Quests': 'modBeta'}), ('vanilla', 2))
        # A chosen mod that is gone (or offers nothing here) passes on, unless the General row says Vanilla.
        self.assertEqual(winner(menu={'Icons': 'modGone'}, file_order='modGamma'), ('modGamma', 6))
        self.assertEqual(winner(menu={'Icons': 'modGone'}, fall=True), ('vanilla', 2))
        # The asking row's own level is left out of its Automatic label.
        self.assertEqual(winner(menu={'Icons': 'modGamma'}, skip=2), ('modAlpha', 7))

    def test_core_rules_match_the_mirror(self):
        text = core_text()
        winner = function_body(text, 'public function WinnerOf(choice : int, skipLevel : int, out level : int) : string')
        for line in ('if (l == 1 && choice != feature)', 'else if (l == 2)', 'else if (l == 4 && choice != feature)',
                     'else if (l == 5)', 'if (l == 3 || l == 6)',
                     'if (pick == "vanilla" || (!candidates.Contains(pick) && fallVanilla))'):
            self.assertIn(line, winner)
        beats = function_body(text, 'public function PieceBeats(choice : int, a : string, b : string) : bool')
        order = [beats.index(s) for s in ('PickDecides(menuChoices[choice]', 'PickDecides(menuChoices[feature]',
                                           'OrderDecides(menuOrder', 'PickDecides(fileChoices[choice]',
                                           'PickDecides(fileChoices[feature]', 'return ProviderBeats(a, b);')]
        self.assertEqual(order, sorted(order))


class MenuAddonTests(unittest.TestCase):
    def test_source_is_up_to_date(self):
        self.assertEqual(addon.MENU.read_text(encoding='utf-8'), addon.menu_xml())
        self.assertEqual(addon.CATALOG.read_text(encoding='utf-8'), addon.catalog_json())

    def test_every_choice_has_one_row(self):
        keys = choice_keys()
        rows = addon.choice_rows()
        self.assertEqual(sorted(rows), sorted(keys))
        wins = [row[1] for _g, _p, _t, page in addon.PAGES for row in page if row[0] == 'win']
        self.assertEqual(len(wins), len(set(wins)))
        for key in wins:
            self.assertIn(key, keys)
        pieces = [k for k in keys[11:] if not re.search(r'_Ignore\d$', k)]
        self.assertEqual(sorted(wins), sorted(pieces + ['Hidden', 'Drawings']))

    def test_menu_file_follows_the_safe_schema(self):
        root = ET.fromstring(addon.menu_xml(probe=True))
        ids = set()
        for group in root.findall('Group'):
            self.assertTrue(group.get('id').startswith('CMFMenu'))
            display = group.get('displayName')
            self.assertNotIn('..', display)
            if group.get('id') != addon.KNOWN_GROUP:
                self.assertTrue(display.startswith('Mods.cmf_menu.'))
                self.assertLessEqual(len(display.split('.')), 4)
            names = [v.get('id') for v in group.iter('Var')]
            self.assertEqual(len(names), len(set(names)))
            for var in group.iter('Var'):
                self.assertNotIn(var.get('id'), ids)
                ids.add(var.get('id'))
                self.assertIsNotNone(var.get('displayName'))
                options = var.findall('OptionsArray/Option')
                if var.get('displayType') == 'OPTIONS':
                    self.assertGreaterEqual(len(options), 2, var.get('id'))
                    for i, option in enumerate(options):
                        self.assertEqual(option.get('id'), str(i))
                        self.assertEqual(option.find('Entry').get('varId'), var.get('id'))
            for var in group.iter('Var'):
                name = var.get('id')
                if name.startswith('CMFPick_'):
                    self.assertIn('CMFName_' + name[8:], names)
                    self.assertEqual(len(var.findall('OptionsArray/Option')), addon.LIVE_CHOICES)
                if re.fullmatch(r'CMFOrder\d', name):
                    self.assertIn('CMFOrderName' + name[8:], names)
        self.assertNotIn('CMFMenuHeadTest', addon.menu_xml())
        self.assertIn('CMFMenuHeadTest', addon.menu_xml(probe=True))
        self.assertNotIn('panel_cmf_headtest', addon.catalog_json())

    def test_every_page_title_has_a_string(self):
        keys = {s['key'] for s in addon.catalog()['strings']}
        for _group, path, _title, _rows in addon.PAGES:
            for segment in path.split('.'):
                self.assertIn('panel_' + segment, keys)
        ids = [s['id'] for s in addon.catalog(probe=True)['strings']]
        self.assertEqual(ids, list(range(addon.ID_BASE + 1, addon.ID_BASE + 1 + len(ids))))
        self.assertTrue(all(2000200100 < i < 2000201000 for i in ids))


class MenuScriptTests(unittest.TestCase):
    def script(self):
        return MENU_WS.read_text(encoding='ascii')

    def test_script_is_ascii_and_names_only_its_own_pages(self):
        text = self.script()
        groups = {g for g, _p, _t, _r in addon.PAGES} | {addon.KNOWN_GROUP}
        for literal in set(re.findall(r"'(CMF\w+)'", text)):
            if literal.startswith('CMFMenu'):
                self.assertIn(literal, groups)
        for literal in ('CMFFallthrough', 'CMFReset', 'CMFReport'):
            self.assertIn("'%s'" % literal, text)

    def test_group_of_each_key_matches_the_pages(self):
        body = function_body(self.script(), 'function CMFMenuGroupOf(key : string) : name')
        tests = re.findall(r'if \((.*?)\)\n\t\{\n\t\treturn \'(\w+)\';', body)

        def mirror(key):
            for condition, group in tests:
                if condition == 'StrFindFirst(key, "_") < 0':
                    if '_' not in key:
                        return group
                    continue
                if any(key.startswith(p) for p in re.findall(r'StrBeginsWith\(key, "([^"]+)"\)', condition)):
                    return group
            return ''
        pages = {}
        for group, _path, _title, rows in addon.PAGES:
            for row in rows:
                if row[0] == 'pick':
                    pages[row[1]] = group
        for key, group in pages.items():
            self.assertEqual(mirror(key), group, key)
        listed = re.findall(r"groups\.PushBack\('(\w+)'\);",
                            function_body(self.script(), 'function CMFMenuChoiceGroups() : array<name>'))
        self.assertEqual(sorted(listed), sorted(set(pages.values())))

    def test_hand_over_reads_settings_only(self):
        body = function_body(self.script(), '@wrapMethod(CMFCore) function ReadMenuChoices()')
        self.assertTrue(body.lstrip().startswith('var') and 'wrappedMethod();' in body)
        for call in ('Providers(', 'WinnerOf(', 'Prepare(', 'AllowedCount(', 'GetRevision(', 'CMFGetCore('):
            self.assertNotIn(call, body)
        for call in ('SetMenuChoice(', 'SetMenuOrder(', 'SetMenuFallthrough(', 'SetMenuReport('):
            self.assertIn(call, body)

    def test_rows_never_offer_more_choices_than_declared(self):
        text = self.script()
        self.assertEqual(text.count('answers.Size() < %d' % addon.LIVE_CHOICES), 2)
        self.assertEqual(text.count('CMFMenuPlaceStored(stored, labels, answers, %d, providers)' % addon.LIVE_CHOICES), 2)

    def test_page_builder_is_scoped(self):
        body = function_body(self.script(), '@wrapMethod function IngameMenu_FillSubMenuOptionsList(flashStorageUtility : '
                             'CScriptedFlashValueStorage, groupID : int,\n\tgroupName : name, groupRootObject : '
                             'CScriptedFlashObject) : bool')
        self.assertIn('result = wrappedMethod(flashStorageUtility, groupID, groupName, groupRootObject);', body)
        self.assertIn('StrBeginsWith(NameToString(groupName), "CMFMenu")', body)


    def test_long_names_keep_their_brackets(self):
        text = self.script()
        body = function_body(text, 'function CMFMenuFit(before : string, modName : string, after : string) : string')
        self.assertIn('room = 32 - StrLen(before) - StrLen(after);', body)
        self.assertIn('space = StrFindLast(shown, " ");', body)

        def fit(before, name, after):
            room = 32 - len(before) - len(after)
            if len(name) <= room or room < 6:
                return before + name + after
            while len(name) > room - 3:
                space = name.rfind(' ')
                name = name[:room - 3] if space <= 0 else name[:space]
            return before + name + '...' + after
        self.assertEqual(fit('', 'Test Minimap Checks', ' (Folder order)'), 'Test Minimap... (Folder order)')
        self.assertEqual(fit('', 'Gwent Players Map', ' (Folder order)'), 'Gwent Players Map (Folder order)')
        # The last level reads "Default", so the names seen in menu launch 2 fit whole.
        level = function_body(core_text(), 'public function LevelName(level : int) : string')
        self.assertIn('return "Default";', level)
        self.assertNotIn('Folder order', level)
        for name in ('Coloured Map Marker', 'Test Minimap Checks', 'Example Icon Pack', 'Map Quest Insight'):
            self.assertEqual(fit('', name, ' (Default)'), name + ' (Default)')
        self.assertEqual(fit('Automatic (', 'Supercalifragilisticexpialidocious', ')'), 'Automatic (Supercalifragilis...)')
        for name in ('A B C D E F G H I J K L M N O P Q R S', 'x' * 60, 'Map Quest Insight Extended Edition'):
            for before, after in (('', ' (Advanced file)'), ('Automatic (', ')'), ('', ' (not loaded)'), ('', '')):
                self.assertLessEqual(len(fit(before, name, after)), 32)
        # Every mod name shown in a value column goes through it.
        self.assertNotIn('"Automatic (" + core.ProviderName', text)
        self.assertNotIn('core.ProviderName(winner) + " ("', text)
        self.assertNotIn('labels.PushBack(core.ProviderName(', text)

    def test_no_offered_by_line_and_no_headings_on_basic(self):
        # Kyle 2026-10-22 (menu launches 3 to 5): no route showed a per-row "which mods" line well, so it is cut
        # everywhere; Basic keeps no headings, so the game draws no jump list beside it.
        text = self.script()
        for gone in ('OnOptionSelectionChanged', 'm_fxUpdateOption', 'force_update_values', '"description"', 'CMFInfo_'):
            self.assertNotIn(gone, text)
        root = ET.fromstring(addon.menu_xml())
        for var in root.iter('Var'):
            self.assertFalse(var.get('id', '').startswith('CMFInfo_'))
            self.assertNotEqual(var.get('displayType'), 'SUBTLE_SEPARATOR')
        # Headings stay only where they carry text found nowhere else (Mod order's meaning, the loaded-mods count);
        # the choice pages are plain lists (Kyle 2026-10-22 06:26Z and 06:41Z).
        for group, _p, _t, rows in addon.PAGES:
            if any(row[0] == 'pick' for row in rows):
                self.assertEqual({row[0] for row in rows}, {'pick'}, group)

    def test_stored_pick_of_a_loaded_mod_says_offers_none(self):
        body = function_body(self.script(), 'function CMFMenuPlaceStored(stored : string, out labels : array<string>, out answers : array<string>, room : int,\n\tproviders : array<string>) : int')
        self.assertIn('after = " (offers none)";', body)
        self.assertIn('after = " (not loaded)";', body)

if __name__ == '__main__':
    unittest.main()
