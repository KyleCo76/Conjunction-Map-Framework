"""Write and stage CMF's optional in-game menu add-on, modCMFInGameMenu (developer only).

Version 1.5.0 requires CMF API 11 for provider presence in Loaded map mods.

The add-on is CMF's Options > Mods > Conjunction Map Framework entry: Mod order, Basic choices,
Advanced choices (9 pages), General and Status (Loaded map mods with the Screen line, and 9 "Who wins"
pages). Version 1.4.0 (CMF API 10: plans/2026-10-24-cmf-rev10-build-contract.md section 7) adds a plain description
of every row to the Options list's help box. Every
choice row is an OPTIONS row with spare placeholder choices; the add-on's script replaces them
with the loaded map mods while the game builds the page, and keeps the chosen folder name in a
hidden name var beside the row.

  python tools/cmf_menu_addon.py write            rewrite source/menu/modCMFInGameMenu.xml and
                                                  source/menu/strings.json from the tables below, and the
                                                  description block of cmfMenu.ws from source/menu/descriptions.json
  python tools/cmf_menu_addon.py check            exit 1 when any of them differs from its source
  python tools/cmf_menu_addon.py build --out DIR  stage Mods/modCMFInGameMenu (script and the 18
                                                  string tables) and bin/config/.../pc/modCMFInGameMenu.xml,
                                                  plus build.json with every SHA-256
      [--probe]                                   add the heading test page (probe copies only, never a release)

Tables are written by the creation skill's w3strings.py (--w3strings, or CMF_W3STRINGS).
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
MOD = 'modCMFInGameMenu'
VERSION = '1.5.0'
MIN_API = 11
MENU = ROOT/'source/menu'/(MOD + '.xml')
CATALOG = ROOT/'source/menu/strings.json'
SCRIPT = ROOT/'source/menu/content/scripts/local/cmfMenu.ws'
# 1.4.0: the row descriptions, written into cmfMenu.ws between the two
# marker lines. A var ending in * stands for every var that starts with the rest.
DESCRIPTIONS = ROOT/'source/menu/descriptions.json'
DESCRIPTION_BEGIN = '// BEGIN row descriptions: written by tools/cmf_menu_addon.py from source/menu/descriptions.json'
DESCRIPTION_END = '// END row descriptions'
DESCRIPTION_MAX = 160
MENUS = 'bin/config/r4game/user_config_matrix/pc'
LANGUAGES = 'ar br cn cz de en es esmx fr hu it jp kr pl ru tr ua zh'.split()
DEFAULT_TOOL = Path('w3strings.py')
# Inside CMF's own block (2000200000-2000209999); the core uses 2000200001-2000200008.
ID_BASE = 2000200100
# Choices a live row can show: Automatic, Vanilla and up to 23 map mods. The game stores the position;
# the add-on stores the folder name.
LIVE_CHOICES = 25
STATUS_MOD_ROWS = 16
ORDER_ROWS = 8

ORDINALS = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th']
GROUP_NAMES = [('General', 'General (signposts, boards, stash, Roach)'), ('Quests', 'Quests'),
               ('Places', 'Places (undiscovered and active)'), ('Completed', 'Completed places'),
               ('Services', 'Shops and services'), ('Power', 'Places of power and workbenches'),
               ('Other', 'Other (beds, herbs, stables)'), ('Added', 'Pins added by mods')]

# Row kinds: ('head', var suffix, heading text) is a SEPARATOR the script re-labels; ('pick', choice key, label) a live
# choice row with its hidden name var; ('order', n) a Mod order row; ('fixed', var, label, [choices]) a
# plain OPTIONS row; ('mods',) the Loaded map mods rows; ('win', choice key, label) a read-only Who wins row;
# ('screen',) the read-only Screen line (1.3.0, CMF API 10).
# Menu add-on 1.3.0 (CMF API 10): a row whose choice key the installed CMF does not know (Behaviour and the keys 63 to
# 68) is left out by the script, and on CMF API 9 or less the script shows the 1.2.x names of the renamed rows
# (cmfMenu.ws CMFMenuOldLabel). The moved rows Spreading, Which pin leads a spread and Label place and hiding keep
# their choice keys and show on the Map behaviour page there too.
PAGES = [
    ('CMFMenuOrder', 'cmf_order', 'Mod order',
     [('head', 'Order', 'Which map mod wins inside CMF (not the game\'s load order)')] +
     [('order', n) for n in range(1, ORDER_ROWS + 1)]),
    # No headings on Basic: the game draws its jump list beside a page only when the page has heading rows (menu
    # launch 4), and Kyle chose a plain list without it (2026-10-22 06:26Z: "It's useless and takes up space").
    ('CMFMenuBasic', 'cmf_basic', 'Basic choices', [
        ('pick', 'Icons', 'Pin icons'),
        ('pick', 'Colours', 'Pin colours'),
        ('pick', 'Size', 'Pin size'),
        ('pick', 'Labels', 'Pin labels'),
        ('pick', 'Legend', 'Legend and filter tabs'),
        ('pick', 'Hidden', 'Hidden pins'),
        ('pick', 'Look', 'Map look'),
        ('pick', 'Painting', 'Map painting'),
        ('pick', 'Drawings', 'Drawings on the map'),
        ('pick', 'Clicks', 'Pin clicks'),
        ('pick', 'Movement', 'Map movement'),
        ('pick', 'Behaviour', 'Map behaviour')]),
    ('CMFMenuAdvIcons', 'cmf_advanced.cmf_adv_icons', 'Pin icons',
     [('pick', 'Icons_' + key, label) for key, label in GROUP_NAMES] +
     # Menu add-on 1.5.0 (CMF API 11): the script hides the row on an older CMF.
     [('pick', 'Icons_Undiscovered', 'Undiscovered places (?)')]),
    ('CMFMenuAdvColours', 'cmf_advanced.cmf_adv_colours', 'Pin colours',
     [('pick', 'Colours_' + key, label) for key, label in GROUP_NAMES]),
    ('CMFMenuAdvSize', 'cmf_advanced.cmf_adv_size', 'Pin size and labels', [
        ('pick', 'Size_Scale', 'Pin size'),
        ('pick', 'Labels_Text', 'Level tags and label text')]),
    ('CMFMenuAdvLegend', 'cmf_advanced.cmf_adv_legend', 'Legend and filters', [
        ('pick', 'Legend_Rows', 'Legend rows'),
        ('pick', 'Legend_Names', 'Row names'),
        ('pick', 'Legend_Tabs', 'Tab names'),
        ('pick', 'Hidden_Ignore1', 'Ignore hidden pins from (1st)'),
        ('pick', 'Hidden_Ignore2', 'Ignore hidden pins from (2nd)'),
        ('pick', 'Hidden_Ignore3', 'Ignore hidden pins from (3rd)')]),
    ('CMFMenuAdvLook', 'cmf_advanced.cmf_adv_look', 'Map look', [
        ('pick', 'Look_Frames', 'Frames and panels'),
        ('pick', 'Look_Legend', 'Legend'),
        ('pick', 'Look_InfoBox', 'Info box'),
        ('pick', 'Look_InfoText', 'Info box text'),
        ('pick', 'Look_Hints', 'Key hints'),
        ('pick', 'Look_PinText', 'Pin text style')]),
    ('CMFMenuAdvMovement', 'cmf_advanced.cmf_adv_movement', 'Map movement', [
        ('pick', 'Movement_Area', 'Map area'),
        ('pick', 'Movement_Pan', 'Pan and zoom feel'),
        ('pick', 'Movement_ZoomOut', 'Zoom out to the whole region'),
        ('pick', 'Movement_Controller', 'Controller crosshair'),
        ('pick', 'Movement_Opening', 'Opening and closing'),
        # Menu add-on 1.2.0 (CMF API 9): the script hides this row and the two picture rows on an older CMF.
        ('pick', 'Movement_View', 'Opening view'),
        ('pick', 'Movement_Wide', 'Fill wide screens')]),
    # Menu add-on 1.3.0 (CMF API 10): the behaviour rows (behaviour spec 5.5; the last row from the ultrawide spec 7).
    ('CMFMenuAdvBehaviour', 'cmf_advanced.cmf_adv_behaviour', 'Map behaviour', [
        ('pick', 'Size_Spread', 'Stacked pins spread out'),
        ('pick', 'Size_Lead', 'Which pin leads a spread'),
        ('pick', 'Labels_Place', 'Label place and hiding'),
        ('pick', 'Behaviour_InfoBoxDodge', 'Info box moves out of the way'),
        ('pick', 'Behaviour_InfoBoxHeight', 'Info box height and scrolling'),
        ('pick', 'Behaviour_HoverNames', 'Names only on hover')]),
    ('CMFMenuAdvPainting', 'cmf_advanced.cmf_adv_painting', 'Map painting', [
        ('pick', 'Painting_WhiteOrchard', 'White Orchard'),
        ('pick', 'Painting_WhiteOrchardWinter', 'White Orchard (winter)'),
        ('pick', 'Painting_Velen', 'Velen and Novigrad'),
        ('pick', 'Painting_Skellige', 'Skellige'),
        ('pick', 'Painting_KaerMorhen', 'Kaer Morhen'),
        ('pick', 'Painting_Vizima', 'Vizima'),
        ('pick', 'Painting_IsleOfMists', 'Isle of Mists'),
        ('pick', 'Painting_Spiral', 'The Spiral'),
        ('pick', 'Painting_Toussaint', 'Toussaint'),
        ('pick', 'Painting_World', 'World overview'),
        ('pick', 'Painting_Crests', 'Region crests and markers')]),
    ('CMFMenuAdvClicks', 'cmf_advanced.cmf_adv_clicks', 'Clicks and drawings', [
        ('pick', 'Clicks_Pins', 'Pin clicks'),
        ('pick', 'Drawings_Ignore1', 'Leave out drawings from (1st)'),
        ('pick', 'Drawings_Ignore2', 'Leave out drawings from (2nd)'),
        ('pick', 'Drawings_Ignore3', 'Leave out drawings from (3rd)')]),
    ('CMFMenuGeneral', 'cmf_general', 'General', [
        ('fixed', 'CMFFallthrough', 'If the chosen mod has nothing for a pin',
         ['Use the next mod in order', 'Use Vanilla']),
        ('fixed', 'CMFReset', 'Reset every CMF choice', ['Keep my choices', 'Reset now (reopen Options to see)']),
        ('fixed', 'CMFReport', 'Write the who-wins report to the log', ['Off', 'On'])]),
    # 1.3.0: the Screen line goes last. Above the heading it made the game list the page's two parts in the
    # right-hand column (start B, 2026-10-24).
    ('CMFMenuStatusMods', 'cmf_status.cmf_status_mods', 'Loaded map mods',
     [('head', 'Mods', 'Map mods loaded'), ('mods',), ('screen',)]),
    ('CMFMenuWinIcons', 'cmf_status.cmf_win_icons', 'Who wins: pin icons',
     [('win', 'Icons_' + key, label) for key, label in GROUP_NAMES] +
     [('win', 'Icons_Undiscovered', 'Undiscovered places (?)')]),
    ('CMFMenuWinColours', 'cmf_status.cmf_win_colours', 'Who wins: pin colours',
     [('win', 'Colours_' + key, label) for key, label in GROUP_NAMES]),
    ('CMFMenuWinSize', 'cmf_status.cmf_win_size', 'Who wins: pin size and labels', [
        ('win', 'Size_Scale', 'Pin size'),
        ('win', 'Labels_Text', 'Level tags and label text')]),
    ('CMFMenuWinLegend', 'cmf_status.cmf_win_legend', 'Who wins: legend and filters', [
        ('win', 'Legend_Rows', 'Legend rows'),
        ('win', 'Legend_Names', 'Row names'),
        ('win', 'Legend_Tabs', 'Tab names'),
        ('win', 'Hidden', 'Hidden pins')]),
    ('CMFMenuWinLook', 'cmf_status.cmf_win_look', 'Who wins: map look', [
        ('win', 'Look_Frames', 'Frames and panels'),
        ('win', 'Look_Legend', 'Legend'),
        ('win', 'Look_InfoBox', 'Info box'),
        ('win', 'Look_InfoText', 'Info box text'),
        ('win', 'Look_Hints', 'Key hints'),
        ('win', 'Look_PinText', 'Pin text style')]),
    ('CMFMenuWinMovement', 'cmf_status.cmf_win_movement', 'Who wins: map movement', [
        ('win', 'Movement_Area', 'Map area'),
        ('win', 'Movement_Pan', 'Pan and zoom feel'),
        ('win', 'Movement_ZoomOut', 'Zoom out to the whole region'),
        ('win', 'Movement_Controller', 'Controller crosshair'),
        ('win', 'Movement_Opening', 'Opening and closing'),
        ('win', 'Movement_View', 'Opening view'),
        ('win', 'Movement_Wide', 'Fill wide screens')]),
    ('CMFMenuWinBehaviour', 'cmf_status.cmf_win_behaviour', 'Who wins: map behaviour', [
        ('win', 'Size_Spread', 'Stacked pins spread out'),
        ('win', 'Size_Lead', 'Which pin leads a spread'),
        ('win', 'Labels_Place', 'Label place and hiding'),
        ('win', 'Behaviour_InfoBoxDodge', 'Info box moves out of the way'),
        ('win', 'Behaviour_InfoBoxHeight', 'Info box height and scrolling'),
        ('win', 'Behaviour_HoverNames', 'Names only on hover')]),
    ('CMFMenuWinPainting', 'cmf_status.cmf_win_painting', 'Who wins: map painting', [
        ('win', 'Painting_WhiteOrchard', 'White Orchard'),
        ('win', 'Painting_WhiteOrchardWinter', 'White Orchard (winter)'),
        ('win', 'Painting_Velen', 'Velen and Novigrad'),
        ('win', 'Painting_Skellige', 'Skellige'),
        ('win', 'Painting_KaerMorhen', 'Kaer Morhen'),
        ('win', 'Painting_Vizima', 'Vizima'),
        ('win', 'Painting_IsleOfMists', 'Isle of Mists'),
        ('win', 'Painting_Spiral', 'The Spiral'),
        ('win', 'Painting_Toussaint', 'Toussaint'),
        ('win', 'Painting_World', 'World overview'),
        ('win', 'Painting_Crests', 'Region crests and markers')]),
    ('CMFMenuWinClicks', 'cmf_status.cmf_win_clicks', 'Who wins: clicks and drawings', [
        ('win', 'Clicks_Pins', 'Pin clicks'),
        ('win', 'Drawings', 'Drawings on the map')]),
]
# Page titles for the nodes above the pages.
NODE_TITLES = {'cmf_advanced': 'Advanced choices', 'cmf_status': 'Status'}
# Page titles added after the first release, in the order they were added. Their string IDs follow every earlier
# string (the script strings included), so no ID ever moves or is reused: 1.3.0 Map behaviour and its Who wins page.
LATER_TITLES = ['cmf_adv_behaviour', 'cmf_win_behaviour']
# The remembered list of map mods (title screen), one folder name per value; a one-segment group with no
# visible rows, so the game adds no Options entry for it.
KNOWN_GROUP = 'CMFMenuKnown'
KNOWN_PRESENT_GROUP = 'CMFMenuKnownPresent'
KNOWN_SLOTS = 24
# Words the script reads from the tables (the rule glyphs a .ws file cannot hold: scripts stay ASCII).
SCRIPT_STRINGS = [
    ('cmf_menu_rule_box', '\u2550' * 12),
    ('cmf_menu_rule_dash', '\u2014' * 12),
]
# Probe builds only: a page of four heading rows, one per heading style the script can write (CMFMenuHeading),
# so Kyle can pick one in the game. Its title string follows the catalog's last ID.
HEAD_TEST_GROUP = 'CMFMenuHeadTest'
HEAD_TEST_PATH = 'cmf_headtest'
HEAD_TEST_TITLE = 'Heading styles (test)'
HEAD_TEST_STYLES = 4


def option_xml(var, labels):
    lines = ['\t\t\t\t<OptionsArray>']
    for i, label in enumerate(labels):
        lines.append('\t\t\t\t\t<Option id="%d" displayName=%s><Entry varId="%s" value="%d"/></Option>'
                     % (i, quoteattr(label), var, i))
    lines.append('\t\t\t\t</OptionsArray>')
    return lines


def options_var(var, label, labels, value='0'):
    return (['\t\t\t<Var id="%s" value="%s" displayName=%s displayType="OPTIONS" '
             'tags="nonLocalizedName;customNames;nonLocalized">' % (var, value, quoteattr(label))] +
            option_xml(var, labels) + ['\t\t\t</Var>'])


def hidden_var(var):
    return ['\t\t\t<Var id="%s" value="" displayName="" displayType="TOGGLE" visibilityCondition="hideAlways"/>' % var]


def page_vars(rows):
    """The page's vars in menu order (hidden name vars last), as XML lines."""
    lines, hidden = [], []
    placeholders = [str(i) for i in range(LIVE_CHOICES)]
    for row in rows:
        kind = row[0]
        if kind == 'head':
            lines.append('\t\t\t<Var id="CMFHead_%s" displayName=%s displayType="SEPARATOR" tags="nonLocalizedName"/>'
                         % (row[1], quoteattr(row[2])))
        elif kind == 'pick':
            lines += options_var('CMFPick_' + row[1], row[2], placeholders)
            hidden += hidden_var('CMFName_' + row[1])
        elif kind == 'order':
            lines += options_var('CMFOrder%d' % row[1], ORDINALS[row[1] - 1], placeholders)
            hidden += hidden_var('CMFOrderName%d' % row[1])
        elif kind == 'fixed':
            lines += options_var(row[1], row[2], row[3])
        elif kind == 'mods':
            for n in range(1, STATUS_MOD_ROWS + 1):
                lines += options_var('CMFStatusMod%d' % n, 'Map mod %d' % n, ['-', '-'])
        elif kind == 'win':
            lines += options_var('CMFWin_' + row[1], row[2], ['-', '-'])
        elif kind == 'screen':
            lines += options_var('CMFStatusScreen', 'Screen', ['-', '-'])
        else:
            raise ValueError(kind)
    return lines + hidden


