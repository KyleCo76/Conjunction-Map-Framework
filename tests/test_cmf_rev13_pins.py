"""Added-pin registry and full-build wiring: offline contracts."""
from pathlib import Path
import sys
import unittest
from test_cmf_review_bundle import body
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/"tools"))
import cmf_pack as pack

class Rev13PinsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core=(ROOT/"source/core/content/scripts/local/cmfCore.ws").read_text()
    def test_identifiers_and_finite_coordinates(self):
        for provider,tag in (("modP","modP.sample"),("ModP","modp.sample"),("modP","modP.a.b")):
            self.assertEqual(pack.added_pin_issues(provider,tag,"NoticeBoard","no_mans_land",0,-200),[])
        for args in (("","x","NoticeBoard","no_mans_land",0,0),
                     ("modP","modQ.sample","NoticeBoard","no_mans_land",0,0),
                     ("modP","modP.","NoticeBoard","no_mans_land",0,0),
                     ("modP","modP.sample","","no_mans_land",0,0),
                     ("modP","modP.sample","NoticeBoard","",0,0),
                     ("modP","modP.bad tag","NoticeBoard","no_mans_land",0,0),
                     ("modP","modP.sample","NoticeBoard","no_mans_land",float("nan"),0),
                     ("modP","modP.sample","NoticeBoard","no_mans_land",0,float("inf"))):
            self.assertTrue(pack.added_pin_issues(*args))
    def test_registry_upsert_remove_and_claim_independence(self):
        upsert=body(self.core,"UpsertAddedPin")
        self.assertIn("StrLower(addedPins[i].provider) == StrLower(pin.provider)",upsert)
        for field in ("pinType","area","x","y","label","description"):
            self.assertIn("addedPins[i]."+field+" == pin."+field,upsert)
        self.assertIn("pin.order = addedPins[i].order",upsert)
        remove=body(self.core,"RemoveAddedPin")
        self.assertIn("AddedPinTagOk(provider, tag)",remove)
        self.assertIn("addedPins.Erase(i)",remove)
        self.assertNotIn("claims.Erase",remove)
        self.assertIn("return true;",remove)
        self.assertIn("addedPins.Erase(i)",body(self.core,"ReleaseProvider"))
    def test_full_build_only_before_normal_processing(self):
        wrapper=body(self.core,"UpdateUserMapPins")
        self.assertLess(wrapper.index("AppendAddedPins("),wrapper.index("FillMissingPinFields("))
        self.assertLess(wrapper.index("if (indexToUpdate < 0)"),wrapper.index("AppendAddedPins("))
        self.assertEqual(self.core.count(".AppendAddedPins("),1)
        self.assertNotIn("AppendAddedPins",body(self.core,"RefreshMap"))
    def test_objects_are_transient_correctly_typed_and_area_scoped(self):
        append=body(self.core,"AppendAddedPins")
        self.assertLess(append.index("addedPins.Size() == 0"),append.index("GetLength"))
        self.assertIn("addedPins[i].area != area",append)
        self.assertIn("NameToFlashUInt(addedPins[i].tag)",append)
        self.assertIn("ids.Contains(id)",append)
        self.assertIn("GetJournalAreaByPosition(area, position)",append)
        for field in ("id","areaId","journalAreaId","posX","posY","type","filteredType","label","description"):
            self.assertIn('"'+field+'"',append)
        struct=self.core.split("struct SCMFAddedPin",1)[1].split("}",1)[0]
        self.assertNotIn("Flash",struct)
    def test_public_calls_declared_and_known(self):
        for name in ("CMFAddPin","CMFRemovePin"):
            self.assertIn(name,pack.API)
            self.assertIn(name,pack.VERSION13)
            self.assertIn("NoteProviderPresent(provider)",body(self.core,name))

