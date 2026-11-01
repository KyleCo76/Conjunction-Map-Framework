"""Actual emitted animation methods; only native clock/resource/display doubles."""
import math
from pathlib import Path
import sys
from types import SimpleNamespace as Obj
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from rev13_panel_vm import PanelVM, load_case
from region_vm import Native
from region_loading_vm import Surface, RawLoader, Bitmap as LoadedBitmap
from rev13_native_display import LinkedTransform, ColorTransformValue


class Display(Surface):
    def __init__(self, **values):
        super().__init__()
        self.transform = LinkedTransform()
        self.filters = []
        self.mouseEnabled = self.mouseChildren = False
        self.__dict__.update(values)
    @property
    def alpha(self): return self.transform.colorTransform.alphaMultiplier
    @alpha.setter
    def alpha(self, value):
        t=self.transform.colorTransform; t.alphaMultiplier=value; self.transform.colorTransform=t
    @property
    def numChildren(self): return len(self.children)
    def addChildAt(self, child, index):
        self.addChild(child); self.children.remove(child); self.children.insert(int(index),child); return child
    def getChildIndex(self, child): return self.children.index(child)
    def getChildAt(self, index): return self.children[int(index)]
    def removeChildAt(self,index): return self.removeChild(self.children[int(index)])
    def getBounds(self,target):
        sx,sy=(1.,1.) if target is self else (self.scaleX,self.scaleY)
        return Obj(x=-16.*sx,y=-16.*sy,width=32.*sx,height=32.*sy,left=-16.*sx,right=16.*sx,top=-16.*sy,bottom=16.*sy)
    def localToGlobal(self,p): return Obj(x=p.x+self.x,y=p.y+self.y)
    def globalToLocal(self,p): return Obj(x=p.x-self.x,y=p.y-self.y)


class Glyph(Display):
    labels = {"a","b","c","r","Boat"} | {"s"+str(i) for i in range(12)}
    def __init__(self):
        super().__init__(); self.currentLabel=self.currentFrameLabel="Boat"; self.swaps=[]
    def gotoAndStop(self,label):
        if label not in self.labels: raise RuntimeError("native missing frame label")
        self.currentLabel=self.currentFrameLabel=label; self.swaps.append(label)


class BitmapData:
    def __init__(self,width=32,height=32,transparent=True,fill=0):
        self.width,self.height,self.transparent=width,height,transparent;self.fill=fill;self.disposed=False
    def dispose(self): self.disposed=True


class Bitmap(Display, LoadedBitmap):
    def __init__(self,data=None,*args):
        super().__init__(); self.bitmapData=data;self.smoothing=False
        if data:self.width,self.height=data.width,data.height


class Loader(RawLoader, Display):
    @property
    def content(self): return getattr(self.contentLoaderInfo,"content",None)
    def complete(self,width=32,height=32):
        self.contentLoaderInfo.width,self.contentLoaderInfo.height=width,height
        self.contentLoaderInfo.content=Bitmap(BitmapData(width,height))
        self.contentLoaderInfo.emit("complete")
    def unload(self): self.unloaded=True
    def unloadAndStop(self,flag): self.stopped=True;self.unloaded=True


class NativeColorTransform(ColorTransformValue):
    def concat(self, second):
        for channel in ("red","green","blue","alpha"):
            mult=channel+"Multiplier";offset=channel+"Offset"
            setattr(self,offset,getattr(self,offset)*getattr(second,mult)+getattr(second,offset))
            setattr(self,mult,getattr(self,mult)*getattr(second,mult))


class AnimationVM(PanelVM):
    def call_super(self,obj,key,args):
        # Native BaseListItem owns the data binding; all CMF setData work is ABC.
        if (obj.owner,key[1]) == ("HubMapPinCategoryItemRenderer","setData"):
            assert len(args) == 1, "BaseListItem.setData has one native data argument"
            obj.public(data=args[0])
            return None
        return super().call_super(obj,key,args)

    def extra_opcode(self,op,stack):
        if op not in (0xa6,0xa8):return False
        def int32(value):
            value=float(value)
            bits=0 if not math.isfinite(value) else math.trunc(value)&0xffffffff
            return bits-0x100000000 if bits>=0x80000000 else bits
        right,left=stack.pop(),stack.pop()
        stack.append(int32(left) >> (int32(right)&31) if op==0xa6 else int32(left)&int32(right))
        return True

    def get(self,obj,key):
        if isinstance(obj,str) and key[1]=="split":return self.boundary("String.split",obj.split)
        if obj is float and key[1]=="POSITIVE_INFINITY":return float("inf")
        if obj is str and key[1]=="fromCharCode":return self.boundary("String.fromCharCode",lambda code:chr(int(code)&0xffff))
        if isinstance(obj,Native) and key[1] in ("Event","IOErrorEvent","SecurityErrorEvent","Bitmap","BitmapData","Class"):
            return self.types[key[1]]
        if isinstance(obj,list) and key[1]=="splice":
            def splice(start,count):
                result=obj[int(start):int(start+count)];del obj[int(start):int(start+count)];return result
            return self.boundary("Array.splice",splice)
        if isinstance(key[0],int):
            ns=self.abc["pool"]["namespaces"][key[0]]
            if ns["uri"]=="flash.display" and key[1]=="Bitmap":return self.types["Bitmap"]
        return super().get(obj,key)


