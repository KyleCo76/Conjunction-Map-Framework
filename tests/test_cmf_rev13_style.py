"""Revision 13 item style contracts and executable target grammar; no panel/runtime claims."""
import sys
import unittest
from pathlib import Path
from test_cmf_review_bundle import body
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tools"))
import cmf_pack as pack

class Rev13StyleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core=(ROOT/"source/core/content/scripts/local/cmfCore.ws").read_text()

    def test_target_grammar(self):
        valid=[("legendRow","NoticeBoard","color"),("legendTab","Quests","color"),
               ("legendTab","id:0","color"),("legendTab","id:002","color"),
               ("tooltip","NoticeBoard","titleColor"),("tooltip","type:NoticeBoard","titleColor"),
               ("tooltip","tag:modP.sample","titleColor"),("pinLabel","tag:modP.sample","size"),
               ("title","no_mans_land","text"),("worldHint","","text"),("legend","","allText")]
        invalid=[("legendRow","type:NoticeBoard","color"),("legendTab","id:-1","color"),
                 ("legendTab","id:","color"),("legendTab","id:2x","color"),("legendTab","tag:x","color"),
                 ("tooltip","type:","titleColor"),("tooltip","tag:","titleColor"),
                 ("tooltip","id:2","titleColor"),("title","no_mans_land","size"),
                 ("hints","anything","list"),("legend","Quests","allText"),("worldHint","x","text")]
        for part,target,key in valid:
            with self.subTest(valid=(part,target,key)): self.assertEqual(pack.item_style_issues(part,target,key),[])
        for part,target,key in invalid:
            with self.subTest(invalid=(part,target,key)): self.assertTrue(pack.item_style_issues(part,target,key))

    def test_empty_target_uses_existing_call_and_only_three_exports_planned(self):
        fn=body(self.core,"CMFStyle")
        self.assertIn("return CMFStylePart(provider, part, key, text, number)",fn)
        self.assertLess(fn.index("ItemTarget("), fn.index("UpsertItemStyle("))
        self.assertIn("CMFStyle",pack.API)
        self.assertIn("CMFStyle",pack.VERSION13)

    def test_item_identity_noop_unset_and_release(self):
        fn=body(self.core,"UpsertItemStyle")
        for field in ("provider","target","item","itemKind","key"):
            self.assertIn("itemStyles[i]."+field+" == styleEntry."+field,fn)
        self.assertIn('styleEntry.text == "unset"',fn)
        self.assertIn("itemStyles[i].number == styleEntry.number",fn)
        self.assertLess(fn.index("itemStyles[i].number == styleEntry.number"),fn.index("itemStyles[i] = styleEntry"))
        self.assertIn("itemStyles.Erase(i)",body(self.core,"ReleaseProvider"))
        self.assertIn("PrepareItemStyles()",body(self.core,"Prepare"))

    def test_separate_wire_and_cache(self):
        send=body(self.core,"SendItemStyles")
        self.assertIn('"cmf.map.itemStyles"',send)
        for key in ("p","q","t","y","s","n","o"): self.assertIn('"'+key+'"',send)
        self.assertIn("itemStyleOwners[i]",send)
        self.assertNotIn("ItemStyleOwner(",send)
        owner=body(self.core,"ItemStyleOwner")
        self.assertIn("ChoiceOnlySkips",owner)
        self.assertIn('answer == "vanilla"',owner)
        self.assertIn("fallVanilla",owner)

    def test_list_offer_has_own_owner_and_no_legacy_write(self):
        owner=body(self.core,"HintListOwner")
        self.assertIn("return hintListPreparedOwner",owner)
        value=body(self.core,"CMFThemeValueOk")
        self.assertIn("part == 'hints' && key == 'list'",value)
        self.assertIn("number == 1",value)
        self.assertNotIn('SetFlashArray("cmf.map.hints"',self.core)



    def test_item_only_provider_choice_canonicalization(self):
        self.assertIn("itemStyles[i].provider",body(self.core,"CanonicalProvider"))
        self.assertIn("itemStyles[i].provider",body(self.core,"PrepareOffers"))

    def test_checker_calls_and_compile_floor_even_with_wrong_guard(self):
        for guard in ("", 'CMFRequireVersion("modP", 2);', 'CMFHasAbility(\'tooltip\', \'titleColor\');'):
            report=pack.Report()
            pack.check_script("test.ws",guard+'CMFStyle("modP", \'tooltip\', \'tag:modP.pin\', \'titleColor\', "", 0);',
                              "modP",report,[],set())
            self.assertEqual(report.errors,[])
            self.assertTrue(any("compiles only with CMF API 13" in n for n in report.notes))
        report=pack.Report()
        pack.check_script("test.ws",'CMFStyle("modP", \'tooltip\', \'id:2\', \'titleColor\', "", 0);',
                          "modP",report,[],set())
        self.assertTrue(any("invalid per-item target" in e for e in report.errors))


    def test_hint_owner_prepared_not_rescanned_on_each_opening(self):
        self.assertNotIn("ThemeStyleOwner(",body(self.core,"HintListOwner"))
        self.assertIn("hintListPreparedOwner = ThemeStyleOwner('hints', 'list')",body(self.core,"PrepareItemStyles"))
