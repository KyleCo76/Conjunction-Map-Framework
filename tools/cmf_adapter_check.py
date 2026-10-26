"""Generate adapter guidance and an offline list checker from one catalogue."""
import argparse
import hashlib
import os
import stat
import subprocess
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = 'tools/cmf_adapter_list.json'
SCRIPT = 'source/adapter-check/content/scripts/local/cmfAdapterCheck.ws'
PAGE = 'source/adapter-check/page/index.html'
STRINGS = 'source/adapter-check/strings.json'
MENU = 'source/adapter-check/modCMFAdapterCheck.xml'
MOD = 'modCMFAdapterCheck'
LANGUAGES = 'ar br cn cz de en es esmx fr hu it jp kr pl ru tr ua zh'.split()
ID_BASE = 2000200900
TABLE_BEGIN = '// BEGIN generated adapter table: tools/cmf_adapter_check.py'
TABLE_END = '// END generated adapter table'
FILES_GUIDANCE = 'Get it from the CMF page on Nexus Mods (Miscellaneous files).'
REQUIRED = {'name', 'nexus', 'folders', 'providers', 'groups', 'textKeys', 'adapter', 'status', 'note'}
FOLDER = re.compile(r'mod[A-Za-z0-9_]+\Z', re.IGNORECASE)
IDENTIFIER = re.compile(r'[A-Za-z_][A-Za-z0-9_]*\Z')


def _text(value):
    return isinstance(value, str) and bool(value.strip()) and value == value.strip() and not any(ord(c) < 32 for c in value)


def validate_entries(entries):
    """Reject ambiguous identities before either consumer receives data."""
    if not isinstance(entries, list):
        raise ValueError('catalogue must be an array')
    if len(entries) > 96:
        raise ValueError('adapter string reservation 2000200900-2000200999 overflow')
    aliases, adapter_aliases, nexus_ids = {}, {}, set()
    for index, row in enumerate(entries):
        if not isinstance(row, dict) or not REQUIRED <= row.keys() or row.keys() - REQUIRED - {'minAdapter', 'aliases'}:
            raise ValueError('missing or unknown catalogue fields at row %d' % index)
        # Paste page only: other names the mod goes by (its Nexus title, its archive name).
        if 'aliases' in row:
            values = row['aliases']
            if (not isinstance(values, list) or not values or any(not _text(v) for v in values) or
                    len({v.casefold() for v in values} | {row['name'].casefold()}) != len(values) + 1):
                raise ValueError('aliases must be distinct nonempty strings other than the name')
        if not _text(row['name']) or not _text(row['note']):
            raise ValueError('name and note must be nonempty one-line strings')
        if row['status'] not in ('adapter', 'works', 'author', 'incompatible'):
            raise ValueError('unknown catalogue status')
        nexus = row['nexus']
        if nexus is not None and (type(nexus) is not int or nexus <= 0):
            raise ValueError('nexus must be a positive integer or null')
        if nexus is not None:
            if nexus in nexus_ids:
                raise ValueError('duplicate Nexus identity')
            nexus_ids.add(nexus)
        for field in ('folders', 'providers', 'groups', 'textKeys'):
            values = row[field]
            if not isinstance(values, list) or any(not _text(v) for v in values):
                raise ValueError(field + ' must be an array of nonempty strings')
            if len({v.casefold() for v in values}) != len(values):
                raise ValueError('duplicate alias in ' + field)
            pattern = FOLDER if field in ('folders', 'providers') else IDENTIFIER
            if any(not pattern.fullmatch(v) for v in values):
                raise ValueError('malformed ' + field)
        adapter = row['adapter']
        if row['status'] == 'adapter':
            if (not isinstance(adapter, dict) or set(adapter) != {'folder', 'file'} or
                    not _text(adapter['folder']) or not FOLDER.fullmatch(adapter['folder']) or
                    not _text(adapter['file']) or not row['folders'] or not row['providers']):
                raise ValueError('adapter requires folder, file, source folders and providers')
        elif adapter is not None:
            raise ValueError('only adapter rows may have adapter metadata')
        if 'minAdapter' in row:
            if row['status'] != 'adapter' or not isinstance(row['minAdapter'], str) or not re.fullmatch(r'\d+(?:\.\d+)+', row['minAdapter']):
                raise ValueError('minAdapter requires an adapter and dotted numeric version')
        if nexus is None or not row['folders']:
            if (nexus is not None or row['folders'] or row['providers'] or row['groups'] or row['textKeys'] or
                    adapter is not None or row['status'] != 'incompatible'):
                raise ValueError('only an external incompatible tool may omit Nexus and folders')
        for alias in [row['name']] + row['folders'] + row['providers']:
            key = alias.casefold()
            if key in aliases and aliases[key] != index:
                raise ValueError('duplicate source identity: ' + alias)
            aliases[key] = index
        if adapter:
            for alias in adapter.values():
                key = alias.casefold()
                if key in adapter_aliases:
                    raise ValueError('duplicate adapter identity: ' + alias)
                adapter_aliases[key] = index
    if aliases.keys() & adapter_aliases.keys():
        raise ValueError('source identity overlaps adapter identity')
    return entries


