"""API 13 map core contracts executed from production WitcherScript."""
from pathlib import Path
from types import SimpleNamespace as Obj
from collections import Counter
import copy
import unittest
from ws_contract_runner import Array, run, bind
from test_cmf_review_bundle import body

CORE=(Path(__file__).resolve().parents[1]/"source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")

def claim(**kw):
    values=dict(provider="modA",propertyId=10,level=1,pinType="Boat",pinTag="",
                mapContext="",text="",number=100,placeX=0.,placeY=0.,valueX=0.,valueY=0.,order=0)
    values.update(kw);values["propertyId"]=int(values["propertyId"])
    return Obj(**values)

def validation_env():
    constants={"LegendCategory":8,"CategoryNoDefault":23,"Hidden":9,"LabelHide":13,
               "TabHide":15,"PinClick":16,"TabHidden":37,"PinScale":10,"LabelPlace":11,
               "LabelColor":17,"SpreadRank":22,"HoverName":28,"InfoTitle":18,"InfoText":19,
               "InfoBoxHeight":14,"WorldPainting":24}
    env={"IsNameValid":bool,"NameToString":str,"StrLower":str.lower,
         "CMFHasProperty":lambda p:1<=p<=43 and p != 38,
         "CMFOnePinProperty":lambda p:p in (1,3,5,9,10,11,12,13,14,15,16,17,18,19,20,21,22,28,29,30,31,32,33,34,35,36,39,42,43),
         "CMFIsPictureProperty":lambda p:24<=p<=27,
         "CMFPictureTargetOk":lambda p,t:t=="Velen","CMFLevelPlace":lambda:3,
         "StrBeginsWith":str.startswith,"StrEndsWith":str.endswith,"StrLen":len,
         "StrFindFirst":str.find,"StrMid":lambda s,i,n:s[i:i+n],"StrLeft":lambda s,n:s[:n],
         "StrRight":lambda s,n:s[-n:] if n else "", "StringToFloat":float,
         "StrBeforeFirst":lambda s,x:s.split(x,1)[0],"StrAfterFirst":lambda s,x:s.split(x,1)[1],
         "CMFIsVanillaCategory":lambda *a:False,"CMFPropertyTextFree":lambda p:p!=1,
         "CMFInfoReplace":lambda:0,"CMFInfoAdd":lambda:1,"CMFPaintingTilesOk":lambda n:True,
         "claims":Array(),"dirty":False,"nextOrder":0,"revision":7,"Report":lambda *a:None}
    for name,value in constants.items():env["CMFProperty"+name]=lambda value=value:value
    env["EveryPinProperty"]=lambda p:run(CORE,"EveryPinProperty",dict(env,propertyId=p))
    env["ClaimTargetOk"]=lambda c:run(CORE,"ClaimTargetOk",dict(env,claim=c))
    env["ClaimRejectReason"]=lambda c:run(CORE,"ClaimRejectReason",dict(env,claim=c))
    env["SameSlot"]=lambda a,b:run(CORE,"SameSlot",dict(env,a=a,b=b))
    logs=[];env["CMFLog"]=logs.append
    env["ClaimNumber"]=bind(CORE,"ClaimNumber",env,("text","value"),(1,))
    env["NewPinValueOk"]=bind(CORE,"NewPinValueOk",env,("propertyId","text","number","x","y"),(3,4))
    env["WithdrawClaim"]=lambda c:run(CORE,"WithdrawClaim",dict(env,command=c),capture=("dirty",))
    return env,logs