def menu_xml(probe=False):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', '<UserConfig>']
    pages = list(PAGES)
    if probe:
        pages.append((HEAD_TEST_GROUP, HEAD_TEST_PATH, HEAD_TEST_TITLE,
                      [('head', 'Test_%d' % n, 'Heading style %d' % (n + 1)) for n in range(HEAD_TEST_STYLES)]))
    for group, path, _title, rows in pages:
        lines.append('\t<Group id="%s" displayName="Mods.cmf_menu.%s">' % (group, path))
        lines.append('\t\t<VisibleVars>')
        lines += page_vars(rows)
        lines.append('\t\t</VisibleVars>')
        lines.append('\t</Group>')
    lines.append('\t<Group id="%s" displayName="cmf_menu_known">' % KNOWN_GROUP)
    lines.append('\t\t<VisibleVars>')
    for n in range(1, KNOWN_SLOTS + 1):
        lines += hidden_var('CMFKnown%d' % n)
    lines.append('\t\t</VisibleVars>')
    lines.append('\t</Group>')
    lines.append('\t<Group id="%s" displayName="cmf_menu_known_present">' % KNOWN_PRESENT_GROUP)
    lines.append('\t\t<VisibleVars>')
    for n in range(1, KNOWN_SLOTS + 1):
        lines += hidden_var('CMFKnownPresent%d' % n)
    lines.append('\t\t</VisibleVars>')
    lines.append('\t</Group>')
    lines.append('</UserConfig>')
    return '\n'.join(lines) + '\n'