def load_catalog(path: Path) -> list[dict]:
    return validate_entries(json.loads(Path(path).read_text(encoding='utf-8')))


def guidance(row, include_files=True):
    if row['status'] != 'adapter':
        return row['name'] + ': ' + row['note']
    if 'minAdapter' in row:
        action = 'install or update %s (version %s or newer)' % (row['adapter']['file'], row['minAdapter'])
    else:
        action = 'install ' + row['adapter']['file'] + ' to keep its map features'
    return row['name'] + ': ' + action + '.' + (' ' + FILES_GUIDANCE if include_files else '')


def validate_strings(catalog):
    ids, keys = set(), set()
    for row in catalog['strings']:
        if type(row['id']) is not int or not ID_BASE <= row['id'] <= ID_BASE + 99 or row['id'] in ids or row['key'] in keys:
            raise ValueError('duplicate or out-of-range localization id/key')
        ids.add(row['id'])
        keys.add(row['key'])
    return catalog


def strings_catalog(entries):
    texts = [('panel_cmf_adapter_check', 'CMF Adapter Check'),
             ('cmf_adapter_check_enabled', 'Warn about missing CMF adapters'),
             ('cmf_adapter_check_intro', 'Some map mods may need CMF adapters to keep their map features:'),
             ('cmf_adapter_check_footer', FILES_GUIDANCE)]
    texts += [('cmf_adapter_check_mod_%03d' % i, guidance(row, include_files=False)) for i, row in enumerate(entries)]
    return validate_strings({'mod': MOD, 'idBase': ID_BASE, 'strings': [
        {'id': ID_BASE + i, 'key': key, 'text': {lang: text for lang in LANGUAGES}}
        for i, (key, text) in enumerate(texts)]})


def _ws(text):
    return json.dumps(text, ensure_ascii=True)


def table(entries):
    lines = [TABLE_BEGIN, '// Populated detector categories combine with AND; alternatives within each are OR.',
             'function CMFAdapterCheckEntries(out entries : array<SCMFAdapterCheckEntry>)', '{',
             '\tvar rowValue : SCMFAdapterCheckEntry;', '\tentries.Clear();']
    for index, row in enumerate(entries):
        if row['status'] != 'adapter' or not (row['groups'] or row['textKeys']):
            continue
        lines += ['\trowValue.providers.Clear();', '\trowValue.groups.Clear();', '\trowValue.textKeys.Clear();',
                  '\trowValue.modName = %s;' % _ws(row['name']),
                  '\trowValue.adapterFolder = %s;' % _ws(row['adapter']['folder']),
                  '\trowValue.messageKey = "cmf_adapter_check_mod_%03d";' % index]
        for field in ('providers', 'groups', 'textKeys'):
            for value in row[field]:
                literal = "'%s'" % value if field == 'groups' else _ws(value)
                lines.append('\trowValue.%s.PushBack(%s);' % (field, literal))
        lines.append('\tentries.PushBack(rowValue);')
    return '\n'.join(lines + ['}', TABLE_END])


def replace_table(script, generated):
    if script.count(TABLE_BEGIN) != 1 or script.count(TABLE_END) != 1:
        raise ValueError('script requires exactly one generated table marker pair')
    start, end = script.index(TABLE_BEGIN), script.index(TABLE_END)
    if end < start:
        raise ValueError('generated table markers out of order')
    return script[:start] + generated + script[end + len(TABLE_END):]