def lookup_env(winners):
    env={"propertyWon":Array(),"globalWinner":Array(),"specificWon":Array(),
         "propertyFirst":Array(),"propertyNext":Array(),"activeWriteSlots":Array(),
         "winners":Array(winners),"tagIds":Array(),"tagNames":Array(),"claimedTypes":Array(),
         "infoTypes":Array(),"infoTags":Array(),"hideClaims":Array(),"tabHideClaims":Array(),
         "labelHideClaims":Array(),"infoAdds":Array(),"NameToString":str,
         "NoteLookupClaim":lambda c:None,"NoteInfoClaim":lambda c:None,
         "CMFPropertyInfoBoxHeight":lambda:14,"choicesActive":True,
         "decideAnswer":Array([""]*80),"fallVanilla":False,"PropertyChoice":lambda p,t:27,
         "CMFLevelPlace":lambda:3,"CMFKindHidden":lambda t:False,
         "CMFPropertyIconUndiscovered":lambda:29,"CMFPropertyIconCompleted":lambda:30,
         "TagBeats":lambda choice,a,b:a.provider<b.provider,
         "Specific":lambda c: {0:0,1:2,2:6,3:4}[c.level],
         "Covers":lambda c,t,tag,level:c.level<=level and
          (c.level==0 or c.level==1 and c.pinType==t or c.level==2 and c.pinTag==tag or c.level==3 and c.pinType==t)}
    env["PropertyWon"]=lambda p:run(CORE,"PropertyWon",dict(env,propertyId=p))
    run(CORE,"NoteLookups",env,capture=("placeClaims","everyPinClaims","infoEveryOrPlace"))
    return env

def find(env,prop=10,kind="Boat",tag="tag",level=3):
    call=dict(env,propertyId=prop,pinType=kind,pinTag=tag,maxLevel=level,result=None)
    accepted=run(CORE,"Find",call,capture=("result",))
    return accepted,call["result"]

class CoreMapContracts(unittest.TestCase):
    def test_rejection_reason_matrix(self):
        cases=[(dict(provider=""),"empty"),(dict(pinType=""),"empty"),
               (dict(level=2,pinType="",pinTag=""),"empty"),
               (dict(propertyId=24,pinType="Bad",text="image"),"target"),
               (dict(propertyId=37,pinType="All"),"target"),
               (dict(propertyId=41,level=2,pinTag="tag"),"level"),
               (dict(propertyId=41,level=3),"level"),
               (dict(mapContext="Boat"),"context")]
        for prop,text,num in ((31,"bad",0),(32,"",24),(33,"",101),(34,"",-1001),
                              (35,"51,0",0),(36,"2,1",0),(41,"",-1),(43,"",16777216)):
            cases.append((dict(propertyId=prop,text=text,number=num),"range"))
        for changes,reason in cases:
            with self.subTest(changes=changes):
                env,logs=validation_env();env["claim"]=claim(**changes)
                self.assertFalse(run(CORE,"Upsert",env,capture=("dirty","nextOrder")))
                self.assertFalse(env["dirty"]);self.assertEqual(env["claims"],[])
                self.assertEqual(env["nextOrder"],0)
                self.assertEqual(logs[-1].split("reason=")[1],reason)
        self.assertFalse("reason=target-value" in CORE)

    def test_global_specific_choice_matrix(self):
        for strict in (False,True):
            for reverse in (False,True):
                for level in (1,2,3):
                    global_c=claim(level=0,pinType="",provider="modGlobal",number=120)
                    local=claim(level=level,pinTag="tag",provider="modSpecific",number=100)
                    env=lookup_env([local,global_c] if reverse else [global_c,local])
                    env["fallVanilla"]=strict
                    for answer in ("","@order","modGlobal","modSpecific","missing","vanilla"):
                        env["decideAnswer"]=Array([answer]*80)
                        accepted,result=find(env)
                        if answer=="vanilla" or answer=="missing" and strict:
                            self.assertFalse(accepted,(level,strict,answer))
                        else:self.assertIs(result,local,(level,strict,answer))
                    # Group choices remain per input even with a global-only cached winner.
                    env=lookup_env([global_c])
                    env["PropertyChoice"]=lambda p,t:27 if t=="Boat" else 28
                    env["decideAnswer"][27]="vanilla"
                    self.assertFalse(find(env)[0]);self.assertIs(find(env,kind="Herbalist")[1],global_c)

    def test_unused_and_global_only_lookup_counts(self):
        env=lookup_env([claim(level=0,pinType="")])
        counts=Counter()
        def covered(*a):counts["covers"]+=1;return True
        def ranked(c):counts["specific"]+=1;return 0
        env.update(Covers=covered,Specific=ranked)
        for i in range(1800):self.assertTrue(find(env)[0])
        self.assertEqual(counts["covers"],0)
        self.assertEqual(counts["specific"],0)
        self.assertEqual(env["globalWinner"][10],0)
        self.assertEqual(env["activeWriteSlots"],[10])
        def owner(*a):counts["owner"]+=1;return ""
        for i in range(1800):
            run(CORE,"WriteSlot",dict(env,propertyId=33,dataObject=None,pinKey="Boat",
                legendKey="Other",pinTag="",maxLevel=3,CMFPinOwner=owner,CMFOwnerField=lambda p:str(p),
                FindPinClaim=lambda *a:False))
        self.assertEqual(counts["owner"],0)

    def test_property_candidates_skip_unrelated_claims(self):
        wanted=claim()
        env=lookup_env([claim(propertyId=11,pinType="Type"+str(i)) for i in range(100)]+[wanted])
        count=Counter()
        class ReadArray(Array):
            def __getitem__(self,key):
                count["candidate_reads"]+=1
                return super().__getitem__(key)
        env["winners"]=ReadArray(env["winners"])
        def covers(c,*a):count["covers"]+=1;return True
        env["Covers"]=covers
        for i in range(1800):self.assertIs(find(env)[1],wanted)
        self.assertEqual(count["covers"],1800)
        self.assertLess(count["candidate_reads"],1800*10)
        self.assertEqual(env["propertyFirst"][10],100)

    def test_noop_preserves_revision(self):
        env,logs=validation_env();env["claim"]=claim();env["claims"]=Array([copy.copy(env["claim"])])
        self.assertTrue(run(CORE,"Upsert",env,capture=("dirty","nextOrder","revision")))
        self.assertFalse(env["dirty"]);self.assertEqual(env["revision"],7)
        env["claim"]=claim(number=120)
        self.assertTrue(run(CORE,"Upsert",env,capture=("dirty","nextOrder","revision")))
        self.assertTrue(env["dirty"]);self.assertEqual(env["claims"][0].number,120)
        self.assertEqual(env["revision"],7) # Only preparation increments revision.

