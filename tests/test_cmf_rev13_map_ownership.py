"""Item ownership and protected pin colors using the actual core methods."""
from types import SimpleNamespace as Obj
import re
import unittest
from ws_contract_runner import Array,bind,run
import test_cmf_rev13_map_contracts as contracts
CORE=contracts.CORE

class ItemOwnershipTests(unittest.TestCase):
    def env(self,entries):
        env=contracts.PreparationLifecycleTests().make_env()
        env["itemStyles"]=Array(entries)
        env["PieceBeats"]=lambda choice,a,b:a<b
        env["CMFListHas"]=bind(CORE,"CMFListHas",env,("list","word"))
        env["PartChoice"]=bind(CORE,"PartChoice",env,("part",))
        env["PartKeyChoice"]=bind(CORE,"PartKeyChoice",env,("part","key"))
        env["ItemStyleOwner"]=bind(CORE,"ItemStyleOwner",env,("styleEntry",))
        return env

    def test_selected_automatic_vanilla_strict_and_separate_pieces(self):
        a=Obj(provider="modA",target="tooltip",item="Boat",itemKind="type",key="titleColor")
        b=Obj(provider="modB",target="tooltip",item="Boat",itemKind="type",key="titleSize")
        move=Obj(provider="modMove",target="tooltip",item="Boat",itemKind="type",key="x")
        other=Obj(provider="modOther",target="tooltip",item="Other",itemKind="type",key="titleColor")
        for reverse in (False,True):
            env=self.env(list(reversed([a,b,move,other])) if reverse else [a,b,move,other])
            for strict in (False,True):
                env["fallVanilla"]=strict
                for answer,expected in (("","modA"),("@order","modA"),("modB","modB"),
                                        ("vanilla",""),("missing","" if strict else "modA")):
                    env["decideAnswer"][41]=answer
                    self.assertEqual(env["ItemStyleOwner"](a),expected)
                    self.assertEqual(env["ItemStyleOwner"](b),expected)
                    self.assertEqual(env["ItemStyleOwner"](move),"modMove")
                    self.assertEqual(env["ItemStyleOwner"](other),
                        "" if answer=="vanilla" or answer not in ("","@order","modOther") and strict else "modOther")

    def test_choice_only_release_and_different_items(self):
        a=Obj(provider="modA",target="tooltip",item="Boat",itemKind="type",key="titleColor")
        b=Obj(provider="modB",target="tooltip",item="Boat",itemKind="type",key="titleSize")
        env=self.env([a,b])
        env["choiceOnlyProviders"].append("modA");env["choiceOnlyChoices"].append(41)
        self.assertEqual(env["ItemStyleOwner"](a),"modB")
        env["menuChoices"][41]="modA";env["decideAnswer"][41]="modA"
        self.assertEqual(env["ItemStyleOwner"](b),"modA")
        env["provider"]="modA";run(CORE,"ReleaseProvider",env,capture=("dirty",))
        env["decideAnswer"][41]="@order";env["menuChoices"][41]=""
        self.assertEqual(env["ItemStyleOwner"](b),"modB")

class PinProtectionTests(unittest.TestCase):
    def test_instance_new_properties_respect_undiscovered_and_completed(self):
        for prop in (1,3,10,31,32,33,34,35,36,42,43):
            env=contracts.lookup_env([contracts.claim(propertyId=prop,level=2,pinTag="tag")])
            env.update(StrBeginsWith=str.startswith,StrEndsWith=str.endswith)
            env["CMFKindHidden"]=bind(CORE,"CMFKindHidden",env,("pinType",))
            for kind in ("NotDiscoveredPOI","BoatDisabled"):
                self.assertFalse(contracts.find(env,prop=prop,kind=kind)[0],(prop,kind))
            self.assertTrue(contracts.find(env,prop=prop,kind="Boat")[0])
        for prop in (29,30):
            env=contracts.lookup_env([contracts.claim(propertyId=prop,level=2,pinTag="tag")])
            env.update(StrBeginsWith=str.startswith,StrEndsWith=str.endswith)
            env["CMFKindHidden"]=bind(CORE,"CMFKindHidden",env,("pinType",))
            self.assertTrue(contracts.find(env,prop=prop,kind="BoatDisabled")[0])

    def test_tracked_gold_and_direct_tint_owner_survive_registered_tint(self):
        class Flash:
            def __init__(self,tracked,highlighted,owner):
                self.fields={"tracked":tracked,"highlighted":highlighted,"cmfTintBy":owner,"cmfIconTint":0xabcdef}
            def GetMemberFlashBool(self,k):return bool(self.fields.get(k,False))
            def GetMemberFlashString(self,k):return self.fields.get(k,"")
            def SetMemberFlashUInt(self,k,v):self.fields[k]=v
            def SetMemberFlashBool(self,k,v):self.fields[k]=v
        for tracked,highlighted,owner in ((True,False,""),(False,True,""),(False,False,"direct"),(False,False,"")):
            env=contracts.lookup_env([contracts.claim(propertyId=3,level=0,pinType="",number=0)])
            for name,value in re.findall(r"function (CMF\w+)\(\) : int \{ return (\d+); \}",CORE):
                env[name]=lambda value=int(value):value
            env["SCMFClaim"]=contracts.claim
            env.update(StrBeginsWith=str.startswith,rowsKept=Array())
            for method,parameters,outs in (
                ("Find",("propertyId","pinType","pinTag","maxLevel","result"),(4,)),
                ("FindPinClaim",("propertyId","pinKey","legendKey","pinTag","maxLevel","result"),(5,)),
                ("CMFPinOwner",("dataObject","ownerField"),()),
                ("DisabledIndex",("pinType","pinTag","maxLevel","mapContext"),()),
                ("WriteClickFields",("dataObject","pinKey","legendKey","pinTag","maxLevel"),())):
                env[method]=bind(CORE,method,env,parameters,outs)
            data=Flash(tracked,highlighted,owner)
            run(CORE,"WriteFields",dict(env,dataObject=data,pinKey="Boat",legendKey="Boat",pinTag="",maxLevel=3,mapContext=""))
            self.assertEqual(data.fields["cmfIconTint"],0xabcdef if tracked or highlighted or owner else 0)
