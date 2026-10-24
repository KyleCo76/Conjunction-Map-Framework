"""Menu add-on 1.4.0: a plain description of every row in the Options list's help box, description first, then a
choice row's "Offered by" line (plans/2026-10-24-cmf-menu-descriptions.md sections 3 and 4).

Static checks of source/menu/descriptions.json, the menu file and cmfMenu.ws; no game files.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_menu_addon as addon

MENU_WS = ROOT/'source/menu/content/scripts/local/cmfMenu.ws'


def visible_vars():
    xml = addon.menu_xml()
    found = []
    for match in re.finditer(r'<Var id="([^"]+)"([^>]*)>', xml):
        var, rest = match.groups()
        if 'hideAlways' in rest or var.startswith('CMFHead_'):
            continue
        found.append(var)
    return found


def described(var):
    for key, text in addon.descriptions():
        if key == var or (key.endswith('*') and var.startswith(key[:-1])):
            return text
    return ''


class DescriptionTests(unittest.TestCase):
    def test_every_visible_row_has_a_description(self):
        missing = [var for var in visible_vars() if not described(var)]
        self.assertEqual(missing, [])

    def test_every_description_names_a_real_row(self):
        names = set(visible_vars())
        for key, _text in addon.descriptions():
            if key.endswith('*'):
                self.assertTrue(any(n.startswith(key[:-1]) for n in names), key)
            else:
                self.assertIn(key, names)

    def test_lengths_and_wording(self):
        for key, text in addon.descriptions():
            self.assertLessEqual(len(text), addon.DESCRIPTION_MAX, key)
            self.assertTrue(text.isascii(), key)
            self.assertNotIn('"', text, key)
            self.assertFalse(re.search(r'\bChoose\b', text), key)
            self.assertFalse(re.search(r'mod0|modCMF|Adapter', text), key)

    def test_script_block_is_written_from_the_json(self):
        self.assertEqual(MENU_WS.read_text(encoding='utf-8'), addon.script_text())
        self.assertTrue(addon.up_to_date())

    def test_choice_rows_put_the_description_first(self):
        text = MENU_WS.read_text(encoding='utf-8')
        self.assertIn('RememberHelp(varName, CMFMenuBoxText(varName, CMFMenuHelpText(', text)
        self.assertIn('return CMFMenuDescription(varName) + CMFMenuLineBreak() + helpLine;', text)

    def test_every_cmf_row_shows_the_box(self):
        text = MENU_WS.read_text(encoding='utf-8')
        self.assertIn('if (StrBeginsWith(NameToString(optionName), "CMF") && menuState.Help(optionName, text) && '
                      'text != "")', text)
        self.assertIn('if (!StrBeginsWith(varText, "CMFPick_") && CMFMenuDescription(varName) != "")', text)

    def test_box_moves_off_the_list_and_back(self):
        text = MENU_WS.read_text(encoding='utf-8')
        place = text[text.index('function CMFMenuPlaceBox('):]
        place = place[:place.index('\n}\n')]
        for part in ('GetChildFlashSprite("mcOptionListModule")', 'GetChildFlashSprite("tooltip")',
                     'GetChildFlashSprite("mcOptionList")', 'SetBoxHome(box.GetY())', 'box.SetY(home)',
                     'field.SetMemberFlashNumber("height", field.GetMemberFlashNumber("textHeight") + '):
            self.assertIn(part, place)
        self.assertEqual(text.count('CMFMenuPlaceBox(m_flashModule, true)'), 1)
        self.assertEqual(text.count('CMFMenuPlaceBox(m_flashModule, false)'), 2)

    def test_version(self):
        self.assertEqual(addon.VERSION, '1.4.0')


if __name__ == '__main__':
    unittest.main()