class ContractRunnerTests(unittest.TestCase):
    def test_source_literals_outs_and_arrays(self):
        source='''function Inner(text:string,out value:float):bool { value = 7.0; return text == "img://icon"; }
        function Outer():float { var number:float; var values:array<int>;
            values.PushBack(2);
            if (Inner("img://icon",number)) { return number + values[0]; } return 0; }'''
        env={};env["Inner"]=bind(source,"Inner",env,("text","value"),(1,))
        self.assertEqual(run(source,"Outer",env),9)

    def test_source_switch_and_short_circuit_loop(self):
        source='''function Choose(level:int):int { switch (level) { case 0: case 2: return 2; case 1:
          if (level == 1) { return 3; } return 4; } return 5; }
          function Loop():int { var i,total:int; for (i=0;i<10 && total<3;i+=1) { total+=1; } return total; }'''
        for value,expected in ((0,2),(2,2),(1,3),(7,5)):
            self.assertEqual(run(source,"Choose",dict(level=value)),expected)
        self.assertEqual(run(source,"Loop",{}),3)

class LookupLifecycleTests(unittest.TestCase):
    def test_filtered_type_specific_and_direct_owner(self):
        for specifics in (False,True):
            entries=[claim(level=0,pinType="",provider="global")]
            if specifics:entries.append(claim(pinType="Boat",provider="specific",number=80))
            env=lookup_env(entries);count=Counter()
            env["SCMFClaim"]=lambda:claim()
            actual=bind(CORE,"Find",env,("propertyId","pinType","pinTag","maxLevel","result"),(4,))
            def counted(*a):count["find"]+=1;return actual(*a)
            counted.out_indices=(4,);env["Find"]=counted
            call=dict(env,propertyId=10,pinKey="Custom",legendKey="Boat",pinTag="",maxLevel=3,result=None)
            self.assertTrue(run(CORE,"FindPinClaim",call,capture=("result",)))
            self.assertEqual(call["result"].provider,"specific" if specifics else "global")
            self.assertEqual(count["find"],2 if specifics else 1)
            # A per-pin writer owns the slot, so stored claims never overwrite it.
            env["CMFPinOwner"]=lambda *a:"direct"
            env["CMFOwnerField"]=lambda p:"cmfScaleBy"
            env["FindPinClaim"]=lambda *a:self.fail("Direct ownership must stop lookup")
            run(CORE,"WriteSlot",dict(env,propertyId=10,dataObject=None,pinKey="Custom",
                legendKey="Boat",pinTag="",maxLevel=3))

    def test_actual_covers_variant_place_tag_and_protected_state(self):
        for reverse in (False,True):
            entries=[claim(level=0,pinType="",number=120),
                     claim(pinType="Boat",number=100),
                     claim(pinType="Boat_2",number=90),
                     claim(level=3,pinType="Boat",number=80),
                     claim(level=2,pinType="",pinTag="tag",number=70)]
            env=lookup_env(list(reversed(entries)) if reverse else entries)
            env.update(variantNow="Boat_2",pinKeyNow="Boat",placeOk=True,placeX=0.,placeY=0.,
                       IsNameValid=bool,CMFPlaceRadius=lambda:2.)
            env["Covers"]=bind(CORE,"Covers",env,("claim","pinType","pinTag","maxLevel"))
            env["Specific"]=bind(CORE,"Specific",env,("claim",))
            self.assertEqual(find(env)[1].number,70)
            self.assertEqual(find(env,tag="other")[1].number,80)
            env["placeX"]=10.
            self.assertEqual(find(env,tag="other")[1].number,90)
            env["variantNow"]=""
            self.assertEqual(find(env,tag="other")[1].number,100)
            env["CMFKindHidden"]=lambda t:True
            self.assertEqual(find(env)[1].number,100)
            self.assertEqual(find(env,kind="Other")[1].number,120)

    def test_unused_click_slot_has_no_native_reads(self):
        class Flash:
            def GetMemberFlashBool(self,key):
                raise AssertionError("Unused click property read "+key)
        env=lookup_env([])
        run(CORE,"WriteClickFields",dict(env,dataObject=Flash(),pinKey="Boat",legendKey="Boat",
            pinTag="",maxLevel=3,CMFPropertyPinClick=lambda:16))

    def test_source_numeric_log_concatenation(self):
        source='function Log():string { var total:int; total=3; return "total=" + total; }'
        self.assertEqual(run(source,"Log",{}),"total=3")

