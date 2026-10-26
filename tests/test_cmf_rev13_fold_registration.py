"""Source-executed public fold registration, arbitration and native wire parity."""
from pathlib import Path
from types import SimpleNamespace as Obj
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/"tests"),str(ROOT/"tools")]
from ws_contract_runner import Array,bind,run
import test_cmf_rev13_map_contracts as contracts
import cmf_pack as pack
CORE=contracts.CORE

class CoreReceiverBoundaryTests(unittest.TestCase):
    SOURCE='''
    function Mark(out result:string):bool { result="kept"; dirty=true; return true; }
    function Ask():bool { var result:string; if (!theGame.CMFGetCore().Mark(result)) { return false; } return result=="kept"; }
    function Other():bool { var result:string; other.Mark(result); return result=="kept"; }
    function Literal():string { return "theGame.CMFGetCore().Mark("; }
    '''
    def fixture(self):
        env=dict(dirty=False,__ws_live_state__=("dirty",))
        env["Mark"]=bind(self.SOURCE,"Mark",env,("result",),(0,),("dirty",))
        core=Obj(Mark=env["Mark"])
        env.update(theGame=Obj(CMFGetCore=lambda:core),other=core,__ws_core_receiver__=core)
        return env
    def test_declared_singleton_preserves_source_out_and_shared_state(self):
        env=self.fixture()
        self.assertTrue(run(self.SOURCE,"Ask",env))
        self.assertTrue(env["dirty"])
    def test_opt_in_does_not_rewrite_default_other_receiver_or_literals(self):
        env=self.fixture();env.pop("__ws_core_receiver__")
        self.assertFalse(run(self.SOURCE,"Ask",env))
        env=self.fixture()
        self.assertFalse(run(self.SOURCE,"Other",env))
        self.assertEqual(run(self.SOURCE,"Literal",env),"theGame.CMFGetCore().Mark(")
    def test_mismatched_source_method_identity_is_rejected(self):
        env=self.fixture();env["__ws_core_receiver__"]=Obj(Mark=lambda *args:True)
        with self.assertRaisesRegex(AssertionError,"unqualified core receiver method"):
            run(self.SOURCE,"Ask",env)


FOLD_KEYS=("foldTag","foldMoreText","foldLessText","foldKeyPad","foldKeyKb","foldOpen")
TEXT_KEYS=FOLD_KEYS[:-1]+("clearAnchor",)

class Flash:
    def __init__(self,**fields):self.fields=fields
    def SetMemberFlashString(self,k,v):self.fields[k]=v
    def SetMemberFlashNumber(self,k,v):self.fields[k]=v
    def SetMemberFlashInt(self,k,v):self.fields[k]=int(v)
    def SetMemberFlashUInt(self,k,v):self.fields[k]=v
    def SetMemberFlashArray(self,k,v):self.fields[k]=v
    def GetMemberFlashString(self,k):return self.fields.get(k,"")
    def GetMemberFlashUInt(self,k):return self.fields.get(k,0)
class FlashList(list):
    def __bool__(self):return True  # Native Flash arrays are objects, including when empty.
    def PushBackFlashObject(self,v):self.append(v)
    def PushBackFlashInt(self,v):self.append(v)
class Storage:
    def __init__(self):self.sent={}
    def __bool__(self):return True
    def CreateTempFlashArray(self):return FlashList()
    def CreateTempFlashObject(self):return Flash()
    def SetFlashArray(self,k,v):self.sent[k]=v

