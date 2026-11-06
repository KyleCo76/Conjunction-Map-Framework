"""Write and stage CMF's Customizer add-on, modCMFCustomizer (developer only).

The add-on is a small Options page where the player sets pin sizes, how icon labels show and which pin groups hide
(plan a design note kept in the private development repository). It needs CMF API 19 (the Player setting level).

  python tools/cmf_customizer_addon.py write            rewrite source/addons/customizer/modCMFCustomizer.xml,
                                                          strings.json and the pin type lists inside the script from the
                                                          tables below and tools/cmf_pin_types.json
  python tools/cmf_customizer_addon.py check            exit 1 when either differs from its source
  python tools/cmf_customizer_addon.py build --out DIR  stage Mods/modCMFCustomizer (script, README and the 18 string
                                                          tables) and bin/config/.../pc/modCMFCustomizer.xml, plus
                                                          build.json with every SHA-256
      [--w3strings PATH]

Tables are written by the creation skill's w3strings.py (Kyle's skill path, or CMF_W3STRINGS).
Never deploys or launches anything.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from xml.sax.saxutils import quoteattr

ROOT = Path(__file__).resolve().parents[1]
MOD = 'modCMFCustomizer'
VERSION = '1.0.0'
MIN_API = 19
SRC = ROOT/'source/addons/customizer'
MENU = SRC/(MOD + '.xml')
CATALOG = SRC/'strings.json'
SCRIPT = SRC/MOD/'content/scripts/local/modcmfcustomizer.ws'
README = SRC/MOD/'README.txt'
MENUS = 'bin/config/r4game/user_config_matrix/pc'
LANGUAGES = 'ar br cn cz de en es esmx fr hu it jp kr pl ru tr ua zh'.split()
DEFAULT_TOOL = Path(os.environ.get('CMF_W3STRINGS', 'w3strings.py'))
ID_BASE = 2000250000
GROUPS = ['General', 'Quests', 'Exploration', 'NPCs', 'Buffs']
SIZES = [50, 75, 90, 110, 125, 150, 175, 200, 250, 300]
GROWTH = [110, 125, 150, 175, 200]
PIN_TYPES = ROOT/'tools/cmf_pin_types.json'
LIST_BEGIN = '// BEGIN pin type lists: written by tools/cmf_customizer_addon.py from tools/cmf_pin_types.json'
LIST_END = '// END pin type lists'
QUEST_TYPES = ['StoryQuest', 'ChapterQuest', 'SideQuest', 'MonsterQuest', 'TreasureQuest', 'QuestReturn', 'QuestBelgard',
               'QuestCoronata', 'QuestVermentino', 'QuestAvailable', 'QuestAvailableHoS', 'QuestAvailableBaW',
               'QuestAvailableLy', 'QuestObjective', 'QuestObjectiveOther']
UNKNOWN_TYPES = ['NotDiscoveredPOI', 'NotDiscoveredPOI_1', 'NotDiscoveredPOI_2', 'NotDiscoveredPOI_3']
CHUNK = 12
# Row and option texts are plain keys: the rows and separators carry the tags customDisplayName (and customNames on the
# OPTIONS rows) as Map Quest Insight's page does, so the game looks the keys up as written (PC, 2026-11-06).

BARE_STRINGS = [
    ('panel_cmf_customizer', 'CMF Customizer'),
    ('cmf_customizer_page', 'CMF Customizer'),
    ('cmf_customizer_help', 'Changes apply when you open the map'),
    ('cmf_customizer_size', 'Pin size'),
    ('cmf_customizer_quest', 'Quest marker size'),
    ('cmf_customizer_unknown', 'Undiscovered place (?) size'),
    ('cmf_customizer_standard', 'Standardize icon sizes'),
    ('cmf_customizer_on', 'On'),
    ('cmf_customizer_selected', 'Selected pin growth'),
    ('cmf_customizer_labels', 'Show icon labels'),
    ('cmf_customizer_far_header', 'Hide pin groups by zoom'),
    ('cmf_customizer_group_general', 'General'),
    ('cmf_customizer_group_quests', 'Quests'),
    ('cmf_customizer_group_exploration', 'Exploration'),
    ('cmf_customizer_group_npcs', 'NPCs'),
    ('cmf_customizer_group_buffs', 'Buffs'),
    ('cmf_customizer_off', 'Off'),
] + [('cmf_customizer_%d' % n, '%d%%' % n) for n in SIZES] + [
    ('cmf_customizer_always', 'Always'),
    ('cmf_customizer_never', 'Never'),
    ('cmf_customizer_hover', 'On hover'),
    ('cmf_customizer_default', 'Game default'),
    ('cmf_customizer_zoom_far', 'Hide when zoomed far out'),
    ('cmf_customizer_zoom_out', 'Hide when zoomed out'),
    ('cmf_customizer_zoom_hide', 'Always hide'),
]


STRINGS = BARE_STRINGS


# (var, display name key, option label keys after Off)
ROWS = [
    ('CMFCZ_Size', 'cmf_customizer_size', ['cmf_customizer_%d' % n for n in SIZES]),
    ('CMFCZ_Standard', 'cmf_customizer_standard', ['cmf_customizer_on']),
    ('CMFCZ_Quest', 'cmf_customizer_quest', ['cmf_customizer_%d' % n for n in SIZES]),
    ('CMFCZ_Unknown', 'cmf_customizer_unknown', ['cmf_customizer_%d' % n for n in SIZES]),
    ('CMFCZ_Selected', 'cmf_customizer_selected', ['cmf_customizer_%d' % n for n in GROWTH]),
    ('CMFCZ_Labels', 'cmf_customizer_labels', ['cmf_customizer_always', 'cmf_customizer_never', 'cmf_customizer_hover']),
]
FAR_ROWS = [('CMFCZ_Far_' + g, 'cmf_customizer_group_' + g.lower(),
             ['cmf_customizer_zoom_far', 'cmf_customizer_zoom_out', 'cmf_customizer_zoom_hide']) for g in GROUPS]


def options_var(var, label, labels, off='cmf_customizer_off'):
    lines = ['\t\t\t<Var id="%s" value="0" displayName=%s displayType="OPTIONS" tags="customDisplayName;customNames">'
             % (var, quoteattr(label)), '\t\t\t\t<OptionsArray>']
    for i, name in enumerate([off] + labels):
        lines.append('\t\t\t\t\t<Option id="%d" displayName=%s><Entry varId="%s" value="%d"/></Option>'
                     % (i, quoteattr(name), var, i))
    lines += ['\t\t\t\t</OptionsArray>', '\t\t\t</Var>']
    return lines


def separator(key):
    return ['\t\t\t<Var id="CMFCZHead_%s" displayName=%s displayType="SEPARATOR" tags="customDisplayName"/>'
            % (key[len('cmf_customizer_'):], quoteattr(key))]


def menu_xml():
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', '<UserConfig>',
             '\t<Group id="CMFCustomizer" displayName="Mods.cmf_customizer">', '\t\t<VisibleVars>']
    lines += separator('cmf_customizer_help')
    for var, label, labels in ROWS:
        lines += options_var(var, label, labels)
    lines += separator('cmf_customizer_far_header')
    for var, label, labels in FAR_ROWS:
        lines += options_var(var, label, labels, off='cmf_customizer_default')
    lines += ['\t\t</VisibleVars>', '\t</Group>', '</UserConfig>']
    return '\n'.join(lines) + '\n'


def catalog_json():
    data = {'mod': MOD, 'idBase': ID_BASE,
            'strings': [{'id': ID_BASE + 1 + i, 'key': key, 'text': {'en': text}} for i, (key, text) in enumerate(STRINGS)]}
    return json.dumps(data, indent=2, ensure_ascii=False) + '\n'


def type_lists():
    data = json.loads(PIN_TYPES.read_text(encoding='utf-8'))
    groups = {g: [x['name'] for x in data['types'] if x['category'] == g] for g in GROUPS}
    for names in groups.values():
        for name in names:
            if name == 'Player' or (name.startswith('User') and name[4:].isdigit()):
                raise SystemExit('a group holds %s' % name)
    return groups


def adder(name, names):
    lines = ['function %s(out list : array<name>)' % name, '{']
    lines += ["\tlist.PushBack('%s');" % n for n in names]
    lines += ['}', '']
    return lines


def list_block():
    """The functions that add pin type names (name literals: WitcherScript has no StringToName)."""
    lines = [LIST_BEGIN]
    lines += adder('CMFCZAddQuest', QUEST_TYPES) + adder('CMFCZAddUnknown', UNKNOWN_TYPES)
    groups = type_lists()
    chunks = {}
    for group in GROUPS:
        names = groups[group]
        chunks[group] = []
        for i in range(0, len(names), CHUNK):
            fn = 'CMFCZAdd%s%d' % (group, i // CHUNK + 1)
            chunks[group].append(fn)
            lines += adder(fn, names[i:i + CHUNK])
    lines += ['// The pin types of a group (General, Quests, Exploration, NPCs, Buffs). Never Player or User1 to User7.',
              'function CMFCZAddGroup(group : int, out list : array<name>)', '{']
    for number, group in enumerate(GROUPS):
        lines.append('\tif (group == %d)' % number)
        lines.append('\t{')
        lines += ['\t\t%s(list);' % fn for fn in chunks[group]]
        lines.append('\t}')
    lines += ['}', LIST_END]
    return '\n'.join(lines)


def script_text():
    text = SCRIPT.read_text(encoding='utf-8')
    start = text.index(LIST_BEGIN)
    end = text.index(LIST_END) + len(LIST_END)
    return text[:start] + list_block() + text[end:]


def up_to_date():
    return (MENU.is_file() and MENU.read_text(encoding='utf-8') == menu_xml() and
            CATALOG.is_file() and CATALOG.read_text(encoding='utf-8') == catalog_json() and
            SCRIPT.read_text(encoding='utf-8') == script_text())


def sha(data):
    return hashlib.sha256(data).hexdigest()


def tool_path(given):
    path = Path(given or os.environ.get('CMF_W3STRINGS') or DEFAULT_TOOL)
    if not path.is_file():
        raise SystemExit('w3strings.py not found: %s (pass --w3strings or set CMF_W3STRINGS)' % path)
    return path


def build(out, w3strings):
    out = Path(out)
    if out.exists() and any(out.iterdir()):
        raise SystemExit('output folder must be new or empty: %s' % out)
    if not up_to_date():
        raise SystemExit('source/addons/customizer is out of date: run "write" first')
    mod = out/'Mods'/MOD
    (mod/'content/scripts/local').mkdir(parents=True)
    (out/MENUS).mkdir(parents=True)
    (mod/'content/scripts/local/modcmfcustomizer.ws').write_bytes(SCRIPT.read_bytes())
    (mod/'README.txt').write_bytes(README.read_bytes())
    (out/MENUS/(MOD + '.xml')).write_bytes(MENU.read_bytes())
    subprocess.run([sys.executable, str(tool_path(w3strings)), 'build', str(CATALOG), '--out', str(mod/'content')], check=True)
    for lang in LANGUAGES:
        if not (mod/'content'/(lang + '.w3strings')).is_file():
            raise SystemExit('missing table %s.w3strings' % lang)
    files = {}
    for path in sorted(p for p in out.rglob('*') if p.is_file()):
        files[path.relative_to(out).as_posix()] = sha(path.read_bytes())
    (out/'build.json').write_text(json.dumps({'mod': MOD, 'version': VERSION, 'minCmfApi': MIN_API, 'files': files},
                                             indent=2) + '\n', encoding='utf-8')
    return files


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('write')
    sub.add_parser('check')
    built = sub.add_parser('build')
    built.add_argument('--out', required=True)
    built.add_argument('--w3strings')
    args = parser.parse_args(argv)
    if args.command == 'write':
        MENU.parent.mkdir(parents=True, exist_ok=True)
        MENU.write_text(menu_xml(), encoding='utf-8', newline='\n')
        CATALOG.write_text(catalog_json(), encoding='utf-8', newline='\n')
        SCRIPT.write_text(script_text(), encoding='utf-8', newline='\n')
        print('wrote', MENU.relative_to(ROOT), CATALOG.relative_to(ROOT), SCRIPT.relative_to(ROOT))
        return 0
    if args.command == 'check':
        ok = up_to_date()
        print('up to date' if ok else 'out of date')
        return 0 if ok else 1
    for path, digest in build(args.out, args.w3strings).items():
        print(digest, path)
    return 0


if __name__ == '__main__':
    sys.exit(main())
