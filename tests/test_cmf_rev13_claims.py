"""API13 claims: executable pack validation and offline core wiring contracts."""
import sys
import unittest
from pathlib import Path
from test_cmf_review_bundle import body
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import cmf_pack as pack

class Rev13ClaimsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = (ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")

    def test_property_allocation(self):
        self.assertTrue(set(range(31, 37)) | {40,41,42,43,44} <= pack.KNOWN_PROPERTIES)
        self.assertIn(39, pack.KNOWN_PROPERTIES)
        self.assertTrue(set(range(31,37)) | {42,43,44} <= pack.ONE_PIN_PROPERTIES)
        self.assertNotIn(41, pack.ONE_PIN_PROPERTIES)

    def test_value_boundaries(self):
        valid = [(31,"frame:selected",0),(42,"img://icons/p/a.png",0),
                 (32,"",25),(32,"",400),(33,"",0),(33,"",100),(34,"",-1000),(34,"",1000),
                 (35,"-50,50",0),(35," 0 , -0.5 ",0),(36,"-100000,100000",0),
                 (36,"0,0",0),(41,"",0),(43,"",16777215),(44,"",25),(44,"",400)]
        invalid = [(31,"",0),(42,"frame:",0),(31,"https://x",0),(32,"",24),(32,"",401),
                   (33,"",-1),(33,"",101),(34,"",-1001),(34,"",1001),(35,"-50.1,0",0),
                   (35,"0,0,0",0),(36,"2,1",0),(36,"NaN,3",0),(36,"0,inf",0),
                   (36,"0,1e999",0),(41,"",-1),(43,"",16777216),(44,"",24),(44,"",401)]
        for prop,text,number in valid:
            with self.subTest(valid=(prop,text,number)):
                self.assertEqual(pack.rev13_property_issues(prop,text,number), [])
        for prop,text,number in invalid:
            with self.subTest(invalid=(prop,text,number)):
                self.assertTrue(pack.rev13_property_issues(prop,text,number))

    def test_withdraw_exact_slot_and_noop(self):
        upsert = body(self.core,"Upsert")
        self.assertLess(upsert.index("WithdrawClaim(incoming)"), upsert.index("CMFParseExemptions"))
        withdraw = body(self.core,"WithdrawClaim")
        self.assertIn("claims[i].provider == incoming.provider && SameSlot(claims[i], incoming)",withdraw)
        self.assertLess(withdraw.index("claims.Erase(i)"),withdraw.index("dirty = true"))
        self.assertLess(withdraw.index("dirty = true"),withdraw.index('Report("withdrawn", incoming)'))
        self.assertEqual(withdraw.count("dirty = true"),1)
        slot = body(self.core,"SameSlot")
        for field in ("propertyId","level","pinType","pinTag","mapContext","placeX","placeY"):
            self.assertIn(f"a.{field} == b.{field}",slot)
        target = body(self.core,"ClaimTargetOk")
        for token in ("38","40","level == 0","level == 2","CMFLevelPlace()","mapContext"):
            self.assertIn(token,target)

    def test_label_hides_union_registered_and_direct(self):
        prepare = body(self.core,"Prepare")
        self.assertIn("labelHideClaims.PushBack(claims[i])",prepare)
        self.assertIn("NoteLookupClaim(labelHideClaims[i])",body(self.core,"NoteLookups"))
        self.assertIn("WriteLabelHides(",body(self.core,"WritePinFields"))
        self.assertIn("WriteLabelHides(",body(self.core,"FillMissingPinFields"))
        self.assertIn("MergeLabelHide(",body(self.core,"WriteLabelHides"))
        style = body(self.core,"StylePin")
        self.assertLess(style.index("MergeLabelHide("), style.rindex("owner = CMFPinOwner"))
        merge = body(self.core,"MergeLabelHide")
        self.assertIn("ApplyLabelHideState(index)",merge)
        self.assertIn('!CMFHasFlag(merged, 2)',merge)
        self.assertNotIn("CMFPropertyLabelHide(), pinKey",body(self.core,"WriteFields"))

    def test_specific_beats_selected_global_before_strict_fallback(self):
        find = body(self.core,"Find")
        self.assertLess(find.index("pickedRank == 0 && bestRank > 0"),find.index('answer != "" && fallVanilla'))
        self.assertIn('answer == "vanilla"',find)
        self.assertIn("ChoiceOnlySkips",body(self.core,"Prepare"))
        pair = body(self.core,"FindPinClaim")
        self.assertIn("primary.level == 0",pair)
        self.assertIn("secondary.level > 0",pair)
        self.assertIn("FindPinClaim(",body(self.core,"WriteSlot"))

    def test_wire_fields_and_cached_pairs(self):
        writer = body(self.core,"SetNewPinFields")
        for field in ("cmfIconSelectedPath","cmfSelectedScale","cmfPinAlpha","cmfPinOrder",
                      "cmfPinOffsetX","cmfPinOffsetY","cmfPinZoomMin","cmfPinZoomMax",
                      "cmfIconUnderPath","cmfIconUnderTint"):
            self.assertIn('"'+field+'"',writer)
        self.assertNotIn("StringToFloat",writer)
        self.assertIn("incoming.valueX",body(self.core,"Upsert"))
        rows = body(self.core,"WriteFields")
        self.assertLess(rows.index("Find(41,"),rows.index('SetMemberFlashUInt("cmfLegendTint"'))
        self.assertIn("SetNewPinFields(",body(self.core,"StylePin"))


class Rev13WithdrawalValidationTests(unittest.TestCase):
    def test_effective_id_level_context_matrix(self):
        for level, target in (("type","Herbalist"),("type",""),("tag","modP.pin"),("place","Herbalist")):
            for prop in (1,3,10,13,31,32,33,34,35,36,39,42,43,44):
                with self.subTest(level=level,prop=prop):
                    self.assertEqual(pack.withdrawal_issues(prop,target,"","",level), [])
        for prop in (5,9):
            for level in ("type","tag","place"):
                self.assertEqual(pack.withdrawal_issues(prop,"Herbalist","Boat","",level), [])
        for prop in (0,38,40,45):
            self.assertTrue(pack.withdrawal_issues(prop,"Herbalist","","","type"))
        for prop in (2,6,7,8,24,37,41):
            for level in ("tag","place"):
                self.assertTrue(pack.withdrawal_issues(prop,"Herbalist","","",level))
        self.assertTrue(pack.withdrawal_issues(1,"Herbalist","Boat","","type"))
        self.assertTrue(pack.withdrawal_issues(1,"Herbalist","","unexpected","type"))
        self.assertTrue(pack.withdrawal_issues(41,"","","","type"))
        self.assertTrue(pack.withdrawal_issues(37,"All","","","type"))