def style_env():
    env=contracts.PreparationLifecycleTests().make_env()
    def entry():return Obj(provider="",kind=0,target="",anchor="",key="",text="",number=0.,order=0,item="",itemKind="",values=Array())
    env.update(SCMFThemeEntry=entry,itemStyleOwners=Array(),itemStylesSent=False,
               menuOrder="",providerOrder="",themeNotes=Array(),StrCmp=lambda a,b:(a>b)-(a<b),
               StrReplaceAll=str.replace,CMFSettingsProviderRank=lambda order,p:-1,
               __ws_live_state__=("dirty","nextOrder","revision","providerOrder","hintListPreparedOwner","itemStylesSent"))
    env["hintListPreparedOwner"]=""
    native=[]
    def keys(kind,action,out):native.append((kind,action));out.extend([70,71] if kind=="kb" else [136])
    env.update(theInput=Obj(GetPCKeysForActionStr=lambda action,out:keys("kb",action,out),
                           GetPadKeysForActionStr=lambda action,out:keys("pad",action,out)),
               GetIconForKey=lambda key,gui:"glyph:"+str(key),GetLocStringByKeyExt=lambda key:"loc:"+key)
    methods=(
      ("CMFListHas",("list","word"),()),("CMFThemeParts",(),()),("CMFThemeKinds",(),()),("CMFThemeLayers",(),()),
      ("CMFThemeGlowKeys",(),()),("CMFThemeTextKeys",(),()),("CMFThemeShadowKeys",(),()),
      ("CMFThemeOpeningKeys",(),()),("CMFThemeWideKeys",(),()),("CMFThemePartKeys",("part",),()),
      ("CMFHasAbility",("part","key"),()),("CMFThemeTextKey",("key",),()),
      ("CMFThemeValueOk",("part","key","text","number"),()),("CMFThemeWordOk",("text",),()),
      ("CMFStyle",("provider","part","target","key","text","number"),()),
      ("CMFStylePart",("provider","part","key","text","number"),()),
      ("ItemTarget",("part","key","target","item","kind"),(3,4)),
      ("UpsertItemStyle",("styleEntry",),()),("UpsertTheme",("themeEntry",),()),
      ("ThemeEntryEqual",("a","b"),()),("UnsetTheme",("provider","part","key"),()),
      ("PartChoice",("part",),()),("PartKeyChoice",("part","key"),()),
      ("ThemeOwnershipKey",("part","key"),()),("ThemeStyleOwner",("part","key"),()),
      ("ItemStyleOwner",("styleEntry",),()),("PrepareItemStyles",(),()),("Prepare",(),()),
      ("CMFFolderBeats",("a","b"),()),("ProviderBeats",("a","b"),()),("CMFProviderBeats",("a","b"),()),
      ("PickDecides",("pick","a","b","result"),(3,)),("OrderDecides",("order","a","b","result"),(3,)),
      ("PieceBeats",("choice","a","b"),()),("ChoiceKey",("choice",),()),
      ("WriteFoldMetadata",("item","styleEntry","storage"),()),
      ("WriteDrawingMetadata",("item","entryValue","storage"),()),
      ("ThemeFolderRank",("provider",),()),("NoteTheme",("line",),()),
      ("SendTheme",("storage",),()),("SendItemStyles",("storage",),()),
      ("InfoFoldOwner",("pin",),()),
    )
    for name,args,outs in methods:env[name]=bind(CORE,name,env,args,outs)
    # Independent channels are not part of fold registration/wire assertions.
    for name in ("SendWideVanilla","SendLookOwners","SendMovieTags","SendWorld"):env[name]=lambda *args:None
    env["SendDefaultMotion"]=lambda *args:0
    core=Obj(**{name:fn for name,fn in env.items() if callable(fn)})
    env.update(__ws_core_receiver__=core,theGame=Obj(CMFGetCore=lambda:core))
    return env,native