def animation_case(panel: Path):
    case = load_case(panel, "MapMenu", {})
    case.vm.__class__=AnimationVM
    case.vm.types["Math"].floor = math.floor
    case.vm.types["Math"].min = min
    case.vm.types["Math"].max = max
    def definition(name):
        assert name=="NativeGlyph", "unknown native glyph symbol"
        return Glyph
    def qualified(glyph):
        assert isinstance(glyph,Glyph), "native symbol lookup requires a glyph"
        return "NativeGlyph"
    case.vm.types.update(Number=float, Event=Obj(COMPLETE="complete",ENTER_FRAME="enterFrame",REMOVED_FROM_STAGE="removed",ADDED_TO_STAGE="added"), IOErrorEvent=Obj(IO_ERROR="ioError"), SecurityErrorEvent=Obj(SECURITY_ERROR="securityError"), Bitmap=Bitmap,BitmapData=BitmapData,Loader=lambda:Loader(case.vm),URLRequest=lambda path:Obj(url=path),ColorTransform=NativeColorTransform,ColorMatrixFilter=lambda matrix:Obj(matrix=matrix),getDefinitionByName=definition,getQualifiedClassName=qualified,Class=type)
    case.vm.instance_types={"Bitmap":Bitmap}
    host=Display()
    case.target.public(addEventListener=host.addEventListener,removeEventListener=host.removeEventListener)
    case.listeners=host.listeners
    case.host=host
    case.set_static("cmfMenu",case.target)
    container=Obj(GetVisibleAreaLocalLeftBottomPos=lambda:Obj(x=-500.,y=500.),GetVisibleAreaLocalRightTopPos=lambda:Obj(x=500.,y=-500.),globalToLocal=lambda p:p,x=0.,y=0.,scaleX=1.)
    case.target.set("mcHubMap",Obj(mcHubMapZoomContainer=Obj(mcHubMapContainer=container,x=0.,y=0.,scaleX=1.),x=0.,y=0.,scaleX=1.))
    return case


def pin(case, identity=1, **fields):
    data=case.vm.native("StaticMapPinData")
    for name,value in dict(id=identity,type="Boat",**fields).items():data.set(name,value)
    view=case.vm.native("StaticMapPinDescribed")
    host=Display(); icon=Display(); glyph=Glyph();icon.addChild(glyph)
    icon.mcPinIcon=glyph;icon.mcHighlightAlt=Display();icon.mcPinGlow=Display()
    view.set("mcIcon",icon)
    icon.parent=view
    view.public(dispatchEvent=case.vm.boundary("pin.dispatchEvent",case.events.append),data=data,selected=False,visible=True,alpha=1.,parent=host,x=0.,y=0.,localToGlobal=lambda p:Obj(x=p.x+view.read("x"),y=p.y+view.read("y")),addEventListener=host.addEventListener,removeEventListener=host.removeEventListener)
    view.set("_cmfBaseIconAlpha",1.)
    view.set("_cmfArtColor",ColorTransformValue())
    return view,data


def pin_call(case, view, name, *args):
    return case.vm.get(view, next(k for k in case.vm.methods[view.owner] if k[1]==name))(*args)


