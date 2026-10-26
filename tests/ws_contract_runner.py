"""Execute a deliberately small, source-derived WitcherScript control-flow subset.
This is an offline contract runner, NOT a compiler or engine emulator. Native calls
and data types are supplied by each test. Unsupported statement shapes fail closed.
"""
import re
import ast
from test_cmf_review_bundle import body

class Array(list):
    def Size(self): return len(self)
    def Contains(self,value): return value in self
    def PushBack(self,value): self.append(value)
    def Clear(self): self.clear()
    def FindFirst(self,value): return self.index(value) if value in self else -1
    def Erase(self,index): self.pop(index)

# WS backslashes are ordinary text; the next matching quote ends the literal.
WS_LITERAL = r""""[^"]*"|'[^']*'"""


def expression(text):
    literals=[]
    def literal(match):
        literals.append(repr(match.group()[1:-1]))
        return "__ws_literal_"+str(len(literals)-1)+"__"
    text=re.sub(WS_LITERAL,literal,text)
    text=re.sub(r"\(float\)\s*(\w+)",r"float(\1)",text)
    text=text.replace("(int)", "").replace("&&"," and ").replace("||"," or ")
    text=re.sub(r"!(?!=)","not ",text)
    text=re.sub(r"\btrue\b","True",text)
    text=re.sub(r"\bfalse\b","False",text)
    text=" ".join(text.split())
    return re.sub(r"__ws_literal_(\d+)__",lambda match:literals[int(match.group(1))],text)

def run(source, method, env, capture=()):
    code=body(source,method)
    local_names=set(env.get("__ws_parameters__", ()))
    for declaration in re.finditer(r"\bvar\s+([\w\s,]+)\s*:",code):
        local_names.update(word.strip() for word in declaration.group(1).split(","))
    live_state=tuple(name for name in env.get("__ws_live_state__", ()) if name not in local_names)
    capture=tuple(dict.fromkeys(capture+live_state))
    # Preserve comment markers in string/name literals (notably img://).
    code=re.sub(WS_LITERAL+r"|//[^\n]*",
                lambda m: "" if m.group().startswith("//") else m.group(), code)
    # Opt-in native singleton boundary: dispatch only to the declared identical
    # source-bound core methods. Other receivers and WS literals stay untouched.
    core_receiver=env.get("__ws_core_receiver__")
    if core_receiver is not None:
        def core_call(match):
            name=match.group(1)
            if name is None or code[:match.start()].rstrip().endswith("."):return match.group()
            assert getattr(core_receiver,name,None) is env.get(name),"unqualified core receiver method: "+name
            return name+"("
        code=re.sub(WS_LITERAL+r"|(?<![\w.])theGame\s*\.\s*CMFGetCore\s*\(\s*\)\s*\.\s*(\w+)\s*\(",core_call,code)
    tokens=[];buf="";quote=None;paren=0
    for ch in code:
        if quote:
            buf+=ch
            if ch==quote:quote=None
        elif ch in ("'",'"'):quote=ch;buf+=ch
        elif ch==":" and paren==0 and (buf.strip().startswith("case ") or buf.strip()=="default"):
            tokens.append(buf.strip()+":");buf=""
        elif ch=="(":paren+=1;buf+=ch
        elif ch==")":paren-=1;buf+=ch
        elif ch in "{}" or (ch==";" and paren==0):
            if buf.strip():tokens.append(buf.strip())
            buf=""
            if ch in "{}":tokens.append(ch)
        else:buf+=ch
    assert not buf.strip(),buf
    grouped=[]
    for token in tokens:
        if token.startswith("case ") and grouped and grouped[-1].startswith("case "):
            grouped[-1]=grouped[-1][:-1]+" | "+token[5:]
        else:
            grouped.append(token)
    tokens=grouped
    lines=["def contract():"]
    if capture:lines.append("    global "+", ".join(capture))
    indent=1
    scopes=[]
    pending="block"
    guard=None
    previous=""
    for token in tokens:
        if token=="{":
            scopes.append({"kind":pending,"case":False})
            pending="block"
            indent+=1
            if guard:
                lines.append("    "*indent+"if not ("+guard+"): break")
                guard=None
            continue
        if token=="}":
            scope=scopes.pop()
            if scope["case"]:
                if not previous.startswith("return") and previous != "break":
                    raise AssertionError("Switch cases must terminate with return or break")
                indent-=1
            indent-=1
            continue
        if token.startswith("case ") or token=="default:":
            assert scopes and scopes[-1]["kind"]=="switch",token
            if scopes[-1]["case"]:
                if not previous.startswith("return") and previous != "break":
                    raise AssertionError("Switch fallthrough is unsupported")
                indent-=1
            value="_" if token=="default:" else expression(token[5:-1])
            lines.append("    "*indent+"case "+value+":")
            indent+=1
            scopes[-1]["case"]=True
            continue
        previous=token
        if token.startswith("var "):
            names,kind=token[4:].split(":",1)
            default="Array()" if kind.strip().startswith("array<") else '""' if kind.strip()=="string" else "False" if kind.strip()=="bool" else "0" if kind.strip() in ("int","float") else kind.strip()+"()" if kind.strip() in env else "None"
            for name in names.split(","):lines.append("    "*indent+name.strip()+" = "+default)
            continue
        if token.startswith("for "):
            pending="loop"
            match=re.fullmatch(r"for\s*\(\s*(\w+)\s*=\s*([^;]+);\s*\1\s*<\s*([^;]+);\s*\1\s*\+=\s*1\s*\)",token)
            if match:
                name,start,stop=match.groups()
                parts=stop.split("&&",1)
                if len(parts)>1:guard=expression(parts[1])
                translated=f"for {name} in range({expression(start)}, {expression(parts[0])}):"
            else:
                match=re.fullmatch(r"for\s*\(\s*(\w+)\s*=\s*([^;]+);\s*\1\s*>=\s*([^;]+);\s*\1\s*-=\s*1\s*\)",token)
                if not match:raise AssertionError("Unsupported for: "+token)
                name,start,stop=match.groups()
                translated=f"for {name} in range({expression(start)}, {expression(stop)} - 1, -1):"
        elif token.startswith("switch "):
            pending="switch"
            translated="match "+expression(token[7:].strip()[1:-1])+":"
        elif token.startswith("while "):
            pending="loop"
            translated="while "+expression(token[6:].strip()[1:-1])+":"
        elif token.startswith("if "):translated="if "+expression(token[3:].strip()[1:-1])+":"
        elif token.startswith("else if "):translated="elif "+expression(token[8:].strip()[1:-1])+":"
        elif token=="else":translated="else:"
        elif token.startswith("return "):translated="return "+expression(token[7:])
        elif token=="break" and any(scope["kind"]=="switch" for scope in scopes):
            nearest=max(i for i,scope in enumerate(scopes) if scope["kind"]=="switch")
            if scopes[-1]["kind"]=="switch":translated="pass"
            elif any(scope["kind"]=="loop" for scope in scopes[nearest+1:]):translated="break"
            else:raise AssertionError("nonterminal switch break not qualified")
        elif token in ("return","continue","break"):translated=token
        elif re.match(r"[\w.\[\]]+\s*(?:=|\+=|-=)",token) or re.match(r"[\w.\[\]]+\(",token):
            translated=expression(token)
        else:raise AssertionError("Unsupported statement: "+token)
        lines.append("    "*indent+translated)
    namespace=dict(env)
    # Opt-in shared object fields: a nested source body sees writes made before
    # its call, just as two methods on one WS object do. Other tests stay unchanged.
    for name, function in env.items():
        target_env=getattr(function,"state_env",None)
        if live_state and target_env is not None:
            def shared_call(*args, function=function, target_env=target_env):
                for field in live_state:target_env[field]=namespace[field]
                result=function(*args)
                for field in live_state:namespace[field]=target_env[field]
                return result
            shared_call.out_indices=getattr(function,"out_indices",())
            namespace[name]=shared_call
    namespace["Array"]=Array
    namespace["__ws_add"]=ws_add
    compiled="\n".join(lines)
    tree=ast.parse(compiled)
    tree=OutCalls(env).visit(tree)
    exec(compile(ast.fix_missing_locations(tree),"<source contract "+method+">","exec"),namespace)
    result=namespace["contract"]()
    for name in capture:env[name]=namespace[name]
    return result


