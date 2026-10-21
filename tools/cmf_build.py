"""CMF offline checks and evidence primitives. Production compilation is disabled."""
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import stat
import subprocess
import sys
import threading

BASELINE = "audit/implementation/baseline-2026-10-18-s01.json"
BINDINGS = ("sourceSeal", "payloadHashes", "toolchainHash", "environmentHash")


class StaleInput(ValueError):
    """An existing game input has changed since the accepted baseline."""


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def seal(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"))
                          .encode("utf-8")).hexdigest()


def load_json(path):
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("JSON document must be an object")
    return value


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")


def no_links(path):
    """Reject symlinks and Windows junctions, including existing ancestors."""
    path = Path(os.path.abspath(path))
    for item in reversed((path, *path.parents)):
        try:
            info = item.lstat()
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(info.st_mode) or (getattr(info, "st_file_attributes", 0) &
                                         getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)):
            raise ValueError(f"Link/reparse path refused: {item}")
    return path


def confined(root, path):
    root, path = no_links(root), no_links(path)
    if not path.is_relative_to(root) or path == root:
        raise ValueError(f"Path is outside required root: {path}")
    return path


def files(root):
    root = no_links(root)
    if not root.exists():
        return []
    result = []
    def fail(error):
        raise error
    for parent, dirs, names in os.walk(root, onerror=fail, followlinks=False):
        for name in dirs + names:
            no_links(Path(parent) / name)
        dirs[:] = sorted(d for d in dirs if d not in ("__pycache__", "compatability-candidates"))
        result.extend(Path(parent) / name for name in sorted(names)
                      if not name.endswith((".pyc", ".pyo")))
    return sorted(result)


def hashes(root, paths):
    return {p.relative_to(root).as_posix(): digest(p) for p in paths}


def game_hashes(root, game):
    baseline = load_json(root / BASELINE)
    expected = {"bin/x64_dx12/witcher3.exe": baseline["checkEnvironment"]["pinned"]["sha256"]}
    for item in baseline["trees"]["reference"]["files"]:
        relative = item["relativePath"].replace("\\", "/")
        # Accept repository-relative S01 names and script-root-relative test names.
        expected[relative if relative.startswith("content/content0/scripts/") else
                 "content/content0/scripts/" + relative] = item["sha256"]
    for item in baseline.get("resources", []):
        if item.get("relativePath", "").endswith("/r4gui.bundle"):
            expected[item["relativePath"]] = item["sha256"]
    for item in baseline["previousSelectedSnapshot"]:
        normalized = item["path"].replace("\\", "/")
        if "/content/content0/scripts/" in normalized:
            relative = "content/content0/scripts/" + normalized.split("/content/content0/scripts/", 1)[1]
            expected[relative] = item["sha256"]
    actual = {name: digest(confined(game, game / name)) for name in sorted(expected)}
    if expected != actual:
        raise StaleInput("Selected game inputs differ from the S01 baseline")
    scripts = game / "content/content0/scripts"
    script_names = {p.relative_to(game).as_posix() for p in files(scripts) if p.suffix.lower() == ".ws"}
    if script_names != {p for p in expected if p.endswith(".ws")}:
        raise StaleInput("Game script inventory differs from the S01 baseline")
    return actual


def binding(root, game):
    root, game = no_links(root), no_links(game)
    source = [p for sub in ("tools", "tests", "source") for p in files(root / sub)]
    source += [root / BASELINE]
    source += [root / p for p in ("docs/development/tooling.md", "docs/api/engine-bindings.md")
               if (root / p).exists()]
    toolchain = root / "source/panel/toolchain.json"
    return {"sourceSeal": seal(hashes(root, source)),
            "payloadHashes": hashes(root, files(root / "payload")),
            "toolchainHash": digest(toolchain) if toolchain.exists() else seal({"qualified": False}),
            "environmentHash": seal({"gameRoot": str(game), "files": game_hashes(root, game),
                                     "python": sys.version, "executable": str(Path(sys.executable)),
                                     "platform": platform.platform()})}


