"""API13 choice contracts: source and generated-menu checks, not engine tests."""
import json
from pathlib import Path
import re
import sys
import unittest
from test_cmf_review_bundle import body

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import cmf_menu_addon as menu

BASE = ("Icons,Colours,Size,Labels,Clicks,Legend,Hidden,Look,Movement,Painting,Drawings,"
        "Icons_General,Icons_Quests,Icons_Places,Icons_Completed,Icons_Services,Icons_Power,Icons_Other,Icons_Added,"
        "Colours_General,Colours_Quests,Colours_Places,Colours_Completed,Colours_Services,Colours_Power,Colours_Other,"
        "Colours_Added,Size_Scale,Size_Lead,Size_Spread,Labels_Text,Labels_Place,Clicks_Pins,Legend_Rows,Legend_Names,"
        "Legend_Tabs,Hidden_Ignore1,Hidden_Ignore2,Hidden_Ignore3,Look_Frames,Look_Legend,Look_InfoBox,Look_Hints,"
        "Look_PinText,Movement_Area,Movement_Pan,Movement_Opening,Painting_WhiteOrchard,Painting_WhiteOrchardWinter,"
        "Painting_Velen,Painting_Skellige,Painting_KaerMorhen,Painting_Vizima,Painting_IsleOfMists,Painting_Spiral,"
        "Painting_Toussaint,Drawings_Ignore1,Drawings_Ignore2,Drawings_Ignore3,Painting_World,Painting_Crests,"
        "Movement_View,Behaviour,Behaviour_InfoBoxDodge,Behaviour_InfoBoxHeight,Movement_ZoomOut,Movement_Controller,"
        "Behaviour_HoverNames,Movement_Wide,Reserved69,Icons_Undiscovered,Look_InfoText").split(",")
ADDED = ["Behaviour_InfoBoxMotion", "Look_Sounds", "Behaviour_InfoFold", "Behaviour_PanelModes",
         "Look_Badges", "Look_PinLook", "Size_Place", "Behaviour_PinZoom"]

class Rev13ChoiceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = (ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")
        cls.keys = "".join(re.findall(r'"([^"]*)"', body(cls.core, "CMFChoiceKeys"))).split(",")

    def test_existing_positions_0_to_71_unchanged(self):
        self.assertEqual(self.keys[:72], BASE)
        self.assertEqual(len(self.keys), 80)
        self.assertEqual(body(self.core, "CMFChoiceParent").count("return 62;"), 1)

    def test_exact_append_72_to_79(self):
        self.assertEqual(self.keys[72:], ADDED)
        self.assertNotIn("Look_Pins", self.keys)

    def test_empty_parent_table_is_inert(self):
        self.assertRegex(body(self.core, "PieceParentTable"), r'return\s+"";')
        resolver = body(self.core, "ResolvePieceParents")
        self.assertLess(resolver.index('if (table == "")'), resolver.index("menuChoices[i] ="))
        read = body(self.core, "ReadChoices")
        self.assertLess(read.index("ReadMenuChoices();"), read.index("ResolvePieceParents();"))
        self.assertLess(read.index("ResolvePieceParents();"), read.index("DecideChoice(i, level)"))

    def test_parent_same_tier_and_automatic(self):
        resolver = body(self.core, "ResolvePieceParents")
        self.assertIn('menuChoices[i] == ""', resolver)
        self.assertIn('fileChoices[i] == ""', resolver)
        self.assertIn("menuChoices[i] = rawMenu[cursor]", resolver)
        self.assertIn("fileChoices[i] = rawFile[cursor]", resolver)
        self.assertLess(resolver.index("seen.Contains(cursor)"), resolver.index("menuChoices[i] ="))
        self.assertIn("childIndex == parentIndex", resolver)
        settings = (ROOT / "source/core/content/scripts/local/cmfSettings.ws").read_text(encoding="utf-8")
        self.assertIn('lowered == "-1"', body(settings, "CMFSettingsChoiceValue"))

    def test_generated_rows_preserve_ids(self):
        picks = menu.choice_rows()
        wins = [r[1] for _, _, _, rows in menu.PAGES for r in rows if r[0] == "win"]
        descriptions = dict(menu.descriptions())
        for key in ADDED:
            self.assertEqual(picks.count(key), 1, key)
            self.assertEqual(wins.count(key), 1, key)
            self.assertTrue(descriptions.get("CMFPick_" + key), key)
        actual = menu.catalog()
        self.assertEqual([x["id"] for x in actual["strings"]], list(range(2000200101, 2000200128)))
        self.assertEqual(menu.VERSION, "1.5.0")
        self.assertTrue(menu.up_to_date())


    def test_file_tier_registers_each_appended_key(self):
        xml=(ROOT / "source/settings/menus/mod0000_ConjunctionMapFramework.xml").read_text()
        for key in ADDED:
            self.assertEqual(xml.count('id="CMFFile_'+key+'"'),1)
