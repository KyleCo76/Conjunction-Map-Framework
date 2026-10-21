// CMF-owned typed FFDec emitter for the bounded diagnostic method plan.
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

public class CmfAssetAbcHost {
    static void need(boolean ok, String why) { if(!ok) throw new IllegalArgumentException(why); }
    static List<Element> children(Element e, String tag) {
        List<Element> out=new ArrayList<>();
        for(Node n=e.getFirstChild();n!=null;n=n.getNextSibling()) if(n instanceof Element && n.getNodeName().equals(tag)) out.add((Element)n);
        return out;
    }
    static int operand(ABC a,String value) {
        String[] p=value.split("\\|",-1);
        if(p[0].equals("n")) return Integer.parseInt(p[1]);
        if(p[0].equals("i")) return a.constants.getIntId(Integer.parseInt(p[1]),true);
        if(p[0].equals("s")) return a.constants.getStringId(p[1],true);
        if(p[0].equals("q")) {
            int ns=a.constants.getNamespaceId(0x16,p[1],0,true);
            return CmfAbcHost.qname(a,ns,p[2]);
        }
        throw new IllegalArgumentException("operand kind");
    }
    static InstructionDefinition definition(String name) throws Exception {
        String[] families={"","localregs.","stack.","construction.","executing.","other.","jumps.","types.","arithmetic.","comparison."};
        for(String family:families) try {
            return (InstructionDefinition)Class.forName("com.jpexs.decompiler.flash.abc.avm2.instructions."+family+name+"Ins").getConstructor().newInstance();
        } catch(ClassNotFoundException absent) { }
        throw new IllegalArgumentException("unknown typed instruction "+name);
    }
    public static void main(String[] args) throws Exception {
        need(args.length==4,"INPUT SHA PLAN OUTPUT");
        Path run=Path.of("").toAbsolutePath().normalize(), input=Path.of(args[0]), plan=Path.of(args[2]), output=Path.of(args[3]).toAbsolutePath().normalize();
        Path compiled=Path.of(CmfAssetAbcHost.class.getProtectionDomain().getCodeSource().getLocation().toURI()).toAbsolutePath().normalize();
        need(compiled.getParent().endsWith(Path.of("build","panel-runs")) && run.startsWith(compiled.getParent()) && !run.equals(compiled.getParent()),"panel-run boundary");
        need(output.startsWith(run) && !Files.exists(output),"new contained output");
        for(Path p:List.of(input,plan,output)) CmfAbcHost.noLinks(p);
        byte[] original=Files.readAllBytes(input);
        need(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(original)).equals(args[1]),"input hash");
        DocumentBuilderFactory factory=DocumentBuilderFactory.newInstance();
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl",true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities",false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities",false);
        Document document=factory.newDocumentBuilder().parse(plan.toFile());
        SWF swf=new SWF(new ByteArrayInputStream(original),null,null,null,false,false,false,null,"UTF-8",false);
        DoABC2Tag target=null;
        for(Tag t:swf.getTags()) if(t instanceof DoABC2Tag) { need(target==null,"multiple ABC"); target=(DoABC2Tag)t; }
        need(target!=null,"missing ABC"); ABC abc=target.getABC();
        int ci=abc.findClassByName("red.game.witcher3.menus.worldmap.MapMenu"); need(ci>=0,"root missing");
        List<Element> methods=children(document.getDocumentElement(),"method"); need(methods.size()==7,"bounded method count");
        for(Element m:methods) {
            String symbol=m.getAttribute("name"); need(symbol.startsWith("CMFAsset"),"owned method name");
            for(int j=1;j<abc.constants.getMultinameCount();j++) {
                Multiname existing=abc.constants.getMultiname(j);
                // References to later new methods may already be added, so
                // duplicate traits, not planned forward-reference names, decide.
                if(existing.name_index!=0 && abc.constants.getString(existing.name_index).equals(symbol)) {
                    for(Trait t:abc.instance_info.get(ci).instance_traits.traits)
                        need(t.name_index!=j,"duplicate method");
                }
            }
            int ret=operand(abc,"q||void"), name=operand(abc,"q||"+symbol);
            AVM2Code code=new AVM2Code(); Map<String,Integer> labels=new HashMap<>();
            Map<AVM2Instruction,String> branches=new LinkedHashMap<>();
            for(Element i:children(m,"i")) {
                List<Element> argsList=children(i,"arg");
                if(i.getAttribute("op").equals("Label")) { labels.put(argsList.get(0).getTextContent(),code.code.size()); continue; }
                int[] operands=new int[argsList.size()]; String jump=null;
                for(int k=0;k<operands.length;k++) {
                    String value=argsList.get(k).getTextContent();
                    if(value.startsWith("l|")) {jump=value.substring(2);operands[k]=0;} else operands[k]=operand(abc,value);
                }
                AVM2Instruction instruction=new AVM2Instruction(0L,definition(i.getAttribute("op")),operands);
                code.code.add(instruction); if(jump!=null) branches.put(instruction,jump);
            }
            code.markOffsets();
            for(Map.Entry<AVM2Instruction,String> jump:branches.entrySet()) {
                AVM2Instruction i=jump.getKey();
                i.operands[0]=Math.toIntExact(code.code.get(labels.get(jump.getValue())).getAddress()-i.getAddress()-i.getBytesLength());
            }
            MethodBody body=new MethodBody();body.setAbc(abc);
            body.max_stack=Integer.parseInt(m.getAttribute("stack"));body.max_regs=Integer.parseInt(m.getAttribute("regs"));
            body.init_scope_depth=13;body.max_scope_depth=children(m,"exception").isEmpty()?14:15;body.traits=new Traits();
            List<ABCException> exceptions=new ArrayList<>();
            for(Element e:children(m,"exception")) {
                ABCException x=new ABCException();
                x.start=(int)code.code.get(labels.get(e.getAttribute("start"))).getAddress();
                x.end=(int)code.code.get(labels.get(e.getAttribute("end"))).getAddress();
                x.target=(int)code.code.get(labels.get(e.getAttribute("target"))).getAddress();x.type_index=0;x.name_index=operand(abc,"q||CMFAssetErrorValue");
                exceptions.add(x);
            }
            body.exceptions=exceptions.toArray(new ABCException[0]);
            int mi=abc.addMethodInfo(new MethodInfo(new int[Integer.parseInt(m.getAttribute("params"))],ret,0,0,new ValueKind[0],new int[0]));
            body.method_info=mi;body.setCode(code);abc.addMethodBody(body);
            TraitMethodGetterSetter trait=new TraitMethodGetterSetter();trait.name_index=name;trait.kindType=1;trait.kindFlags=0;trait.disp_id=0;trait.method_info=mi;
            abc.instance_info.get(ci).instance_traits.addTrait(trait);
        }
        target.setModified(true);swf.setModified(true);
        try(OutputStream out=Files.newOutputStream(output,StandardOpenOption.CREATE_NEW)){swf.saveTo(out);}
        System.out.println("CMF_ASSET_METHODS_EMITTED count="+methods.size());
    }
}