def check(root, game):
    try:
        root, game = no_links(root), no_links(game)
        bindings = binding(root, game)
        vanilla = {p.relative_to(game / "content/content0/scripts").as_posix().lower()
                   for p in files(game / "content/content0/scripts") if p.suffix.lower() == ".ws"}
        for path in files(root / "payload"):
            name = path.relative_to(root / "payload").as_posix()
            if "/content/scripts/" in name.lower():
                relative = name.lower().split("/content/scripts/", 1)[1]
                if relative in vanilla:
                    raise ValueError(f"Vanilla script replacement refused: {name}")
        return {"schemaVersion": 1, "result": "PASS", "scope": "static/source/package-footprint",
                **bindings, "warnings": ["Script-side check only; offline panel inventory is recorded separately. Engine dependency loading and behavior UNOBSERVED",
                                         "Production build route BLOCKED pending CMF toolchain qualification"]}
    except (OSError, ValueError, KeyError, TypeError) as error:
        return {"schemaVersion": 1, "result": "REFUSED", "reason": str(error)}


def build(root, game, case, run_id, output=None):
    """Reserve an immutable blocked run. No command execution route exists in S02a."""
    try:
        root, game = no_links(root), no_links(game)
        if root == game or root.is_relative_to(game) or game.is_relative_to(root / "build/probes"):
            raise ValueError("Reference/game output target refused")
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,79}", run_id):
            raise ValueError("Invalid run ID")
        if case != "bridge":
            raise ValueError("Unsupported case; S02a reserves bridge only")
        run = confined(root / "build/probes", root / "build/probes" / run_id)
        if output is not None and no_links(output) != run:
            raise ValueError("Outputs must use build/probes/<run-id>")
        checked = check(root, game)
        if checked["result"] != "PASS":
            return checked
        run.mkdir(parents=True, exist_ok=False)
        manifest = {"schemaVersion": 1, "runId": run_id, "caseId": case,
                    **{k: checked[k] for k in BINDINGS}, "observations": [], "artifacts": {},
                    "result": "BLOCKED",
                    "reason": "No reviewed CMF-specific qualified panel/compiler toolchain is implemented"}
        write_json(run / "run.json", manifest)
        return manifest
    except (OSError, ValueError, KeyError, TypeError) as error:
        return {"schemaVersion": 1, "result": "REFUSED", "reason": str(error)}


def compiler_result(returncode, stdout, marker, blob, linkage_verified):
    """Judge output evidence; retain returncode in the caller's process diagnostics.

    Successful wcc runs can exit 0 or 1. Neither code proves or disproves the
    required marker, nonempty output and independently inspected linkage.
    """
    if not marker or marker not in stdout or not Path(blob).is_file() or not Path(blob).stat().st_size:
        return "UNOBSERVED"
    return "PASS" if linkage_verified is True else "UNOBSERVED"


def run_child(argv, cwd, timeout, output_limit=1024 * 1024):
    """Developer primitive only: bounded capture; owns/kills exactly its Popen child.

    Callers must use a direct, non-spawning process. No shell, name-based kill,
    engine runner, licence flag or production build wiring is provided.
    """
    if not 0 < timeout <= 60 or not 0 < output_limit <= 1024 * 1024:
        raise ValueError("Timeout must be (0,60] seconds and output limit (0,1MiB]")
    if not isinstance(argv, list) or not argv or any(not isinstance(x, str) for x in argv):
        raise ValueError("Argument array required")
    process = subprocess.Popen(argv, cwd=no_links(cwd), shell=False, stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    output = {"stdout": bytearray(), "stderr": bytearray()}
    exceeded = threading.Event()
    def read(pipe, key):
        while block := pipe.read(4096):
            available = output_limit - len(output[key])
            output[key].extend(block[:max(available, 0)])
            if len(block) > available:
                exceeded.set()
                try:
                    process.kill()
                except OSError:
                    pass
                break
        pipe.close()
    threads = [threading.Thread(target=read, args=(getattr(process, key), key), daemon=True)
               for key in output]
    timed_out = False
    try:
        for thread in threads:
            thread.start()
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            process.kill()
            process.wait(timeout=5)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait(timeout=5)
        for thread in threads:
            thread.join(timeout=1)
    return {"pid": process.pid, "returncode": process.returncode, "timedOut": timed_out,
            "outputLimitExceeded": exceeded.is_set(),
            **{k: bytes(v).decode("utf-8", errors="replace") for k, v in output.items()}}
