// CMF S03e-A: bounded three-class typed append plus five exact native hooks.
import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.tags.*;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.types.*;
import com.jpexs.decompiler.flash.abc.types.traits.*;
import com.jpexs.decompiler.flash.abc.avm2.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.*;

public class CmfRegionAbcHost extends CmfRoleAbcHost {
    static int operand(ABC a,String value) {
        if(value.startsWith("r|")) {
            int id=Integer.parseInt(value.substring(2));
            need(id>0 && id<a.constants.getMultinameCount(),"original QName index range");
            need(a.constants.getMultiname(id).kind==7,"original QName kind");return id;
        }
        return CmfRoleAbcHost.operand(a,value);
    }
    static int owner(ABC a,String name) {
        need(Set.of("MapMenu","HubMap","HubMapPreview","HubMapContainer","HubMapPreviewZoomContainer",
            "LodContainer","ImageContainer","HubMapTile","HubMapTileLoader").contains(name),"bounded owner");
        int ci=a.findClassByName("red.game.witcher3.menus.worldmap."+name);need(ci>=0,"qualified owner missing");return ci;
    }
    static AVM2Code code(ABC a,Element node,Map<String,Integer> labels) throws Exception {
        AVM2Code code=new AVM2Code();Map<AVM2Instruction,String> branches=new LinkedHashMap<>();
        for(Element ins:children(node,"i")) {
            List<Element> args=children(ins,"arg");String op=ins.getAttribute("op");
            if(op.equals("Label")){need(!labels.containsKey(args.get(0).getTextContent()),"duplicate label");labels.put(args.get(0).getTextContent(),code.code.size());continue;}
            int[] operands=new int[args.size()];String jump=null;
            for(int i=0;i<operands.length;i++) {
                String value=args.get(i).getTextContent();
                if(value.startsWith("l|")){jump=value.substring(2);operands[i]=0;}else operands[i]=operand(a,value);
            }
            AVM2Instruction instruction=new AVM2Instruction(0L,definition(op),operands);code.code.add(instruction);
            if(jump!=null)branches.put(instruction,jump);
        }
        code.markOffsets();
        for(var entry:branches.entrySet()) {
            AVM2Instruction i=entry.getKey();need(labels.containsKey(entry.getValue()),"missing jump label");
            i.operands[0]=(int)(code.code.get(labels.get(entry.getValue())).getAddress()-i.getAddress()-i.getBytesLength());
        }
        return code;
    }
    static void inject(ABC abc, List<Element> hooks, boolean sentinel) throws Exception {
        Map<Integer,Map<Long,Element>> grouped=new LinkedHashMap<>();
        for(Element hook:hooks) {
            int mi=Integer.parseInt(hook.getAttribute("method"));long at=Long.parseLong(hook.getAttribute("at"));
            need(grouped.computeIfAbsent(mi,k->new LinkedHashMap<>()).put(at,hook)==null,"duplicate injection");
        }
        for(var entry:grouped.entrySet()) {
            MethodBody body=abc.findBody(entry.getKey());need(body.exceptions.length==0,"B native exception topology");
            // FFDec getCode() normalizes an unreachable jump after return in
            // native HubMap.handleInput. Preserve original raw destinations;
            // reject every other parser normalization rather than accepting it.
            byte[] rawOriginal=body.getCodeBytes().clone();
            if(sentinel) {
                need(entry.getKey()==5843,"sentinel only ApplyBatch");
                need(rawOriginal[340]==0x2d && rawOriginal[341]==2 && (rawOriginal[342]&255)==0xb0 && rawOriginal[343]==0x11,"sentinel original predicate");
            }
            AVM2Code old=body.getCode();old.markOffsets();AVM2Code next=new AVM2Code();
            Map<Long,AVM2Instruction> destinations=new HashMap<>();
            Map<AVM2Instruction,Map<Integer,Long>> branches=new LinkedHashMap<>();
            Set<Long> found=new HashSet<>();
            int consumed=0;
            for(AVM2Instruction ins:old.code) {
                long at=ins.getAddress();Element hook=entry.getValue().get(at);
                need(at==consumed && at+ins.getBytesLength()<=rawOriginal.length,"B original instruction layout");
                byte[] raw=Arrays.copyOfRange(rawOriginal,(int)at,(int)at+ins.getBytesLength());
                consumed+=ins.getBytesLength();
                List<AVM2Instruction> prefix=hook==null?List.of():code(abc,hook,new HashMap<>()).code;
                if(hook!=null)found.add(at);
                destinations.put(at,prefix.isEmpty()?ins:prefix.get(0));
                int op=ins.definition.instructionCode;Map<Integer,Long> offsets=new LinkedHashMap<>();
                need((raw[0]&255)==op,"B original opcode preserved");
                if(op>=0x0c && op<=0x1a) {
                    need(raw.length==4,"B original branch width");
                    int delta=(raw[1]&255)|((raw[2]&255)<<8)|(raw[3]<<16);
                    offsets.put(0,at+4+delta);
                } else need(Arrays.equals(raw,ins.getBytes()),"B unexpected parser normalization");
                if(op==0x1b) {
                    offsets.put(0,at+ins.operands[0]);
                    for(int n=2;n<ins.operands.length;n++)offsets.put(n,at+ins.operands[n]);
                }
                if(!offsets.isEmpty())branches.put(ins,offsets);
                next.code.addAll(prefix);
                if(sentinel && at==340) {
                    ins=new AVM2Instruction(0L,definition("PushInt"),new int[]{operand(abc,"i|1")});
                    if(prefix.isEmpty()) destinations.put(at,ins);
                    next.code.add(ins);
                    next.code.add(new AVM2Instruction(0L,definition("Negate"),new int[0]));
                } else {
                    if(sentinel && (at==342 || at==343)) {
                        AVM2Instruction replacement=new AVM2Instruction(0L,definition(at==342?"StrictEquals":"IfFalse"),at==342?new int[0]:ins.operands.clone());
                        if(branches.containsKey(ins)) branches.put(replacement,branches.remove(ins));
                        ins=replacement;
                        if(prefix.isEmpty()) destinations.put(at,ins);
                    }
                    next.code.add(ins);
                }
            }
            need(consumed==rawOriginal.length,"B complete original instruction roster");
            need(found.equals(entry.getValue().keySet()),"B injection instruction boundary");next.markOffsets();
            for(var branch:branches.entrySet())for(var offset:branch.getValue().entrySet()) {
                AVM2Instruction ins=branch.getKey();need(destinations.containsKey(offset.getValue()),"B original branch boundary");
                long base=ins.getAddress()+(ins.definition.instructionCode==0x1b?0:ins.getBytesLength());
                ins.operands[offset.getKey()]=(int)(destinations.get(offset.getValue()).getAddress()-base);
            }
            body.max_stack=Math.max(body.max_stack,16);body.setCode(next);
        }
    }
    public static void main(String[] args) throws Exception {
        need(args.length==4,"INPUT SHA PLAN OUTPUT");
        Path run=Path.of("").toAbsolutePath().normalize(),input=Path.of(args[0]),plan=Path.of(args[2]),output=Path.of(args[3]).toAbsolutePath().normalize();
        Path compiled=Path.of(CmfRegionAbcHost.class.getProtectionDomain().getCodeSource().getLocation().toURI()).toAbsolutePath().normalize();
        need(compiled.getParent().endsWith(Path.of("build","panel-runs")) && run.startsWith(compiled.getParent()) && !run.equals(compiled.getParent()),"panel-run boundary");
        need(output.startsWith(run) && !Files.exists(output),"new contained output");
        for(Path p:List.of(input,plan,output))CmfAbcHost.noLinks(p);
        byte[] original=Files.readAllBytes(input);
        need(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(original)).equals(args[1]),"input hash");
        DocumentBuilderFactory factory=DocumentBuilderFactory.newInstance();
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl",true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities",false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities",false);
        Element root=factory.newDocumentBuilder().parse(plan.toFile()).getDocumentElement();
        boolean sentinel=root.getAttribute("version").equals("role-sentinel-1");
        boolean loading=sentinel || root.getAttribute("version").equals("b1");
        if(sentinel) need(children(root,"field").isEmpty() && children(root,"method").isEmpty() && children(root,"prefix").isEmpty(),"sentinel no definitions");
        need(loading || root.getAttribute("version").equals("a1"),"bounded plan version");
        SWF swf=new SWF(new ByteArrayInputStream(original),null,null,null,false,false,false,null,"UTF-8",false);
        DoABC2Tag target=null;
        for(Tag t:swf.getTags())if(t instanceof DoABC2Tag){need(target==null,"multiple ABC");target=(DoABC2Tag)t;}
        need(target!=null,"missing ABC");ABC abc=target.getABC();
        if(!loading)need(children(root,"field").size()==4 && children(root,"method").size()==4 && children(root,"prefix").size()==4,"bounded plan roster");
        else need(children(root,"field").size()<=32 && children(root,"method").size()<=64 && children(root,"inject").size()<=96 && children(root,"prefix").isEmpty(),"bounded B plan roster");
        for(Element f:children(root,"field")) {
            int ci=owner(abc,f.getAttribute("owner"));String name=f.getAttribute("name");need(name.startsWith("CMFRegion"),"owned field");
            int ni=operand(abc,"q||"+name);
            for(Trait t:abc.instance_info.get(ci).instance_traits.traits)need(t.name_index!=ni,"duplicate field");
            TraitSlotConst field=new TraitSlotConst();field.name_index=ni;field.kindType=0;field.kindFlags=0;field.slot_id=0;
            field.type_index=f.getAttribute("type").equals("*")?0:operand(abc,"q||"+f.getAttribute("type"));field.value_index=0;
            abc.instance_info.get(ci).instance_traits.addTrait(field);
        }
        for(Element m:children(root,"method")) {
            int ci=owner(abc,m.getAttribute("owner"));String name=m.getAttribute("name");need(name.startsWith("CMFRegion"),"owned method");
            int ret=m.getAttribute("ret").equals("*")?0:operand(abc,"q||void"),ni=operand(abc,"q||"+name);
            for(Trait t:abc.instance_info.get(ci).instance_traits.traits)need(t.name_index!=ni,"duplicate method");
            Map<String,Integer> labels=new HashMap<>();AVM2Code code=code(abc,m,labels);
            MethodBody body=new MethodBody();body.setAbc(abc);body.max_stack=Integer.parseInt(m.getAttribute("stack"));body.max_regs=Integer.parseInt(m.getAttribute("regs"));
            body.init_scope_depth=Integer.parseInt(m.getAttribute("scope"));body.max_scope_depth=body.init_scope_depth+(children(m,"exception").isEmpty()?1:2);body.traits=new Traits();
            List<ABCException> exceptions=new ArrayList<>();
            for(Element e:children(m,"exception")) {
                ABCException ex=new ABCException();ex.start=(int)code.code.get(labels.get(e.getAttribute("start"))).getAddress();
                ex.end=(int)code.code.get(labels.get(e.getAttribute("end"))).getAddress();ex.target=(int)code.code.get(labels.get(e.getAttribute("target"))).getAddress();
                ex.type_index=0;ex.name_index=operand(abc,"q||CMFRegionErrorValue");exceptions.add(ex);
            }
            body.exceptions=exceptions.toArray(new ABCException[0]);
            int mi=abc.addMethodInfo(new MethodInfo(new int[Integer.parseInt(m.getAttribute("params"))],ret,0,0,new ValueKind[0],new int[0]));
            body.method_info=mi;body.setCode(code);abc.addMethodBody(body);
            TraitMethodGetterSetter trait=new TraitMethodGetterSetter();trait.name_index=ni;trait.kindType=1;trait.kindFlags=0;trait.disp_id=0;trait.method_info=mi;
            abc.instance_info.get(ci).instance_traits.addTrait(trait);
        }
        if(loading)inject(abc,children(root,"inject"),sentinel);
        for(Element prefix:children(root,"prefix")) {
            int mi=Integer.parseInt(prefix.getAttribute("method"));need(mi>=4754 && mi<=4757,"bounded forwarding hook");
            MethodBody body=abc.findBody(mi);need(body.exceptions.length==0 && body.init_scope_depth==13,"forwarding topology");
            AVM2Code old=body.getCode();old.markOffsets();AVM2Code next=new AVM2Code();
            for(AVM2Instruction i:old.code){if(i.getAddress()==2)next.code.addAll(code(abc,prefix,new HashMap<>()).code);next.code.add(i);}
            body.max_stack=Math.max(body.max_stack,mi==4757?10:7);body.setCode(next);
        }
        if(!loading) {
        MethodBody hub=abc.findBody(3706);need(hub.exceptions.length==0 && hub.init_scope_depth==12,"HubMap topology");
        AVM2Code old=hub.getCode();old.markOffsets();AVM2Code next=new AVM2Code();
        for(AVM2Instruction i:old.code) {
            if(i.getAddress()==17) {
                need(i.definition.instructionCode==0xd0,"guard receiver boundary");
                next.code.add(new AVM2Instruction(0L,definition("GetLocal0"),new int[0]));
                next.code.add(new AVM2Instruction(0L,definition("GetProperty"),new int[]{operand(abc,"q||CMFRegionGuard")}));
                next.code.add(new AVM2Instruction(0L,definition("IfTrue"),new int[]{10}));
            }
            next.code.add(i);
        }
        hub.setCode(next);
        }
        target.setModified(true);swf.setModified(true);
        try(OutputStream out=Files.newOutputStream(output,StandardOpenOption.CREATE_NEW)){swf.saveTo(out);}
        System.out.println(loading?"CMF_REGION_B_EMITTED":"CMF_REGION_A_EMITTED methods=4 fields=4 nativeBodies=5");
    }
}
