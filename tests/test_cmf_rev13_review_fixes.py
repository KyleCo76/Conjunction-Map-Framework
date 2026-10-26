"""Behavioral regressions from the independent API13 review; restricted WS source execution."""
from pathlib import Path
from types import SimpleNamespace as Obj
import unittest
from ws_contract_runner import Array, run
from test_cmf_review_bundle import body
ROOT=Path(__file__).resolve().parents[1]
CORE=(ROOT/"source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")

class ReviewFixTests(unittest.TestCase):
    def test_added_distance_current_and_remote_multiple_pins(self):
        fn=body(CORE,"AppendAddedPins")
        self.assertIn('SetMemberFlashNumber("distance",',fn)
        player=Obj(X=10,Y=20)
        for position,expected in ((Obj(X=13,Y=24),25),(Obj(X=110,Y=20),10000)):
            env={"currentArea":True,"position":position,"playerPosition":player,
                 "VecDistanceSquared2D":lambda a,b:(a.X-b.X)**2+(a.Y-b.Y)**2}
            self.assertEqual(run(CORE,"AddedPinDistance",env),expected)
            env["currentArea"]=False
            self.assertEqual(run(CORE,"AddedPinDistance",env),0)

    def test_equal_drawing_definitions_values_and_lists(self):
        def theme(kind,**extra):
            return Obj(kind=kind,anchor="mapSpace",key="x",text="",number=2,values=Array([1.,2.]),**extra)
        for kind in (1,2,3,4):
            a,b=theme(kind),theme(kind)
            self.assertTrue(run(CORE,"ThemeEntryEqual",{"a":a,"b":b}))
            for field,value in (("anchor","other"),("key","y"),("text","different"),("number",3)):
                b=theme(kind);setattr(b,field,value)
                self.assertFalse(run(CORE,"ThemeEntryEqual",{"a":a,"b":b}),field)
            b=theme(kind);b.values=Array([1.,3.])
            self.assertFalse(run(CORE,"ThemeEntryEqual",{"a":a,"b":b}))
        upsert=body(CORE,"UpsertTheme")
        self.assertLess(upsert.index("ThemeEntryEqual("),upsert.index("themeEntries[i] = themeEntry"))

    def test_label_choice_union_recomputed_for_all_orders_and_openings(self):
        class Flash:
            def __init__(self):self.fields={}
            def SetMemberFlashInt(self,k,v):self.fields[k]=v
            def SetMemberFlashString(self,k,v):self.fields[k]=v
        for existing_offer in (False,True):
            for order in (("modB","modA"),("modA","modB")):
                for registered_first in (False,True):
                    data=Flash();state=Obj(pin=data,providers=Array(),flags=Array())
                    known={"modA"} if existing_offer else set()
                    env={"index":0,"labelHidePins":Array([state]),
                         "AnswerAllows":lambda choice,p: p=="modA" or "modA" not in known,
                         "CMFHasFlag":lambda n,f: bool(n&f),"CMFProviderBeats":lambda a,b:a<b}
                    if registered_first:state.providers.append("modB");state.flags.append(2)
                    for provider in order:
                        known.add(provider)
                        state.providers.append(provider);state.flags.append(1 if provider=="modA" else 2)
                        run(CORE,"ApplyLabelHideState",env)
                    self.assertEqual(data.fields["cmfLabelHide"],1,(existing_offer,order,registered_first))
                    self.assertEqual(data.fields["cmfLabelHideBy"],"modA")
                    env["AnswerAllows"]=lambda choice,p:True
                    run(CORE,"ApplyLabelHideState",env)
                    self.assertEqual(data.fields["cmfLabelHide"],3)
                    env["AnswerAllows"]=lambda choice,p:False
                    run(CORE,"ApplyLabelHideState",env)
                    self.assertEqual(data.fields["cmfLabelHide"],0)
        self.assertIn("ApplyLabelHideState(i)",body(CORE,"NoteLabelHideOffer"))
        self.assertNotIn("AnswerAllows",body(CORE,"WriteLabelHides"))

    def test_selected_global_loses_to_specific_in_both_orders_and_strict_modes(self):
        for strict in (False,True):
            for reverse in (False,True):
                for level,rank in ((1,2),(2,6),(3,4)):
                    global_claim=Obj(propertyId=10,level=0,provider="modGlobal",number=120)
                    specific=Obj(propertyId=10,level=level,provider="modSpecific",number=100)
                    winners=Array([specific,global_claim] if reverse else [global_claim,specific])
                    result=Obj()
                    env={"propertyId":10,"pinType":"Herbalist","pinTag":"tag","maxLevel":3,
                         "result":result,"propertyWon":Array([True]*64),"winners":winners,
                         "specificWon":Array([True]*64),"globalWinner":Array([1 if reverse else 0]*64),
                         "propertyFirst":Array([0]*64),"propertyNext":Array([1,-1]),
                         "choicesActive":True,"decideAnswer":Array(["modGlobal"]*80),"fallVanilla":strict,
                         "PropertyChoice":lambda *a:27,"Covers":lambda *a:True,
                         "CMFLevelPlace":lambda:3,"CMFKindHidden":lambda t:False,
                         "CMFPropertyIconUndiscovered":lambda:29,"CMFPropertyIconCompleted":lambda:30,
                         "Specific":lambda c:0 if c.level==0 else rank,"TagBeats":lambda *a:False}
                    self.assertTrue(run(CORE,"Find",env,capture=("result",)))
                    self.assertIs(env["result"],specific)
                    env["decideAnswer"]=Array(["vanilla"]*80)
                    self.assertFalse(run(CORE,"Find",env,capture=("result",)))


    def test_identical_drawings_do_not_dirty_or_advance_revision(self):
        for kind in (2,3,4):
            a=Obj(provider="modP",kind=kind,target="drawing",anchor="mapSpace",key="x",text="",number=2,
                  values=Array([1.,2.]),order=7)
            b=Obj(**vars(a));b.values=Array(a.values)
            env={"themeEntry":b,"themeEntries":Array([a]),"dirty":False,"nextOrder":7,
                 "IsNameValid":bool,"CMFLog":lambda x:None,"NameToString":str}
            env["ThemeEntryEqual"]=lambda a,b:run(CORE,"ThemeEntryEqual",{"a":a,"b":b})
            self.assertTrue(run(CORE,"UpsertTheme",env,capture=("dirty","nextOrder")))
            self.assertFalse(env["dirty"])
            self.assertEqual(env["nextOrder"],7)
            b.number=3
            self.assertTrue(run(CORE,"UpsertTheme",env,capture=("dirty","nextOrder")))
            self.assertTrue(env["dirty"])

    def test_actual_label_bookkeeping_replays_prior_pins_and_clears_refs(self):
        class Flash:
            def __init__(self,id):self.id=id;self.fields={}
            def GetMemberFlashUInt(self,key):return self.id
            def SetMemberFlashInt(self,k,v):self.fields[k]=v
            def SetMemberFlashString(self,k,v):self.fields[k]=v
        for order in (("modB","modA"),("modA","modB")):
            env={"labelHidePins":Array(),"labelHideBuckets":Array(),"labelHideOffers":Array(),
                 "choicesActive":True,"decideAnswer":Array(["modA"]*80),
                 "SCMFLabelHideState":lambda:Obj(pin=None,providers=Array(),flags=Array(),next=-1),
                 "CMFHasFlag":lambda n,f:bool(n&f),"CMFProviderBeats":lambda a,b:a<b}
            env["AnswerAllows"]=lambda c,p:p=="modA" or "modA" not in env["labelHideOffers"]
            env["ApplyLabelHideState"]=lambda index:run(CORE,"ApplyLabelHideState",dict(env,index=index))
            for opening in range(2):
                one,two=Flash(1),Flash(257) # Deliberate bucket collision.
                run(CORE,"ClearLabelHideState",env)
                # Registered non-selected contribution arrives before direct wrappers.
                run(CORE,"MergeLabelHide",dict(env,dataObject=one,provider="modB",flags=2))
                for provider in order:
                    run(CORE,"NoteLabelHideOffer",dict(env,provider=provider))
                    for pin in (one,two):
                        run(CORE,"MergeLabelHide",dict(env,dataObject=pin,provider=provider,flags=1 if provider=="modA" else 2))
                for pin in (one,two):self.assertEqual(pin.fields["cmfLabelHide"],1)
            run(CORE,"ClearLabelHideState",env)
            self.assertEqual(len(env["labelHidePins"]),0)
            self.assertEqual(len(env["labelHideBuckets"]),0)