def catalog(probe=False):
    keys = []
    seen = set()
    later = {}
    for _group, path, title, _rows in PAGES:
        segments = path.split('.')
        for segment in segments[:-1]:
            if segment not in seen:
                seen.add(segment)
                keys.append(('panel_' + segment, NODE_TITLES[segment]))
        if segments[-1] in LATER_TITLES:
            later[segments[-1]] = title
        else:
            keys.append(('panel_' + segments[-1], title))
    keys += SCRIPT_STRINGS
    keys += [('panel_' + segment, later[segment]) for segment in LATER_TITLES]
    keys.append(('cmf_menu_support_present', 'CMF support present'))
    if probe:
        keys.append(('panel_' + HEAD_TEST_PATH, HEAD_TEST_TITLE))
    return {
        'mod': MOD,
        'idBase': ID_BASE,
        'strings': [{'id': ID_BASE + 1 + i, 'key': key, 'text': {'en': text}} for i, (key, text) in enumerate(keys)],
    }


def catalog_json(probe=False):
    data = catalog(probe)
    lines = ['{', '  "mod": "%s",' % data['mod'], '  "idBase": %d,' % data['idBase'], '  "strings": [']
    entries = ['    ' + json.dumps(s, ensure_ascii=False) for s in data['strings']]
    lines.append(',\n'.join(entries))
    lines += ['  ]', '}']
    return '\n'.join(lines) + '\n'