class FoldPublicRegistrationTests(unittest.TestCase):
    def test_discovery_choice_and_text_typing_match_checker(self):
        env,_=style_env()
        actual=set(env["CMFThemePartKeys"]("tooltip").split(","))
        for key in FOLD_KEYS+("clearAnchor",):
            self.assertTrue(env["CMFHasAbility"]("tooltip",key),key)
            self.assertEqual(env["PartKeyChoice"]("tooltip",key),74 if key in FOLD_KEYS else 63,key)
            self.assertEqual(env["CMFThemeTextKey"](key),key in TEXT_KEYS,key)
        self.assertEqual(actual,set(pack.THEME_PART_KEYS["tooltip"]))
        self.assertTrue(set(FOLD_KEYS+("clearAnchor",))<=actual)

    def test_public_whole_and_item_calls_preserve_values_and_identity(self):
        values=(("foldTag","NAME_-:9",0.),("foldMoreText","<b>More</b>",0.),("foldLessText","[[less_key]]",0.),
                ("foldKeyKb","Native Action",0.),("foldKeyPad","PadAction",0.),("foldOpen","",0.),("clearAnchor","pin",0.))
        for target in ("","type:Boat"):
            env,_=style_env()
            for key,text,number in values:
                self.assertTrue(env["CMFStyle"]("modP","tooltip",target,key,text,number),(target,key))
            stored=env["itemStyles"] if target else env["themeEntries"]
            self.assertEqual([(e.key,e.text,e.number) for e in stored],list(values))
            if target:self.assertEqual({(e.itemKind,e.item) for e in stored},{("type","Boat")})
            self.assertTrue(env["dirty"])

    def test_invalid_values_empty_strings_zero_noop_and_withdrawal(self):
        for target in ("","type:Boat"):
            env,_=style_env();submit=lambda key,text,num:env["CMFStyle"]("modP","tooltip",target,key,text,num)
            for key,text,num in (("foldOpen","",-1.),("foldOpen","",2.),("foldOpen","",.5),
                                 ("foldOpen","",float("nan")),("clearAnchor","",0.),("clearAnchor","PIN",0.),
                                 ("clearAnchor","other",0.),("foldTag","bad name",0.),("foldTag","bad<tag",0.)):
                self.assertFalse(submit(key,text,num),(target,key,text,num))
            stored=env["itemStyles"] if target else env["themeEntries"]
            self.assertEqual(stored,[])
            for key in FOLD_KEYS[:-1]:self.assertTrue(submit(key,"",0.),key)
            self.assertTrue(submit("foldOpen","",1.));self.assertTrue(submit("foldOpen","",0.))
            self.assertEqual(next(e.number for e in stored if e.key=="foldOpen"),0.)
            env["dirty"]=False;order=env["nextOrder"]
            self.assertTrue(submit("foldOpen","",0.))
            self.assertFalse(env["dirty"]);self.assertEqual(env["nextOrder"],order)
            for key in FOLD_KEYS:self.assertTrue(submit(key,"unset",999.))
            self.assertEqual(stored,[])
            self.assertTrue(submit("clearAnchor","cursor",0.))
            self.assertTrue(submit("clearAnchor","pin",0.))
            self.assertTrue(submit("clearAnchor","unset",0.))
            self.assertEqual(stored,[])

    def test_registered_whole_and_item_winners_reach_metadata_and_wire(self):
        for target in ("","type:Boat"):
            env,native=style_env()
            register=lambda p,k,t,n=0.:env["CMFStyle"](p,"tooltip",target,k,t,n)
            self.assertTrue(register("modLook","titleColor","",123.))
            self.assertTrue(register("modMove","clearAnchor","pin"))
            for provider,marker in (("modA","FIRST"),("modB","SECOND")):
                self.assertTrue(register(provider,"foldTag",marker))
                self.assertTrue(register(provider,"foldMoreText","[[more_key]]"))
                self.assertTrue(register(provider,"foldLessText","<i>Less</i>"))
                self.assertTrue(register(provider,"foldKeyKb","Fold Action"))
                self.assertTrue(register(provider,"foldKeyPad","Pad Action"))
                self.assertTrue(register(provider,"foldOpen","",0.))
            storage=Storage();env["SendTheme"](storage)
            channel="cmf.map.itemStyles" if target else "cmf.map.theme"
            owner="o" if target else "b"
            initial=next(item.fields for item in storage.sent[channel] if item.fields["y"]=="foldTag")
            self.assertEqual(initial[owner],"modA")
            native.clear()
            env["decideAnswer"][74]="modB";env["decideAnswer"][63]="modMove";env["decideAnswer"][41]="modLook"
            env["dirty"]=True;env["SendTheme"](storage)
            wire=storage.sent["cmf.map.itemStyles" if target else "cmf.map.theme"]
            bykey={item.fields["y"]:item.fields for item in wire}
            owner="o" if target else "b"
            self.assertEqual(bykey["foldTag"]["s"],"SECOND")
            self.assertEqual(bykey["foldTag"][owner],"modB")
            self.assertEqual(bykey["foldMoreText"]["fl"],"loc:more_key")
            self.assertEqual(bykey["foldLessText"]["fl"],"<i>Less</i>")
            self.assertEqual(bykey["foldKeyKb"]["s"],"Fold Action")
            self.assertEqual(bykey["foldKeyKb"]["fk"],[70,71])
            self.assertEqual(bykey["foldKeyKb"]["fg"],"glyph:70")
            self.assertEqual(bykey["foldKeyPad"]["s"],"Pad Action")
            self.assertEqual(bykey["foldKeyPad"]["fk"],[136])
            self.assertEqual(bykey["foldKeyPad"]["fg"],"glyph:136")
            self.assertEqual(bykey["foldOpen"]["n"],0.)
            self.assertEqual(bykey["clearAnchor"][owner],"modMove")
            self.assertEqual(bykey["titleColor"][owner],"modLook")
            self.assertEqual(env["InfoFoldOwner"](Flash(type="Boat",filteredType="Boat",id=0)),"modB")
            if target:
                self.assertEqual(bykey["foldTag"]["c"],74)
                self.assertEqual(bykey["clearAnchor"]["c"],63)
            self.assertEqual(native,[("kb","Fold Action"),("pad","Pad Action")])
            env["decideAnswer"][74]="vanilla";env["dirty"]=True;env["SendTheme"](storage)
            wire=storage.sent["cmf.map.itemStyles" if target else "cmf.map.theme"]
            self.assertFalse(any(item.fields["y"] in FOLD_KEYS for item in wire))
            self.assertTrue(any(item.fields["y"]=="clearAnchor" for item in wire))

    def test_pack_checker_keys_rows_and_literal_values(self):
        for name,target in (("CMFStylePart",None),("CMFStyle","type:Boat")):
            for key,text,num,ok in (("foldTag","NAME",0,True),("foldMoreText","",0,True),
                                    ("foldLessText","[[less]]",0,True),("foldKeyKb","Action Name",0,True),
                                    ("foldKeyPad","",0,True),("foldOpen","",0,True),("foldOpen","",2,False),
                                    ("clearAnchor","pin",0,True),("clearAnchor","cursor",0,True),("clearAnchor","bad",0,False),
                                    ("foldTag","bad name",0,False),("foldOpen","unset",99,True)):
                args='"modP", \'tooltip\', '+("\'type:Boat\', " if target else "")+"'%s', \"%s\", %s"%(key,text,num)
                report=pack.Report();pack.check_script("test.ws",name+"("+args+");","modP",report,[],set())
                self.assertEqual(not report.errors,ok,(name,key,text,num,report.errors))
        for key in FOLD_KEYS:self.assertEqual(pack.theme_key_row("tooltip",key),"Map behaviour > Info box folding")
        self.assertEqual(pack.theme_key_row("tooltip","clearAnchor"),"Map behaviour > Info box moves out of the way")


class FoldHookCheckerTests(unittest.TestCase):
    def test_existing_info_fold_hook_is_allowed(self):
        script='''@wrapMethod(CMFCore)
function OnInfoFold(menu : CR4MapMenu, provider : string, open : bool)
{
    wrappedMethod(menu, provider, open);
}
'''
        report=pack.Report();pack.check_script("test.ws",script,"modP",report,[],set())
        self.assertEqual(report.errors,[])