class OutCalls(ast.NodeTransformer):
    """Copy source-call out values back to their actual call-site lvalues."""
    def __init__(self, env):
        self.env=env
        self.serial=0

    def visit_BinOp(self, node):
        node=self.generic_visit(node)
        if isinstance(node.op,ast.Add):
            return ast.Call(ast.Name("__ws_add",ast.Load()),[node.left,node.right],[])
        return node

    def visit_Call(self, node):
        node=self.generic_visit(node)
        fn=self.env.get(node.func.id) if isinstance(node.func,ast.Name) else None
        indices=getattr(fn,"out_indices",())
        if not indices:
            return node
        self.serial+=1
        temp="__ws_out_"+str(self.serial)
        result=[ast.NamedExpr(ast.Name(temp,ast.Store()),node)]
        for slot,index in enumerate(indices,1):
            target=node.args[index]
            value=ast.Subscript(ast.Name(temp,ast.Load()),ast.Constant(slot),ast.Load())
            if isinstance(target,ast.Name):
                result.append(ast.NamedExpr(ast.Name(target.id,ast.Store()),value))
            elif isinstance(target,ast.Attribute):
                result.append(ast.Call(ast.Name("setattr",ast.Load()),
                                       [target.value,ast.Constant(target.attr),value],[]))
            else:
                raise AssertionError("Unsupported out lvalue: "+ast.dump(target))
        result.append(ast.Subscript(ast.Name(temp,ast.Load()),ast.Constant(0),ast.Load()))
        return ast.Subscript(ast.Tuple(result,ast.Load()),ast.Constant(-1),ast.Load())


def bind(source, method, env, parameters, out_indices=(), capture=()):
    """Bind another real source body, including explicit out parameters."""
    def call(*args):
        local=dict(env,**dict(zip(parameters,args)))
        local["__ws_parameters__"]=parameters
        outs=tuple(parameters[i] for i in out_indices)
        result=run(source,method,local,capture=tuple(dict.fromkeys(capture+tuple(parameters))))
        declared=set(parameters)
        for declaration in re.finditer(r"\bvar\s+([\w\s,]+)\s*:",body(source,method)):
            declared.update(word.strip() for word in declaration.group(1).split(","))
        shared=tuple(name for name in env.get("__ws_live_state__", ()) if name not in declared)
        for name in tuple(dict.fromkeys(capture+shared)):
            env[name]=local[name]
        return (result,*(local[name] for name in outs)) if outs else result
    call.out_indices=out_indices
    call.state_env=env
    return call


def ws_add(a,b):
    # Explicitly support the numeric/string combinations used by WS diagnostics.
    if isinstance(a,str) and isinstance(b,(str,int,float)):
        return a+str(b)
    if isinstance(b,str) and isinstance(a,(int,float)):
        return str(a)+b
    return a+b