def payload_instructions(code):
    """Qualify FFDec debug records in addition to the bounded native decoder."""
    from cmf_region_loading_hooks import instructions
    # Debug-only records can occur between real instructions. Decode one native
    # instruction at a time with the same explicit operand inventory.
    one={0x04,0x05,0x06,0x08,0x25,0x2c,0x2d,0x2e,0x2f,0x31,0x40,0x41,0x42,0x49,0x53,0x55,0x56,0x58,0x59,0x5a,0x5d,0x5e,0x5f,0x60,0x61,0x62,0x63,0x66,0x68,0x6a,0x6c,0x6d,0x6e,0x6f,0x80,0x86,0x92,0x94,0xb2,0xc2,0xc3}
    two={0x32,0x43,0x44,0x45,0x46,0x4a,0x4c,0x4e,0x4f}
    out=[];pos=0
    def uint():
        nonlocal pos
        result=shift=0
        for _ in range(5):
            if pos>=len(code):raise AssertionError("truncated payload operand")
            b=code[pos];pos+=1;result|=(b&127)<<shift;shift+=7
            if b<128:return result
        raise AssertionError("overlong payload operand")
    def jump(base):
        nonlocal pos
        if pos+3>len(code):raise AssertionError("truncated payload branch")
        value=base+int.from_bytes(code[pos:pos+3],"little",signed=True);pos+=3;return value
    while pos<len(code):
        at=pos;op=code[pos];pos+=1;target=None
        if 0x0c<=op<=0x1a:target=jump(pos+3)
        elif op==0x1b:
            default=jump(at);count=uint()
            if count>4096:raise AssertionError("unbounded payload switch")
            target=tuple([default]+[jump(at) for _ in range(count+1)])
        elif op==0xef:
            pos+=1;uint();pos+=1;uint()
        elif op in (0xf0,0xf1):uint()
        elif op in (0x24,0x65):pos+=1
        elif op in one|two:
            for _ in range(2 if op in two else 1):uint()
        else:instructions(bytes([op])) # validates the original decoder's zero-operand inventory
        if pos>len(code):raise AssertionError("truncated payload instruction")
        out.append((at,code[at:pos],target))
    boundaries={at for at,raw,target in out}
    for at,raw,target in out:
        for dest in (() if target is None else target if isinstance(target,tuple) else (target,)):
            if dest not in boundaries:raise AssertionError("payload branch into operand")
    return out


def emitted_class_payload(panel, owner):
    """Resolve pool addresses but preserve instructions/branches and owned metadata.

    FFDec relocates QName indices when sealed fields are appended. This is an
    instruction comparison, not a source/decompiler-only equivalence claim.
    Unknown instructions fail in the existing bounded native decoder.
    """
    from cmf_region_build import abc
    from cmf_region_loading_hooks import instructions
    from rev13_panel_vm import class_index
    data=abc(Path(panel).read_bytes())
    cls=data["classes"][class_index(data,"red.game.witcher3.menus.worldmap."+owner)]
    pool=data["pool"]
    def ns(index):
        value=pool["namespaces"][index]
        return value["kind"],value["uri"]
    def name(index):
        if index==0:return None
        value=pool["names"][index];kind=value[0]
        if kind in (7,13):return kind,ns(value[1]),pool["strings"][value[2]]
        if kind in (9,14):return kind,pool["strings"][value[1]],tuple(ns(i) for i in pool["sets"][value[2]])
        if kind in (27,28):return kind,tuple(ns(i) for i in pool["sets"][value[1]])
        if kind==29:return kind,name(value[1]),tuple(name(i) for i in value[2])
        raise AssertionError("unqualified payload multiname "+str(value))
    named={0x04,0x05,0x45,0x46,0x4a,0x4c,0x4e,0x4f,0x59,0x5d,0x5e,0x5f,0x60,0x61,0x66,0x68,0x6a,0x80,0x86,0xb2}
    bodies={v["header"][0]:v for v in data["bodyRecords"]}
    indices={t["methodIndex"] for t in cls["traits"]+cls["staticTraits"] if t["kind"] in (1,2,3)}
    for label in ("initializer","staticInitializer"):
        if label in cls:
            indices.add(next(i for i,m in enumerate(data["methods"]) if m is cls[label]))
    result=[]
    while indices:
        index=min(indices);indices.remove(index)
        if any(v[0]==index for v in result):continue
        body=bodies.get(index)
        if body is None:continue
        decoded=payload_instructions(body["code"])
        boundaries={at:i for i,(at,raw,target) in enumerate(decoded)}
        code=[]
        for at,raw,target in decoded:
            op=raw[0];tail=raw[1:]
            if op in (0xef,0xf0,0xf1):continue
            def uint():
                nonlocal tail
                value=shift=0
                for position,b in enumerate(tail):
                    value|=(b&127)<<shift;shift+=7
                    if b<128:
                        tail=tail[position+1:];return value
                raise AssertionError("truncated payload operand")
            if target is not None:
                operand=tuple(boundaries[t] for t in target) if isinstance(target,tuple) else boundaries[target]
            elif op in named:operand=(name(uint()),tail.hex())
            elif op in (0x2c,0x2d,0x2e,0x2f,0x31):
                value=uint();operand=ns(value) if op==0x31 else pool[{0x2c:"strings",0x2d:"ints",0x2e:"uints",0x2f:"doubles"}[op]][value]
            else:
                if op==0x40:indices.add(uint())
                operand=raw[1:].hex()
            code.append((op,operand))
        result.append((index,body["header"],code,[(a,b,c,name(d),name(e)) for a,b,c,d,e in body["exceptions"]],body["traits"]))
    return cls,result
