"""Build CMF's settings menus and string tables into a staged overlay (developer only).

Writes, under a new output directory:
  bin/config/r4game/user_config_matrix/pc/mod0000_ConjunctionMapFramework.xml  (hidden [CMFSettings])
  bin/config/r4game/user_config_matrix/pc/modCMFTestIconPack.xml               (test toggle)
  Mods/mod0000_ConjunctionMapFramework/content/<18 languages>.w3strings        (source/strings.json)
  Mods/mod0000_ConjunctionMapFramework/content/scripts/local/cmfSettings.ws
  Mods/modCMFTestIconPack/content/<18 languages>.w3strings                     (test pack catalog)
  Mods/modCMFTestIconPack/content/scripts/local/cmfTestIconPack.ws
plus settings-stage.json with SHA-256 of every file. Tables are written by the
creation skill's w3strings.py and decoded back against their catalogs. The overlay
goes on top of a tools/cmf_pin_stage.py tree. Never deploys or launches anything.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CORE = 'mod0000_ConjunctionMapFramework'
PACK = 'modCMFTestIconPack'
MENUS = 'bin/config/r4game/user_config_matrix/pc'
LANGUAGES = 'ar br cn cz de en es esmx fr hu it jp kr pl ru tr ua zh'.split()
DEFAULT_TOOL = Path(os.environ.get('CMF_W3STRINGS', 'w3strings.py'))
CATALOGS = {CORE: ROOT/'source/strings.json', PACK: ROOT/'source/settings/modCMFTestIconPack.strings.json'}
COPIES = {
    MENUS + '/' + CORE + '.xml': ROOT/'source/settings/menus'/(CORE + '.xml'),
    MENUS + '/' + PACK + '.xml': ROOT/'source/settings/menus'/(PACK + '.xml'),
    'Mods/' + CORE + '/content/scripts/local/cmfSettings.ws': ROOT/'source/core/content/scripts/local/cmfSettings.ws',
    'Mods/' + PACK + '/content/scripts/local/cmfTestIconPack.ws':
        ROOT/'source/providers'/PACK/'content/scripts/local/cmfTestIconPack.ws',
}


def need(ok, why):
    if not ok:
        raise ValueError(why)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def run_tool(tool, *args):
    done = subprocess.run([sys.executable, '-B', str(tool)] + [str(a) for a in args] + ['--json'],
                          capture_output=True, text=True, encoding='utf-8')
    need(done.returncode == 0, 'w3strings %s failed: %s%s' % (args[0], done.stdout[-400:], done.stderr[-400:]))
    return json.loads(done.stdout)


def build_tables(tool, catalog_path, content, game):
    catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
    run_tool(tool, 'check', catalog_path)
    vanilla = ['--game', game] if game else ['--no-vanilla-check']
    report = run_tool(tool, 'build', catalog_path, '--out', content, *vanilla)
    need(report.get('ok') is True and sorted(t['language'] for t in report['tables']) == LANGUAGES,
         catalog_path.name + ': string build incomplete')
    for lang in LANGUAGES:
        rows = run_tool(tool, 'decode', content/(lang + '.w3strings'), '--keys', catalog_path)
        need(rows.get('version') == 164, lang + ': not a v164 table')
        got = sorted((r['id'], r['key'], r['text']) for r in rows['strings'])
        want = sorted((s['id'], s['key'], s['text'].get(lang, s['text']['en'])) for s in catalog['strings'])
        need(got == want, '%s %s: decoded rows differ from the catalog' % (catalog_path.name, lang))
    return {'catalog': catalog_path.relative_to(ROOT).as_posix(), 'idBase': catalog['idBase'],
            'strings': len(catalog['strings']), 'languages': len(LANGUAGES)}


def stage(tool, out, game=None):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    tool = Path(tool)
    need(tool.is_file(), 'missing string tool ' + str(tool))
    for name, source in COPIES.items():
        data = source.read_bytes()
        if name.endswith('.ws'):
            need(b'\r' not in data and all(b < 128 for b in data), name + ' must be ASCII/LF')
        target = out/name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    strings = {mod: build_tables(tool, catalog, out/'Mods'/mod/'content', game) for mod, catalog in CATALOGS.items()}
    files = {p.relative_to(out).as_posix(): digest(p) for p in sorted(out.rglob('*')) if p.is_file()}
    report = {'schema': 'cmf-settings-stage-1', 'stringTool': {'path': str(tool), 'sha256': digest(tool)},
              'vanillaLanguageKeys': 'checked' if game else 'not checked', 'strings': strings, 'files': files}
    (out/'settings-stage.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--w3strings', default=str(DEFAULT_TOOL), help="creation skill's w3strings.py")
    parser.add_argument('--game', help='read-only reference game folder for the language-key check')
    parser.add_argument('--out', required=True, help='new output directory')
    args = parser.parse_args()
    print(json.dumps(stage(args.w3strings, args.out, args.game), indent=1))


if __name__ == '__main__':
    main()