class PreparationLifecycleTests(unittest.TestCase):
    def make_env(self):
        env=lookup_env([])
        validation,_=validation_env();env.update(validation)
        import re
        for name,value in re.findall(r"function (CMF\w+)\(\) : int \{ return (\d+); \}",CORE):
            env[name]=lambda value=int(value):value
        for field in ("choiceOnlySkipped","tabsHidden","rowsKept","themeEntries","itemStyles",
                      "addedPins","openingViews","choiceOnlyProviders","choiceOnlyChoices","labelHideOffers",
                      "declaredTagProviders","declaredTagNames","unknownTagProviders","unknownTagTexts"):
            env[field]=Array()
        env.update(choiceKeys=Array(["key"]*80),choiceFeature=Array([0]*80),
                   menuChoices=Array([""]*80),fileChoices=Array([""]*80),revision=0,
                   CMFSettingsProviderOrder=lambda:"",ReadChoices=lambda:None,
                   EnsureChoices=lambda:None,AdditiveAllows=lambda *a:True,
                   ReportClickShadow=lambda *a:None,PrepareItemStyles=lambda:None,PrepareDrawingRoots=lambda:None,
                   ReportProviders=lambda:None,PrepareOffers=lambda:None,
                   ReportChoices=lambda:None,PrepareLegend=lambda:None,
                   CMFHasFlag=lambda n,f:bool(n&f),NoteProviderPresent=lambda *a:True,
                   Beats=lambda a,b:a.provider<b.provider)
        for method,params,outs,capture in (
            ("CMFIsClickProperty",("propertyId",),(),()),
            ("ClaimRejectReason",("claim",),(),()),("ClaimTargetOk",("claim",),(),()),
            ("EveryPinProperty",("propertyId",),(),()),("SameSlot",("a","b"),(),()),
            ("ClaimNumber",("text","value"),(1,),()),
            ("NewPinValueOk",("propertyId","text","number","x","y"),(3,4),()),
            ("WithdrawClaim",("command",),(),("dirty",)),
            ("ChoiceOnlySkips",("choice","provider"),(),()),
            ("NoteLookups",(),(),("placeClaims","everyPinClaims","infoEveryOrPlace"))):
            env[method]=bind(CORE,method,env,params,outs,capture)
        return env

    def prepare(self,env):
        run(CORE,"Prepare",env,capture=("providerOrder","dirty","revision"))
        self.assertFalse(env["dirty"])

    def upsert(self,env,value):
        env["claim"]=value
        self.assertTrue(run(CORE,"Upsert",env,capture=("dirty","nextOrder")))

    def test_update_withdraw_release_choice_and_cache_invalidation(self):
        env=self.make_env()
        self.upsert(env,claim(level=0,pinType="",number=120))
        self.prepare(env)
        self.assertEqual(find(env)[1].number,120)
        revision=env["revision"]
        self.upsert(env,claim(level=0,pinType="",number=120))
        self.assertFalse(env["dirty"]);self.assertEqual(env["revision"],revision)
        self.upsert(env,claim(level=0,pinType="",number=130))
        self.assertTrue(env["dirty"]);self.prepare(env)
        self.assertEqual(find(env)[1].number,130)
        self.upsert(env,claim(provider="modB",number=80))
        self.prepare(env);self.assertTrue(env["specificWon"][10])
        self.assertEqual(find(env)[1].number,80)
        self.upsert(env,claim(provider="modB",propertyId=40,number=10))
        self.prepare(env);self.assertFalse(env["specificWon"][10])
        self.assertEqual(find(env)[1].number,130)
        self.upsert(env,claim(provider="modB",propertyId=40,number=10))
        self.assertFalse(env["dirty"])
        # The settings callback's requested refresh rebuilds these same indices.
        env["decideAnswer"][27]="vanilla"
        run(CORE,"RequestRefresh",env,capture=("dirty",))
        self.assertTrue(env["dirty"]);self.prepare(env)
        self.assertFalse(find(env)[0])
        env["decideAnswer"][27]=""
        env["provider"]="modA"
        run(CORE,"ReleaseProvider",env,capture=("dirty",))
        self.assertTrue(env["dirty"]);self.prepare(env)
        self.assertEqual(env["activeWriteSlots"],[])
        self.assertFalse(find(env)[0])
        run(CORE,"ReleaseProvider",env,capture=("dirty",))
        self.assertFalse(env["dirty"])

    def test_choice_only_is_filtered_before_cache_preparation(self):
        for reverse in (False,True):
            env=self.make_env()
            entries=[claim(provider="modA",level=0,pinType="",number=120),
                     claim(provider="modB",number=80)]
            for c in reversed(entries) if reverse else entries:self.upsert(env,c)
            env["choiceOnlyProviders"].append("modB");env["choiceOnlyChoices"].append(27)
            self.prepare(env)
            self.assertFalse(env["specificWon"][10]);self.assertEqual(find(env)[1].number,120)
            env["menuChoices"][27]="modB";env["decideAnswer"][27]="modB"
            run(CORE,"RequestRefresh",env,capture=("dirty",));self.prepare(env)
            self.assertTrue(env["specificWon"][10]);self.assertEqual(find(env)[1].number,80)
            env["menuChoices"][27]="";env["decideAnswer"][27]="@order"
            run(CORE,"RequestRefresh",env,capture=("dirty",));self.prepare(env)
            self.assertFalse(env["specificWon"][10]);self.assertEqual(find(env)[1].number,120)

class TerminalSwitchTests(unittest.TestCase):
    def test_terminal_switch_break_preserves_following_return(self):
        source='''function Choose(level:int):int { var answer:int; answer=1;
          switch (level) { case 0: answer=2; break; case 1: if (level==1) { return 3; } break; }
          return answer; }'''
        for level,expected in ((0,2),(1,3),(2,1)):
            self.assertEqual(run(source,"Choose",dict(level=level)),expected)

    def test_nonterminal_switch_break_stays_unqualified(self):
        source='''function Choose(level:int):int { var answer:int; switch (level) {
          case 0: if (level==0) { break; } answer=5; break; } return answer; }'''
        with self.assertRaises(AssertionError):
            run(source,"Choose",dict(level=0))