MENU_XML = '''<?xml version="1.0" encoding="UTF-8"?>
<UserConfig>
\t<Group id="CMFAdapterCheck" displayName="Mods.cmf_adapter_check">
\t\t<VisibleVars>
\t\t\t<Var id="CMFAdapterCheckEnabled" value="1" displayName="cmf_adapter_check_enabled" displayType="OPTIONS" tags="customNames;nonLocalized">
\t\t\t\t<OptionsArray>
\t\t\t\t\t<Option id="0" displayName="Off"><Entry varId="CMFAdapterCheckEnabled" value="0"/></Option>
\t\t\t\t\t<Option id="1" displayName="On"><Entry varId="CMFAdapterCheckEnabled" value="1"/></Option>
\t\t\t\t</OptionsArray>
\t\t\t</Var>
\t\t\t<Var id="CMFAdapterCheckKnown" value="" displayName="" displayType="TOGGLE" visibilityCondition="hideAlways"/>
\t\t</VisibleVars>
\t</Group>
</UserConfig>
'''

def page_html(entries):
    rows = [dict(row, guidance=guidance(row)) for row in entries]
    # HTML's script tokenizer sees closing tags even inside JS strings.
    data = json.dumps(rows, ensure_ascii=True, separators=(',', ':')).replace('&', '\\u0026').replace('<', '\\u003c').replace('>', '\\u003e')
    return PAGE_HTML.replace('__SCRIPT__', PAGE_JS.replace('__CATALOGUE__', data))


def render_outputs(entries: list[dict], script: str) -> dict[str, bytes]:
    validate_entries(entries)
    return {SCRIPT: replace_table(script, table(entries)).encode('ascii'),
            MENU: MENU_XML.encode('utf-8'),
            STRINGS: (json.dumps(strings_catalog(entries), indent=2, ensure_ascii=False) + '\n').encode('utf-8'),
            PAGE: page_html(entries).encode('utf-8')}


def _outputs(root):
    # Preserve handwritten CRLF bytes outside generated markers.
    return render_outputs(load_catalog(root / CATALOG), (root / SCRIPT).read_bytes().decode('ascii'))


def write(root: Path = ROOT):
    for relative, data in _outputs(Path(root)).items():
        path = Path(root) / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)


def check(root: Path) -> bool:
    try:
        return all((Path(root) / relative).is_file() and (Path(root) / relative).read_bytes() == data
                   for relative, data in _outputs(Path(root)).items())
    except (OSError, ValueError, UnicodeError, KeyError, TypeError):
        return False


DEFAULT_W3STRINGS = Path(os.environ.get('CMF_W3STRINGS', 'w3strings.py'))
MENUS = 'bin/config/r4game/user_config_matrix/pc'


