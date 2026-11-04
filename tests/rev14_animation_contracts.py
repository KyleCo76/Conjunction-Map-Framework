"""Execute shipped API14 WS bodies with explicit native string/Flash boundaries.
This is an offline contract runner, not engine compilation or runtime acceptance.
"""
import re
import copy
from pathlib import Path
from types import SimpleNamespace as Obj
from ws_contract_runner import Array, bind, run
from test_cmf_review_bundle import body
ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")

def install(env, names):
    for match in re.finditer(r"function (\w+)\((.*?)\)\s*(?::[^\{]+)?\s*\{", CORE, re.S):
        name, signature = match.groups()
        if name not in names: continue
        parameters, outs = [], []
        for i, part in enumerate(signature.split(",") if signature.strip() else []):
            words = part.split(":", 1)[0].strip().split()
            parameters.append(words[-1])
            if "out" in words: outs.append(i)
        bound = bind(CORE, name, env, tuple(parameters), tuple(outs))
        structs = [i for i,p in enumerate(signature.split(",")) if ": SCMF" in p]
        def invoke(*args, bound=bound, structs=structs):
            args=list(args)
            for i in structs: args[i]=copy.copy(args[i])
            return bound(*args)
        invoke.out_indices = tuple(outs)
        invoke.state_env = env
        env[name] = invoke
    return env

def parser_environment():
    env = dict(StrLen=len, StrBeginsWith=str.startswith, StrEndsWith=str.endswith,
        StrFindFirst=str.find, StrMid=lambda s,i,n:s[i:i+n], StrLeft=lambda s,n:s[:n],
        StrRight=lambda s,n:s[-n:] if n else "", StrLower=str.lower, StrChar=chr,
        StrReplaceAll=str.replace, StrBeforeFirst=lambda s,d:s.split(d,1)[0],
        StrAfterFirst=lambda s,d:s.split(d,1)[1] if d in s else "", StringToFloat=float,
        StringToInt=int, IntToString=str, NameToString=str, IsNameValid=bool,
        SCMFAnimationStage=lambda:Obj(stageName="", frames="", fps="", plays="", direction="", holdFirst="", holdLast="", offset="", delay=""),
        SCMFAnimationCache=lambda:Obj(text="", canonical="", poster="", reason="", fps=0, stageCount=0, frameCount=0, valid=False),
        animationCache=Array(), animationTextClean=False, animationBlanks="", animationDirect=Array(), animationBindings=Array(), animationBindingKeys=Array(), claims=Array(),
        __ws_live_state__=("animationTextClean","animationBlanks"))
    names = set(re.findall(r"function (Animation\w+|ParseAnimation)\(", CORE))
    install(env, names | {"TrimFilterWord", "ClaimNumber", "ParseAskInt"})
    return env

def actual_parse(text: str, fps: int, env=None) -> dict:
    env = parser_environment() if env is None else env
    assert "ParseAnimation" in env, "missing shipped ParseAnimation"
    ok, canonical, poster, reason = env["ParseAnimation"](text, fps, "", "", "")
    return dict(ok=ok, canonical=canonical, poster=poster, reason=reason)


def core_environment():
    from test_cmf_rev13_map_asks import environment
    env, logs = environment()
    parser=parser_environment()
    for key,value in parser.items():
        if key != "__ws_live_state__": env[key]=value
    env.update(animationClaimIndices=Array(), animationBindings=Array(), animationBindingKeys=Array(), animationNotes=Array(), animationCounts=Array(),
        animationMenu=None, animationOptionsRead=False, animationEnabled=True, animationCap=0, animationDragPause=True, animationMemory=64,
        animationPins=Array(), animationPinKeys=Array(), revision=7, nextOrder=0,
        dirty=False, SCMFAnimationBinding=lambda:Obj(pinKey="",text="",propertyId=0,fps=0), SCMFAnimationDirect=lambda:Obj(pin=None,pinKey="",provider="",offset=0),
        FloatToString=str, CMFPlaceRadius=lambda:2.0,
        variantNow="", pinKeyNow="", placeOk=False, placeClaims=0, placeX=0.0, placeY=0.0,
        CMFSettingsDebug=lambda:False, debugTiming=False, Report=lambda *a:None, DeclareTag=lambda *a:True, CMFYesNo=lambda b:"yes" if b else "no", CMFIsVanillaCategory=lambda *a:False)
    env["__ws_live_state__"] += ("animationTextClean","animationBlanks","dirty","nextOrder","revision","animationMenu",
        "animationOptionsRead","animationEnabled","animationCap","animationDragPause","animationMemory","placeClaims","variantNow","pinKeyNow","placeOk","placeX","placeY")
    env.update(propertyWon=Array([False]*64),propertyFirst=Array([-1]*64),propertyNext=Array(),
        globalWinner=Array([-1]*64),specificWon=Array([False]*64))
    for name in ("typeKeys","tagKeys","typeHead","typeTail","typeNext","tagHead","tagTail","tagNext",
                 "globalHead","globalTail","globalNext","memoState","candidates"):env[name]=Array()
    env.update(indexBuilt=False,timingFinds=0,timingCandidates=0,timingMemoHits=0)
    names=set(re.findall(r"function (Animation\w+|ParseAnimation)\(",CORE))
    names |= {"Upsert","WithdrawClaim","EveryPinProperty","ClaimTargetOk","ClaimRejectReason",
        "CMFHasProperty","CMFOnePinProperty","CMFPropertyTextFree","CMFIsPictureProperty",
        "CMFPictureTargetOk","NewPinValueOk","SameSlot","CMFListHas","ClaimNumber",
        "CMFHasAbility","CMFKindHidden","StylePin","SetNewPinFields","WriteSlot","FindPinClaim","Find","Covers",
        "Specific","NoteLookups","PropertyWon","SendAnimationOptions","CloseAnimations",
        "SetPinContext","ClearPinContext","NoteLookupClaim","Beats","Prepare","FindOwn","BuildLookupIndex"}
    for name,value in re.findall(r"function (CMF\w+)\(\) : int \{ return (\d+); \}",CORE):
        env[name]=lambda value=int(value):value
    install(env,names)
    return env, logs


def prepare_lookup(env, claims=None):
    # Use the production prepared-index builder. Offset claims deliberately retain all owners.
    from test_cmf_rev13_map_contracts import lookup_env
    env.update(lookup_env([]))
    if claims is not None: env["winners"]=Array(claims)
    env.update(variantNow="",pinKeyNow="",placeOk=True,placeX=0.0,placeY=0.0,
        CMFPlaceRadius=lambda:2.0,CMFKindHidden=lambda t:t.startswith("NotDiscoveredPOI") or t.endswith("Disabled"))
    install(env,{"NoteLookups","PropertyWon","Find","FindPinClaim","Specific","Covers","PropertyChoice","BuildLookupIndex"})
    env["NameToFlashUInt"] = lambda name: abs(hash(name)) % 2147483647
    install(env,{"NoteLookupClaim"})
    env["NoteLookups"]()
    return env
