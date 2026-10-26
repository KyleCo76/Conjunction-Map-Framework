"""API13 hook wiring and owned-channel contracts (offline)."""
from pathlib import Path
import re
import unittest
from test_cmf_review_bundle import body
ROOT=Path(__file__).resolve().parents[1]

class Rev13HookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core=(ROOT/"source/core/content/scripts/local/cmfCore.ws").read_text()
    def test_new_events_and_chainable_hooks(self):
        for name,signature in (("OnCMFMapTab","category : string"),("OnCMFMapHints","")):
            self.assertEqual(len(re.findall(r"@addMethod\(CR4MapMenu\)\s*event "+name+r"\("+re.escape(signature)+r"\)",self.core)),1)
        self.assertIn("OnMapTab(this, category)",self.core)
        self.assertIn("MapHintsReady(this)",self.core)
        self.assertEqual(body(self.core,"OnMapTab").strip(),"")
        self.assertEqual(body(self.core,"OnMapHints").strip(),"")
        for name in ("OnCMFMapFilter","OnCMFMapHintsReady"):
            self.assertNotRegex(self.core,r"(?:function|event)\s+"+name+r"\s*\(")
    def test_only_new_event_dispatches_owned_hints(self):
        self.assertEqual(self.core.count("MapHintsReady(this)"),1)
        self.assertEqual(self.core.count("OnMapHints(menu, owner)"),1)
        for callback in ("OnMapReady","BeginBuild","SendTheme"):
            self.assertNotIn("MapHintsReady(",body(self.core,callback))
    def test_owned_channel_no_readback_or_legacy_mutation(self):
        fn=body(self.core,"MapHintsReady")
        self.assertIn('owner == "" && hintListOwnerSent == ""',fn)
        self.assertLess(fn.index('owner == "" && hintListOwnerSent == ""'),fn.index("CreateTempFlashArray"))
        self.assertIn('SetMemberFlashString("owner", owner)',fn)
        self.assertIn('SetFlashArray("cmf.map.hints.owned",',fn)
        self.assertNotIn('SetFlashArray("cmf.map.hints",',self.core)
        self.assertNotIn("GetFlashArray",self.core)
        self.assertIn("hintListOwnerSent = owner",fn)
    def test_author_examples_chain_once_and_gate_owner(self):
        guide=(ROOT/"docs/authors/icon-pack-guide.md").read_text()
        start=guide.index("**Revision 13 hooks**")
        end=guide.index("### The map theme",start)
        section=guide[start:end]
        self.assertEqual(section.count("wrappedMethod(menu, category);"),1)
        self.assertEqual(section.count("wrappedMethod(menu, owner);"),1)
        self.assertIn('owner != "modMyPack"',section)
        self.assertIn("available from API version 13",section)
        self.assertNotIn("inert until",section)
        self.assertIn("OnMapHints(menu, owner)",self.core)