def _build_destination(out):
    """Allow fresh staging only below this clone's build, without link traversal."""
    out = Path(os.path.abspath(out))
    boundary = ROOT / 'build'
    if not out.is_relative_to(boundary) or out == boundary:
        raise ValueError('output must be a fresh directory below this clone build/')
    for path in [out, *out.parents]:
        if path.exists() or path.is_symlink():
            info = path.lstat()
            if path.is_symlink() or getattr(info, 'st_file_attributes', 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT:
                raise ValueError('output path must not traverse a reparse point: ' + str(path))
        if path == ROOT:
            break
    if out.exists() and (not out.is_dir() or any(out.iterdir())):
        raise ValueError('output must be new or empty: ' + str(out))
    return out


def build(out: Path, w3strings: Path) -> dict[str, str]:
    """Stage only this optional add-on; never deploy or launch the game."""
    out = _build_destination(out)
    if not check(ROOT):
        raise ValueError('adapter-check generation is stale: run write first')
    tool = Path(w3strings or os.environ.get('CMF_W3STRINGS') or DEFAULT_W3STRINGS)
    if not tool.is_file():
        raise ValueError('w3strings.py not found: pass --w3strings')
    content = out / 'Mods' / MOD / 'content'
    (content / 'scripts/local').mkdir(parents=True)
    (out / MENUS).mkdir(parents=True)
    (content / 'scripts/local/cmfAdapterCheck.ws').write_bytes((ROOT / SCRIPT).read_bytes())
    (content.parent / 'README.md').write_bytes((ROOT / 'source/adapter-check/README.md').read_bytes())
    (out / MENUS / (MOD + '.xml')).write_bytes((ROOT / MENU).read_bytes())
    subprocess.run([sys.executable, '-B', str(tool), 'build', str(ROOT / STRINGS), '--out', str(content)], check=True)
    expected = {'Mods/' + MOD + '/content/scripts/local/cmfAdapterCheck.ws',
                'Mods/' + MOD + '/README.md', MENUS + '/' + MOD + '.xml'}
    expected.update('Mods/' + MOD + '/content/' + lang + '.w3strings' for lang in LANGUAGES)
    actual = {p.relative_to(out).as_posix() for p in out.rglob('*') if p.is_file()}
    if actual != expected:
        raise ValueError('unexpected or missing payload files: ' + str(sorted(actual ^ expected)))
    files = {relative: hashlib.sha256((out / relative).read_bytes()).hexdigest() for relative in sorted(expected)}
    (out / 'build.json').write_text(json.dumps({'mod': MOD, 'minCmfApi': 11, 'files': files}, indent=2) + '\n', encoding='utf-8')
    # Independent readback catches incomplete writes; the manifest never hashes itself.
    manifest = json.loads((out / 'build.json').read_text(encoding='utf-8'))
    for relative, digest in manifest['files'].items():
        if hashlib.sha256((out / relative).read_bytes()).hexdigest() != digest:
            raise ValueError('payload readback failed: ' + relative)
    return files


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('write')
    sub.add_parser('check')
    built = sub.add_parser('build')
    built.add_argument('--out', required=True, type=Path)
    built.add_argument('--w3strings', type=Path)
    page = sub.add_parser('page')
    page.add_argument('--out', required=True, type=Path)
    args = parser.parse_args(argv)
    if args.command == 'write':
        write(ROOT)
        print('wrote adapter table, settings XML, strings and offline page')
        return 0
    if args.command == 'check':
        ok = check(ROOT)
        print('up to date' if ok else 'out of date')
        return 0 if ok else 1
    if args.command == 'build':
        for path, digest in build(args.out, args.w3strings).items():
            print(digest, path)
        return 0
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(page_html(load_catalog(ROOT / CATALOG)).encode('utf-8'))
    print('wrote', args.out)
    return 0


PAGE_JS = r'''
"use strict";
const entries = __CATALOGUE__;
function tokenPattern(token) {
    return new RegExp("(?<![A-Za-z0-9_])" + token.replace(/[.*+?^{}()|[\]\\$]/g, "\\$&") + "(?![A-Za-z0-9_])", "gi");
}
function spans(text, token) {
    return Array.from(text.matchAll(tokenPattern(token)), match => ({start: match.index, end: match.index + match[0].length}));
}
function adapterSpans(text, rows) {
    return rows.flatMap(row => row.adapter ? [row.adapter.folder, row.adapter.file].flatMap(alias => spans(text, alias)) : []);
}
function matchMods(text, rows) {
    // Mask adapter tokens first: their download names contain source mod names.
    const original = String(text);
    const masked = original.split("");
    for (const span of adapterSpans(original, rows)) {
        for (let i = span.start; i < span.end; i++) masked[i] = " ";
    }
    const source = masked.join("");
    const candidates = [];
    rows.forEach((entry, index) => {
        for (const alias of [entry.name, ...(entry.aliases || []), ...entry.folders]) {
            for (const span of spans(source, alias)) candidates.push({...span, index});
        }
    });
    // Longest alias owns overlapping text; separate occurrences still match.
    candidates.sort((a, b) => (b.end - b.start) - (a.end - a.start) || a.start - b.start || a.index - b.index);
    const accepted = [], found = new Set();
    for (const candidate of candidates) {
        if (accepted.some(other => candidate.start < other.end && candidate.end > other.start)) continue;
        accepted.push(candidate);
        found.add(candidate.index);
    }
    return rows.flatMap((entry, index) => found.has(index) ? [{entry, adapterFound: !!entry.adapter &&
        [entry.adapter.folder, entry.adapter.file].some(alias => spans(original, alias).length > 0)}] : []);
}
function renderResults(text, rows, container, doc) {
    container.replaceChildren();
    const matches = matchMods(text, rows);
    const count = doc.createElement("p");
    count.textContent = matches.length ? matches.length + " known mod names found in pasted text." : "No known mod names found in pasted text.";
    container.appendChild(count);
    for (const {entry, adapterFound} of matches) {
        const card = doc.createElement("article");
        const heading = doc.createElement("h3");
        heading.textContent = entry.name;
        card.appendChild(heading);
        const result = doc.createElement("p");
        if (entry.status === "adapter") {
            result.textContent = adapterFound ? "Adapter name also found. This cannot confirm that it is enabled, loads, or meets the recommended version." : entry.guidance;
        } else {
            const labels = {works: "Works without an adapter. ", author: "Needs its author's CMF-ready update. ", incompatible: "Incompatible by design. "};
            result.textContent = labels[entry.status] + entry.note;
        }
        card.appendChild(result);
        if (entry.status === "adapter") {
            const note = doc.createElement("p");
            note.textContent = entry.note;
            card.appendChild(note);
            if (adapterFound && entry.minAdapter) {
                const minimum = doc.createElement("p");
                minimum.textContent = "Recommended minimum adapter download: " + entry.minAdapter + ". Check your installed version yourself.";
                card.appendChild(minimum);
            }
            const files = doc.createElement("a");
            files.textContent = "CMF adapter files on Nexus Mods";
            files.href = "https://www.nexusmods.com/witcher3/mods/14693?tab=files";
            files.rel = "noreferrer";
            card.appendChild(files);
        }
        if (entry.nexus !== null) {
            const link = doc.createElement("a");
            link.textContent = "Original mod on Nexus Mods";
            link.href = "https://www.nexusmods.com/witcher3/mods/" + entry.nexus;
            link.rel = "noreferrer";
            card.appendChild(link);
        }
        container.appendChild(card);
    }
}
if (typeof module !== "undefined") module.exports = {matchMods, entries, renderResults};
if (typeof document !== "undefined") {
    const input = document.getElementById("mod-list");
    const results = document.getElementById("results");
    input.addEventListener("input", () => renderResults(input.value, entries, results, document));
    renderResults("", entries, results, document);
}
'''

PAGE_HTML = '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<title>CMF adapter list checker</title>
<style>
:root {color-scheme:light dark; --bg:#f6f5f1; --card:#fff; --ink:#242b2b; --muted:#465853; --line:#a0afa9; --link:#165b50;}
@media (prefers-color-scheme:dark) {:root {--bg:#171c1d; --card:#20292a; --ink:#f0f1e9; --muted:#becbc4; --line:#60746e; --link:#9adbc4;}}
* {box-sizing:border-box;} body {margin:0; background:var(--bg); color:var(--ink); font:1rem/1.55 system-ui,sans-serif;}
main {max-width:58rem; margin:auto; padding:clamp(1rem,4vw,3rem);} h1 {line-height:1.15; font-size:clamp(1.8rem,5vw,2.8rem); margin:.5rem 0 1rem;}
h2 {font-size:1.3rem;} h3 {margin:0 0 .4rem;} p {margin:.5rem 0 1rem;} .eyebrow {color:var(--muted); font-size:.85rem; letter-spacing:.08em;}
label {display:block; font-weight:650; margin:1.5rem 0 .5rem;} textarea {width:100%; min-width:0; min-height:14rem; padding:.8rem; resize:vertical; border:1px solid var(--line); border-radius:.4rem; color:var(--ink); background:var(--card); font: .95rem/1.5 ui-monospace,monospace;}
textarea:focus {outline:3px solid var(--link); outline-offset:2px;} article {padding:1rem; border:1px solid var(--line); border-radius:.4rem; margin:1rem 0; background:var(--card); overflow-wrap:anywhere;}
a {color:var(--link); display:block; width:fit-content; margin:.4rem 0; overflow-wrap:anywhere;} code {overflow-wrap:anywhere;} .limit {color:var(--muted);} footer {border-top:1px solid var(--line); margin-top:2rem; padding-top:1rem;}
</style>
</head>
<body><main>
<p class="eyebrow">CONJUNCTION MAP FRAMEWORK</p>
<h1>Check your map mod list</h1>
<p>Find CMF adapter guidance from names in your Mods folder list, mods.settings, Vortex list or Mod Organizer 2 list. Paste text below; results update as you type.</p>
<p>In Windows, open a terminal in the game's Mods folder and run <code>cmd /c dir /b /ad</code>. Copy the folder names here. You can also paste quoted paths or your mod manager's display names.</p>
<p class="limit">Results are names found in pasted text, not proof that mods or adapters are enabled or loading. Disabled lines (including <code>Enabled=0</code> and MO2's minus prefix) still count. This page cannot read installed versions or your game. Unknown names are not assessed.</p>
<label for="mod-list">Your mod list</label>
<textarea id="mod-list" spellcheck="false" autocomplete="off" placeholder="modMapQuestInsight&#10;modCMFAdapterMapQuestInsight"></textarea>
<h2>Names found and guidance</h2>
<div id="results" aria-live="polite" aria-atomic="true"></div>
<footer><p class="limit">Offline and private: pasted text stays in this page. It makes no network requests. Nexus links open only when you click them. Guidance reflects the catalogue checked on October 24, 2026; tested versions in the notes are the versions tested by CMF's maintainer.</p></footer>
</main>
<script id="cmf-page-script">__SCRIPT__</script>
</body></html>
'''

if __name__ == '__main__':
    sys.exit(main())
