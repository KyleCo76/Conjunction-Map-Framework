"""Approved Q7: typed, provider-owned session tags; never reconstruct a name."""
import sys
from pathlib import Path
from types import SimpleNamespace as Obj
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/"tests"),str(ROOT/"tools")]
from ws_contract_runner import Array,bind,run
import test_cmf_rev13_map_contracts as contracts
CORE=contracts.CORE
claim=contracts.claim
import cmf_pack as pack

class TypedTag(str): pass

class Flash:
    def __init__(self):self.fields={}
    def SetMemberFlashString(self,k,v):self.fields[k]=v
    def SetMemberFlashNumber(self,k,v):self.fields[k]=v
    def SetMemberFlashInt(self,k,v):self.fields[k]=int(v)
    def SetMemberFlashUInt(self,k,v):self.fields[k]=v & 0xffffffff

class FlashList(list):
    def PushBackFlashObject(self,item):self.append(item)

class Storage:
    def __init__(self):self.sent={}
    def CreateTempFlashArray(self):return FlashList()
    def CreateTempFlashObject(self):return Flash()
    def SetFlashArray(self,k,v):self.sent[k]=v

class KnownTagTests(unittest.TestCase):
    def env(self):
        env=contracts.PreparationLifecycleTests().make_env()
        for name in ("declaredTagProviders","declaredTagNames","unknownTagProviders","unknownTagTexts"):
            env[name]=Array()
        logs=[];env["CMFLog"]=logs.append
        def native_id(tag):
            self.assertIsInstance(tag,TypedTag,"only an actual typed name reaches NameToFlashUInt")
            return {"sample":42,"claimed":43,"moda.added":44}[str(tag).lower()]
        env["NameToFlashUInt"]=native_id
        for method,params,capture in (
            ("DeclareTag",("provider","tag"),("dirty",)),
            ("ResolveKnownTag",("provider","text"),()),
            ("AddedPinWordOk",("text",),()),("AddedPinTagOk",("provider","tag"),())):
            env[method]=bind(CORE,method,env,params,(),capture)
        env["WriteFoldMetadata"]=bind(CORE,"WriteFoldMetadata",env,("item","styleEntry","storage"))
        for name,params in (("CMFListHas",("list","word")),("PartChoice",("part",)),("PartKeyChoice",("part","key"))):
            env[name]=bind(CORE,name,env,params)
        return env,logs

    def test_declared_idempotent_case_insensitive_and_shared_release(self):
        env,logs=self.env()
        self.assertTrue(env["DeclareTag"]("modA",TypedTag("Sample")))
        self.assertEqual(env["ResolveKnownTag"]("style","SAMPLE"),42)
        env["dirty"]=False
        self.assertTrue(env["DeclareTag"]("modA",TypedTag("sample")))
        self.assertFalse(env["dirty"]);self.assertEqual(len(env["declaredTagNames"]),1)
        self.assertTrue(env["DeclareTag"]("modB",TypedTag("sample")))
        env["provider"]="modA"
        run(CORE,"ReleaseProvider",env,capture=("dirty",))
        self.assertEqual(env["ResolveKnownTag"]("style","sample"),42)
        env["provider"]="modB"
        run(CORE,"ReleaseProvider",env,capture=("dirty",))
        self.assertEqual(env["ResolveKnownTag"]("style","sample"),0)

    def test_claimed_and_added_names_are_retained_until_provider_release(self):
        env,logs=self.env()
        env["claim"]=claim(level=2,pinType="",pinTag=TypedTag("Claimed"))
        self.assertTrue(run(CORE,"Upsert",env,capture=("dirty","nextOrder")))
        self.assertEqual(env["ResolveKnownTag"]("style","claimed"),43)
        env["pin"]=Obj(provider="modA",tag=TypedTag("modA.added"),pinType="Boat",area="AN_Skellige",
                       x=0.,y=0.,label="added",description="",order=0)
        self.assertTrue(run(CORE,"UpsertAddedPin",env,capture=("nextOrder",)))
        self.assertEqual(env["ResolveKnownTag"]("style","MODA.ADDED"),44)
        env["provider"]="modA";env["tag"]=TypedTag("modA.added")
        self.assertTrue(run(CORE,"RemoveAddedPin",env))
        self.assertEqual(env["ResolveKnownTag"]("style","moda.added"),44)
        run(CORE,"ReleaseProvider",env,capture=("dirty",))
        self.assertEqual(env["ResolveKnownTag"]("style","claimed"),0)
        self.assertEqual(env["ResolveKnownTag"]("style","moda.added"),0)

    def test_unknown_logs_once_and_late_declaration_resolves_at_send(self):
        env,logs=self.env();store=Storage()
        env.update(storage=store,itemStylesSent=False,itemStyles=Array([
            Obj(provider="modStyle",target="tooltip",itemKind="tag",item="sample",key="alpha",text="",number=0.)]),
            itemStyleOwners=Array(["modStyle"]))
        run(CORE,"SendItemStyles",env,capture=("itemStylesSent",))
        self.assertEqual(store.sent["cmf.map.itemStyles"][0].fields["u"],0)
        run(CORE,"SendItemStyles",env,capture=("itemStylesSent",))
        self.assertEqual(len([x for x in logs if "tag unknown" in x]),1)
        env["DeclareTag"]("modA",TypedTag("sample"))
        run(CORE,"SendItemStyles",env,capture=("itemStylesSent",))
        self.assertEqual(store.sent["cmf.map.itemStyles"][0].fields["u"],42)
        self.assertFalse(env["DeclareTag"]("",TypedTag("sample")))
        self.assertFalse(env["DeclareTag"]("modA",TypedTag("")))

    def test_public_call_is_in_api_checker_and_floor(self):
        self.assertIn("CMFDeclareTag",pack.API)
        self.assertIn("CMFDeclareTag",pack.VERSION13)

        report=pack.Report()
        pack.check_script("test.ws",'CMFDeclareTag("modA", \'sample\');',"modA",report,[],set())
        self.assertEqual(report.errors,[])
        self.assertTrue(any("compiles only with CMF API 13" in n for n in report.notes))
        report=pack.Report()
        pack.check_script("test.ws",'CMFDeclareTag("other", \'sample\');',"modA",report,[],set())
        self.assertTrue(report.errors)
