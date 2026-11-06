"""CMF menu add-on: a Status row shows its value in the LABEL ("<row name>: <value>") and leaves "current" empty, because Ink and
Iron's options menu redraws BUTTON rows without the text on the right. The model mirrors CMFMenuLabelWith; nothing ran in the game.
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WS = (ROOT / 'source/menu/content/scripts/local/cmfMenu.ws').read_text(encoding='utf-8')
XML = (ROOT / 'source/menu/modCMFInGameMenu.xml').read_text(encoding='utf-8')
ROOM = 70


def body(name):
    m = re.search(r'function ' + re.escape(name) + r'\(', WS)
    start = WS.index('{', m.start())
    depth = 0
    for i in range(start, len(WS)):
        depth += WS[i] == '{'
        depth -= WS[i] == '}'
        if depth == 0:
            return WS[m.start():i + 1]


def fit_to(limit, before, name, after):
    room = limit - len(before) - len(after)
    if len(name) <= room or room < 6:
        return before + name + after
    while len(name) > room - 3:
        space = name.rfind(' ')
        name = name[:room - 3] if space <= 0 else name[:space]
    return before + name + '...' + after


def label_with(label, text):
    if label == '':
        return text
    sep = ' - ' if ': ' in label else ': '
    room = ROOM - len(label) - len(sep)
    if len(text) <= room or room < 10:
        return label + sep + text
    head, tail = text, ''
    cut = text.rfind(' (')
    if cut > 0 and len(text) - cut < room - 6:
        head, tail = text[:cut], text[cut:]
    return label + sep + fit_to(room, '', head, tail)


class Model(unittest.TestCase):
    def test_the_usual_rows(self):
        self.assertEqual(label_with('Map size, position and backdrop', 'Ink and Iron (Default)'), 'Map size, position and backdrop: Ink and Iron (Default)')
        self.assertEqual(label_with('Quests', 'Vanilla (none loaded)'), 'Quests: Vanilla (none loaded)')
        self.assertEqual(label_with('Quests', 'Open the map once to see'), 'Quests: Open the map once to see')

    def test_the_screen_row_does_not_double_the_colon(self):
        self.assertEqual(label_with('Screen: 21:9', 'Map fills it (CMF)'), 'Screen: 21:9 - Map fills it (CMF)')

    def test_the_row_name_stays_whole_and_the_total_fits(self):
        longest = 'General (signposts, boards, stash, Roach)'
        for value in ('Ink and Iron (Default)', 'Map Quest Insight Extended Edition (Default)', 'x' * 60 + ' (Advanced file)', 'Load a save to see'):
            out = label_with(longest, value)
            self.assertTrue(out.startswith(longest + ': '), out)
            self.assertLessEqual(len(out), ROOM, out)
        # a level in brackets is kept when the name gives way
        self.assertTrue(label_with(longest, 'Map Quest Insight Extended Edition (Default)').endswith('(Default)'))

    def test_longest_real_labels_are_known(self):
        rows = re.findall(r'<Var id="CMF(?:Win|Status)[A-Za-z0-9_]*" value="[^"]*" displayName="([^"]*)" displayType="BUTTON"', XML)
        self.assertTrue(rows)
        self.assertEqual(max(len(r) for r in rows), 41)      # "General (signposts, boards, stash, Roach)"
        self.assertEqual(label_with('General (signposts, boards, stash, Roach)', 'Ink and Iron (Default)'), 'General (signposts, boards, stash, Roach): Ink and Iron (Default)')
        self.assertEqual(len('General (signposts, boards, stash, Roach): Ink and Iron (Default)'), 65)


class Row:
    """A flash row: label plus the members the script keeps."""

    def __init__(self, label):
        self.m = {'label': label}

    def get(self, k):
        return self.m.get(k, '')

    def set(self, k, v):
        self.m[k] = v


def base_name(row):
    base = row.get('cmfBase')
    if base == '' or base == 'undefined':
        base = row.get('label')
        row.set('cmfBase', base)
    return base


def set_value(row, text):
    row.set('label', label_with(base_name(row), text))
    row.set('current', '')


def set_base(row, name):
    row.set('cmfBase', name)
    row.set('label', name)


class Refill(unittest.TestCase):
    def test_a_second_fill_of_the_same_row_gives_one_value(self):
        row = Row('Map size, position and backdrop')
        set_value(row, 'Ink and Iron (Default)')
        set_value(row, 'Vanilla (Default)')
        self.assertEqual(row.get('label'), 'Map size, position and backdrop: Vanilla (Default)')
        set_value(row, 'Open the map once to see')
        self.assertEqual(row.get('label'), 'Map size, position and backdrop: Open the map once to see')
        self.assertEqual(row.get('current'), '')

    def test_the_screen_row_name_has_a_colon_and_still_gives_one_value(self):
        row = Row('Screen')
        set_base(row, 'Screen: 21:9')
        set_value(row, 'Map fills it (CMF)')
        set_base(row, 'Screen: 21:9')
        set_value(row, '16:9 map (Vanilla)')
        self.assertEqual(row.get('label'), 'Screen: 21:9 - 16:9 map (Vanilla)')
        set_base(row, 'Screen: 16:9')          # the screen changed: the new name wins
        set_value(row, '16:9 map (Vanilla)')
        self.assertEqual(row.get('label'), 'Screen: 16:9 - 16:9 map (Vanilla)')

    def test_a_row_the_code_names_each_fill(self):
        row = Row('Map mod 1')
        set_base(row, 'Ink and Iron')
        set_value(row, 'Size, Colours')
        set_base(row, 'Ink and Iron')
        set_value(row, 'Size, Colours, Legend')
        self.assertEqual(row.get('label'), 'Ink and Iron: Size, Colours, Legend')


class Source(unittest.TestCase):
    def test_set_value_writes_the_label_and_leaves_current_empty(self):
        s = body('CMFMenuSetValue')
        self.assertIn('row.SetMemberFlashString("label", CMFMenuLabelWith(CMFMenuBaseName(row), text));', s)
        self.assertIn('row.SetMemberFlashString("current", "");', s)
        self.assertIn('row.SetMemberFlashString("startingValue", "");', s)
        self.assertIn('row.SetMemberFlashBool("disabled", disabled);', s)

    def test_label_with_text(self):
        s = body('CMFMenuLabelWith')
        for part in ('room = 70 - StrLen(label) - StrLen(sep);', 'sep = " - ";', 'cut = StrFindLast(text, " (");',
                     'return label + sep + CMFMenuFitTo(room, "", head, tail);', 'if (StrLen(text) <= room || room < 10)'):
            self.assertIn(part, s)

    def test_every_status_call_goes_through_set_value(self):
        self.assertEqual(WS.count('CMFMenuSetValue(row,'), 4)
        # the fallbacks stay
        for text in ('Open the map once to see', 'Load a save to see', 'Vanilla (none loaded)', 'Nothing yet (open the map)'):
            self.assertIn(text, WS)

    def test_base_name_source(self):
        b = body('CMFMenuBaseName')
        self.assertIn('base = row.GetMemberFlashString("cmfBase");', b)
        self.assertIn('if (base == "" || base == "undefined")', b)
        self.assertIn('row.SetMemberFlashString("cmfBase", base);', b)
        s = body('CMFMenuSetBase')
        self.assertIn('row.SetMemberFlashString("cmfBase", baseName);', s)
        self.assertIn('row.SetMemberFlashString("label", baseName);', s)

    def test_callers_that_name_a_row_use_set_base(self):
        self.assertEqual(WS.count('CMFMenuSetBase(row,'), 6)
        self.assertIn('CMFMenuSetBase(row, "Screen: " + CMFMenuAspectText(width, height));', WS)
        self.assertIn('CMFMenuSetBase(row, core.ProviderName(providers[index]));', WS)
        self.assertNotIn('row.SetMemberFlashString("label", "Screen: ', WS)

    def test_the_choice_rows_still_use_their_own_current(self):
        self.assertIn('row.SetMemberFlashString("current", IntToString(current));', body('CMFMenuSetChoices'))

    def test_compile_audit(self):
        for n in ('CMFMenuSetValue', 'CMFMenuBaseName', 'CMFMenuSetBase', 'CMFMenuLabelWith', 'CMFMenuFitTo', 'CMFMenuFit'):
            b = body(n)
            self.assertEqual(b.count('{'), b.count('}'), n)
            self.assertNotIn('?', b.replace('"?"', ''), n)
        self.assertEqual(WS.count('function CMFMenuFitTo('), 1)


if __name__ == '__main__':
    unittest.main()


class NoTypeNamedVariables(unittest.TestCase):
    """A parameter or local named like a WitcherScript type (name, string, int, ...) is a compile risk."""

    def test_no_parameter_or_var_named_like_a_type(self):
        import re
        bad = re.compile(r'(?:[(,]|\bvar)\s*(name|string|int|float|bool|array|struct|class|state|event)\s*:')
        hits = [m.group(0) for m in bad.finditer(WS)]
        self.assertEqual(hits, [], 'type word used as a variable or parameter name: %s' % hits)