def descriptions():
    """(var, text) for every described row, in the order of descriptions.json."""
    data = json.loads(DESCRIPTIONS.read_text(encoding='utf-8'))
    return [(row['var'], row['text']) for page in data['pages'] for row in page['rows']]


def description_ws():
    """The CMFMenuDescription function, between the marker lines."""
    exact, prefixes = [], []
    for var, text in descriptions():
        if '"' in text or '\\' in text or not text.isascii():
            raise ValueError('description of %s must be plain ASCII without quotes or backslashes' % var)
        (prefixes if var.endswith('*') else exact).append((var.rstrip('*'), text))
    lines = [DESCRIPTION_BEGIN,
             '// 1.4.0: the plain description of a row, shown first in the help box ("" for a row without one).',
             'function CMFMenuDescription(varName : name) : string',
             '{',
             '\tvar varText : string;',
             '\tvarText = NameToString(varName);']
    for prefix, text in prefixes:
        lines += ['\tif (StrBeginsWith(varText, "%s"))' % prefix, '\t{', '\t\treturn "%s";' % text, '\t}']
    lines += ['\tswitch (varName)', '\t{']
    texts = []
    for _var, text in exact:
        if text not in texts:
            texts.append(text)
    for text in texts:
        for var, other in exact:
            if other == text:
                lines.append("\t\tcase '%s':" % var)
        lines.append('\t\t\treturn "%s";' % text)
    lines += ['\t}', '\treturn "";', '}', DESCRIPTION_END]
    return '\n'.join(lines)


