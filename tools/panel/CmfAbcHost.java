// CMF-owned narrow FFDec API host. Never parses or changes original method code.
import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.ArrayList;
import java.util.List;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.tags.*;
import com.jpexs.decompiler.flash.abc.ABC;
import com.jpexs.decompiler.flash.abc.types.*;
import com.jpexs.decompiler.flash.abc.types.traits.*;
import com.jpexs.decompiler.flash.abc.avm2.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.localregs.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.stack.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.construction.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.executing.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.other.*;
import com.jpexs.decompiler.flash.abc.avm2.instructions.jumps.*;

public class CmfAbcHost {
    static void require(boolean ok, String message) { if (!ok) throw new IllegalArgumentException(message); }
    static void noLinks(Path p) throws IOException {
        for (Path cur = p; cur != null; cur = cur.getParent())
            if (Files.exists(cur, LinkOption.NOFOLLOW_LINKS))
                require(!Files.isSymbolicLink(cur) && !Files.readAttributes(cur, java.nio.file.attribute.BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS).isOther(), "reparse path");
    }
    static int qname(ABC abc, int ns, String name) {
        return abc.constants.getMultinameId(Multiname.createQName(false, abc.constants.getStringId(name, true), ns), true);
    }
    static void ins(AVM2Code c, InstructionDefinition def, int... operands) {
        c.code.add(new AVM2Instruction(0L, def, operands));
    }
    static void callback(ABC abc, int ns, AVM2Code code, int value) {
        int callback = abc.constants.getStringId("OnDebugEvent", true);
        int sentinel = abc.constants.getIntId(value, true);
        int call = qname(abc, ns, "callGameEvent");
        ins(code, new GetLocal0Ins()); ins(code, new PushStringIns(), callback);
        ins(code, new PushIntIns(), sentinel); ins(code, new NewArrayIns(), 1);
        ins(code, new CallPropVoidIns(), call, 2);
    }
    static void branch(AVM2Code code, List<AVM2Instruction> branches, InstructionDefinition def) {
        AVM2Instruction instruction = new AVM2Instruction(0L, def, new int[]{0});
        code.code.add(instruction); branches.add(instruction);
    }
    public static void main(String[] args) throws Exception {
        require(args.length == 5, "INPUT SHA CASE TOKEN_OR_DASH NEW_OUTPUT");
        Path input = Path.of(args[0]).toAbsolutePath().normalize();
        Path output = Path.of(args[4]).toAbsolutePath().normalize();
        Path run = Path.of("").toAbsolutePath().normalize();
        Path compiledAt = Path.of(CmfAbcHost.class.getProtectionDomain().getCodeSource().getLocation().toURI()).toAbsolutePath().normalize();
        Path boundary = compiledAt.getParent();
        require(boundary.endsWith(Path.of("build", "panel-runs")) && run.startsWith(boundary) && !run.equals(boundary), "CMF panel-run boundary required");
        require(output.startsWith(run) && !output.equals(run) && !Files.exists(output), "new contained output required");
        noLinks(input); noLinks(output);
        byte[] original = Files.readAllBytes(input);
        require(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(original)).equals(args[1]), "input hash");
        String mode = args[2];
        require(mode.equals("noop") || mode.equals("newmethod") || mode.equals("version") || mode.equals("object"), "case");
        require(!mode.equals("object") || args[3].matches("[A-Za-z0-9][A-Za-z0-9_-]{0,63}"), "run token");
        // Explicitly parse all tags; the one-argument overload reads only headers.
        // parallelRead/checkOnly/lazy/allowRenameIdentifiers are all false.
        SWF swf = new SWF(new ByteArrayInputStream(original), null, null, null,
                          false, false, false, null, "UTF-8", false);
        DoABC2Tag target = null;
        for (Tag tag : swf.getTags()) if (tag instanceof DoABC2Tag) { require(target == null, "multiple ABC"); target = (DoABC2Tag) tag; }
        require(target != null, "missing ABC");
        ABC abc = target.getABC();
        int ci = abc.findClassByName("red.game.witcher3.menus.worldmap.MapMenu");
        require(ci >= 0, "missing root class");
        if (!mode.equals("noop")) {
            String[] symbols = mode.equals("object") ? new String[]{"CMFBridgeVersion", "CMFInstallBridge", "CMFApplyPrepared"} : new String[]{"CMFBridgeVersion"};
            // Reject any existing same-name multiname, including inherited/private variants.
            for (int i = 1; i < abc.constants.getMultinameCount(); i++) {
                Multiname n = abc.constants.getMultiname(i);
                for (String symbol : symbols)
                    require(n.name_index == 0 || !abc.constants.getString(n.name_index).equals(symbol), "duplicate CMF name");
            }
            int ns = abc.constants.getNamespaceId(0x16, "", 0, false);
            require(ns > 0, "missing public namespace");
            int ret = qname(abc, ns, "void");
            for (String symbol : symbols) {
            int name = qname(abc, ns, symbol);
            int[] parameters = new int[0];
            MethodBody body = new MethodBody(); body.setAbc(abc);
            body.max_stack = mode.equals("newmethod") ? 1 : 3;
            body.max_regs = 1; body.init_scope_depth = 13; body.max_scope_depth = 14;
            body.exceptions = new ABCException[0]; body.traits = new Traits();
            AVM2Code code = new AVM2Code();
            List<AVM2Instruction> branches = new ArrayList<>();
            ins(code, new GetLocal0Ins()); ins(code, new PushScopeIns());
            if (symbol.equals("CMFBridgeVersion")) {
                if (!mode.equals("newmethod")) callback(abc, ns, code, 1129137665);
            } else if (symbol.equals("CMFInstallBridge")) {
                int channel = abc.constants.getStringId("cmf.prepared", true);
                int receiver = qname(abc, ns, "CMFApplyPrepared");
                int register = qname(abc, ns, "registerDataBinding");
                ins(code, new GetLocal0Ins()); ins(code, new PushStringIns(), channel);
                ins(code, new GetLocal0Ins()); ins(code, new GetPropertyIns(), receiver);
                ins(code, new CallPropVoidIns(), register, 2);
                callback(abc, ns, code, 1129137666);
            } else {
                parameters = new int[]{qname(abc, ns, "Object")}; body.max_regs = 2;
                ins(code, new GetLocal1Ins()); branch(code, branches, new IfFalseIns());
                ins(code, new GetLocal1Ins()); ins(code, new GetPropertyIns(), qname(abc, ns, "schema"));
                ins(code, new PushByteIns(), 1); branch(code, branches, new IfStrictNeIns());
                ins(code, new GetLocal1Ins()); ins(code, new GetPropertyIns(), qname(abc, ns, "revision"));
                ins(code, new PushByteIns(), 7); branch(code, branches, new IfStrictNeIns());
                ins(code, new GetLocal1Ins()); ins(code, new GetPropertyIns(), qname(abc, ns, "runId"));
                ins(code, new PushStringIns(), abc.constants.getStringId(args[3], true)); branch(code, branches, new IfStrictNeIns());
                callback(abc, ns, code, 1129137667);
            }
            ins(code, new ReturnVoidIns()); code.markOffsets();
            long end = code.code.get(code.code.size() - 1).getAddress();
            for (AVM2Instruction jump : branches)
                jump.operands[0] = Math.toIntExact(end - jump.getAddress() - jump.getBytesLength());
            int mi = abc.addMethodInfo(new MethodInfo(parameters, ret, 0, 0, new ValueKind[0], new int[0]));
            body.method_info = mi; body.setCode(code); abc.addMethodBody(body);
            TraitMethodGetterSetter trait = new TraitMethodGetterSetter();
            trait.name_index = name; trait.kindType = 1; trait.kindFlags = 0; trait.disp_id = 0; trait.method_info = mi;
            abc.instance_info.get(ci).instance_traits.addTrait(trait);
            }
        }
        // Exercise serialization on no-op too, while keeping every original body cached.
        target.setModified(true); swf.setModified(true);
        try (OutputStream out = Files.newOutputStream(output, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE)) { swf.saveTo(out); }
        System.out.println("CMF_ABC_EMITTED case=" + mode + " root=" + ci + " methods=" + abc.method_info.size());
    }
}
