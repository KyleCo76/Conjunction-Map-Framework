"""CMF's own movement (1.0.0): 60 frames a second and time-based movement when no folder sets them.

Reads cmfCore.ws and the panel edits as text; only a launch proves the map honours the values.
"""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
OWN = {'frameRate': 60, 'frameTimed': 1, 'zoomTimed': 1, 'tweenEveryFrame': 1}


def method(code, name):
    start = code.index('function ' + name + '(')
    end = code.index('\n\t}\n', start)
    return code[start:end]


class OwnMotion(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding='utf-8')
        cls.send = method(cls.core, 'SendDefaultMotion')
        cls.theme = method(cls.core, 'SendTheme')

    def test_sends_the_four_keys(self):
        self.assertEqual(re.findall(r"keys\.PushBack\('(\w+)'\);", self.send), list(OWN))

    def test_values(self):
        value = self.core[self.core.index('function CMFDefaultNavigationValue('):]
        value = value[:value.index('\n}\n')]
        self.assertIn("if (key == 'frameRate')\n\t{\n\t\treturn 60;\n\t}\n\treturn 1;", value)

    def test_values_are_in_range(self):
        ok = self.core[self.core.index('function CMFThemeMotionValueOk('):]
        self.assertIn("case 'frameRate':\n\t\t\treturn number >= 24 && number <= 60;", ok)
        for key in ('zoomTimed', 'tweenEveryFrame'):
            self.assertIn("case '%s':" % key, ok[:ok.index('return number == 0 || number == 1;')])

    def test_any_folder_wins(self):
        self.assertIn("if (ThemeStyleOwner('navigation', keys[i]) != \"\")\n\t\t\t{\n\t\t\t\tcontinue;", self.send)

    def test_sent_as_navigation_style(self):
        for text in ('SetMemberFlashInt("k", 1);', 'SetMemberFlashString("t", "navigation");',
                     'SetMemberFlashString("y", NameToString(keys[i]));',
                     'SetMemberFlashNumber("n", CMFDefaultNavigationValue(keys[i]));',
                     'flashArray.PushBackFlashObject(item);'):
            self.assertIn(text, self.send)

    def test_after_the_folders_and_before_the_map_gets_the_list(self):
        own = self.theme.index('ownMotion = SendDefaultMotion(storage, flashArray);')
        self.assertLess(self.theme.index('for (i = 0; i < themeEntries.Size(); i += 1)'), own)
        self.assertLess(own, self.theme.index('storage.SetFlashArray("cmf.map.theme", flashArray);'))
        self.assertIn('" cmfMotion=" + ownMotion', self.theme)

    def test_logged(self):
        self.assertIn('NoteTheme("theme default part=navigation key=" + NameToString(keys[i]) + " value=" +', self.send)

    def test_panel_reads_them(self):
        edits = json.dumps(json.loads(EDITS.read_text(encoding='utf-8')))
        for text in ('MapMenu.cmfNum(\\"navigation\\",\\"frameTimed\\",0)',
                     'MapMenu.cmfNum(\\"navigation\\",\\"zoomTimed\\",0)',
                     'MapMenu.cmfNum(\\"navigation\\",\\"tweenEveryFrame\\",0)',
                     'MapMenu.cmfHas(\\"navigation\\",\\"frameRate\\")'):
            self.assertIn(text, edits)


if __name__ == '__main__':
    unittest.main()