def script_text():
    """cmfMenu.ws with its description block written from descriptions.json."""
    text = SCRIPT.read_text(encoding='utf-8')
    start = text.index(DESCRIPTION_BEGIN)
    end = text.index(DESCRIPTION_END) + len(DESCRIPTION_END)
    return text[:start] + description_ws() + text[end:]


def up_to_date():
    return (MENU.read_text(encoding='utf-8') == menu_xml() and CATALOG.read_text(encoding='utf-8') == catalog_json()
            and SCRIPT.read_text(encoding='utf-8') == script_text())


def choice_rows():
    """Every choice key a row of the menu names, in menu order."""
    return [row[1] for _g, _p, _t, rows in PAGES for row in rows if row[0] == 'pick']


def sha(data):
    return hashlib.sha256(data).hexdigest()


def tool_path(given):
    for candidate in (given, os.environ.get('CMF_W3STRINGS'), DEFAULT_TOOL):
        if candidate and Path(candidate).is_file():
            return Path(candidate)
    raise SystemExit('w3strings.py not found: pass --w3strings or set CMF_W3STRINGS')


def build(out, w3strings, probe=False):
    out = Path(out)
    if out.exists() and any(out.iterdir()):
        raise SystemExit('output folder must be new or empty: %s' % out)
    if not up_to_date():
        raise SystemExit('source/menu is out of date: run "write" first')
    mod = out/'Mods'/MOD
    (mod/'content/scripts/local').mkdir(parents=True)
    (out/MENUS).mkdir(parents=True)
    (mod/'content/scripts/local/cmfMenu.ws').write_bytes(SCRIPT.read_bytes())
    catalog_file = CATALOG
    if probe:
        (out/MENUS/(MOD + '.xml')).write_text(menu_xml(True), encoding='utf-8', newline='\n')
        catalog_file = out/'probe-strings.json'
        catalog_file.write_text(catalog_json(True), encoding='utf-8', newline='\n')
    else:
        (out/MENUS/(MOD + '.xml')).write_bytes(MENU.read_bytes())
    subprocess.run([sys.executable, str(tool_path(w3strings)), 'build', str(catalog_file), '--out', str(mod/'content')],
                   check=True)
    if probe:
        catalog_file.unlink()
    for lang in LANGUAGES:
        if not (mod/'content'/(lang + '.w3strings')).is_file():
            raise SystemExit('missing table %s.w3strings' % lang)
    files = {}
    for path in sorted(p for p in out.rglob('*') if p.is_file()):
        files[path.relative_to(out).as_posix()] = sha(path.read_bytes())
    (out/'build.json').write_text(json.dumps({'mod': MOD, 'version': VERSION, 'minCmfApi': MIN_API, 'probe': probe, 'files': files},
                                             indent=2) + '\n',
                                  encoding='utf-8')
    return files


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('write')
    sub.add_parser('check')
    built = sub.add_parser('build')
    built.add_argument('--out', required=True)
    built.add_argument('--w3strings')
    built.add_argument('--probe', action='store_true')
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
    for path, digest in build(args.out, args.w3strings, args.probe).items():
        print(digest, path)
    return 0


if __name__ == '__main__':
    sys.exit(main())
