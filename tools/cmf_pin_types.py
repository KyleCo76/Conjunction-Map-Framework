"""Pin type names a CMF icon pack can target, generated from the pinned 5.01 world map.

Reads two things from Kyle's local reference material (nothing vanilla is stored):
  * the frame labels of the stock pin glyph sprite (588, PinIcon_122) in the map movie,
    taken from either the vanilla panel_worldmap.redswf or a CMF pin-field build
    (CMF edits only ActionScript, so the sprite tag is byte-identical; its SHA-256 is pinned);
  * the legend tab and order of each type from an FFDec export of HubMapPinPanel.as
    (the _pinTypeDefinitions table; its parsed content is pinned).
CMF-owned notes on how the CMF 1 core reaches each type come from the October 19
pin-sources research (kept in the private development repository),
which read vanilla mapMenu.ws and commonMapManager.ws.

  generate  write tools/cmf_pin_types.json and docs/authors/pin-types.md
  render    rewrite docs/authors/pin-types.md from the committed JSON
Developer only; never launches or deploys anything.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT/'tools/cmf_pin_types.json'
MD_PATH = ROOT/'docs/authors/pin-types.md'
PIN_SPRITE = 588
PIN_SPRITE_SHA = 'd9b5f0daff36ed8e30318f868eeb5b8d69767aa72651964bdc035f437cee81d4'
LEGEND_SHA = '25d8e7c015ca126f00295a39b928348455be805c2bb3be8e7431be84143ac005'
CATEGORIES = ['General', 'Quests', 'Exploration', 'NPCs', 'Buffs']

# Quest pins collapse into one shared legend row (HubMapPinPanel.addPinInstance, isQuest).
QUEST = {'StoryQuest', 'ChapterQuest', 'SideQuest', 'MonsterQuest', 'TreasureQuest', 'QuestReturn',
         'HorseRace', 'BoatRace', 'QuestBelgard', 'QuestCoronata', 'QuestVermentino',
         'QuestObjective', 'QuestObjectiveOther'}
# Filtered out by vanilla mapMenu.ws before any map pin exists.
NOT_DRAWN = {'NPC', 'Enemy', 'EnemyDead', 'GenericFocus', 'Rift', 'PointOfInterestMappin', 'Teleport',
             'HorseRaceTarget', 'HorseRaceDummy'}
# Built outside CR4MapMenu.AddPinTypeData, so the CMF 1 core never sees them.
NOT_REACHED = {'Player': 'player arrow; built by UpdatePlayerPin, which API version 1 does not reach'}
USER_PIN = re.compile(r'User\d+$')
# Visible types vanilla 5.01 sends to the world map that have no legend definition.
ALL_TAB_ONLY = {'Bed', 'Stables', 'MagicLamp', 'Herb'}
NOTES = {
    'Herb': 'no legend row; every herb pin is this type and its tag is the herb kind, so a tag claim changes every pin of that herb',
    'NotDiscoveredPOI': 'the "?" pin of every undiscovered place; a claim changes all of them at once',
    'QuestObjective': 'the tracked quest\'s other objectives; they stay gold whatever tint is registered',
    'QuestObjectiveOther': 'untracked quest objectives; the usual target for quest tints (Map Quest Insight tints this one)',
    'Harbor': 'shown only while sailing',
    'RoadSign': 'signpost (fast travel); hidden while sailing',
    'NoticeBoard': 'notice board with nothing new; the full board is NoticeBoardFull',
    'Horse': 'Roach',
    'PlayerStash': 'stash',
    'Entrance': 'cave or dungeon entrance',
    'Shopkeeper': 'general merchant',
    'Blacksmith': 'blacksmith (weapons)',
    'Armorer': 'armorer (armour)',
    'Alchemic': 'alchemist',
    'Herbalist': 'herbalist',
    'Innkeeper': 'innkeeper',
    'Enchanter': 'runewright (Blood and Wine)',
    'Prostitute': 'courtesan',
    'Hairdresser': 'barber',
    'WineMerchant': 'wine merchant',
    'DyeMerchant': 'dye merchant',
    'PlaceOfPower': 'Place of Power',
    'AlchemyTable': 'alchemy table',
    'ArmorRepairTable': 'armorer\'s table',
    'Bookshelf': 'bookshelf',
    'Bed': 'bed',
    'Stables': 'stables',
}


def need(ok, why):
    if not ok:
        raise ValueError(why)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def _tags(data, position, end):
    while position < end:
        start = position
        header = struct.unpack_from('<H', data, position)[0]
        position += 2
        code, size = header >> 6, header & 63
        if size == 63:
            size = struct.unpack_from('<I', data, position)[0]
            position += 4
        need(position + size <= end, 'tag outside movie')
        yield code, data[start:position + size], data[position:position + size]
        position += size
        if code == 0:
            return


def sprite_labels(movie_body, sprite_id=PIN_SPRITE):
    """Frame labels of one DefineSprite in an uncompressed SWF body (after the 8-byte header)."""
    rect = (5 + 4 * (movie_body[0] >> 3) + 7) // 8
    for code, whole, payload in _tags(movie_body, rect + 4, len(movie_body)):
        if code == 39 and struct.unpack_from('<H', payload)[0] == sprite_id:
            labels = [inner[:inner.index(0)].decode('ascii')
                      for inner_code, _, inner in _tags(payload, 4, len(payload)) if inner_code == 43]
            return sha(whole), labels
    raise ValueError('sprite %d not found' % sprite_id)


def movie_body(movie):
    import zlib
    need(movie[:3] in (b'CFX', b'GFX', b'CWS', b'FWS'), 'movie signature')
    return zlib.decompress(movie[8:]) if movie[:1] == b'C' else movie[8:]


def movie_from(redswf=None, bundle=None, metadata=None):
    import cmf_panel
    if redswf:
        return cmf_panel.read_cr2w(Path(redswf).read_bytes())['movieBytes']
    import lz4.block
    data, meta = Path(bundle).read_bytes(), Path(metadata).read_bytes()
    cmf_panel.read_package(data, meta)
    offset, size, packed = struct.unpack_from('<QII', data, 32 + 272)
    return cmf_panel.read_cr2w(lz4.block.decompress(data[offset:offset + packed], uncompressed_size=size))['movieBytes']


def legend_definitions(text):
    """(name, category, priority) from HubMapPinPanel._pinTypeDefinitions; a later duplicate key wins, as in AS3."""
    start = text.index('_pinTypeDefinitions:Object = {')
    block = text[start:text.index('};', start)]
    found = {}
    for name, category, priority in re.findall(r'"(\w+)":new PinTypeDefinition\("(\w+)",(\d+)\)', block):
        found.pop(name, None)
        found[name] = (category, int(priority))
    need(found, 'no pin type definitions found')
    return [(name, category, priority) for name, (category, priority) in found.items()]


def legend_digest(definitions):
    return sha(json.dumps(sorted(definitions)).encode('ascii'))


def classify(name, frames, legend):
    """CMF-owned description of how the CMF 1 world map core treats one type name."""
    base = re.sub(r'(_\d+|Disabled)$', '', name)
    entry = {'name': name, 'art': name in frames, 'category': None, 'priority': None, 'reach': 'yes', 'note': ''}
    if name in legend:
        entry['category'], entry['priority'] = legend[name]
    if re.search(r'_\d+$', name):
        entry['reach'] = 'base'
        entry['note'] = 'level variant of %s (vanilla adds the level to the drawn frame only); register %s, and its image covers every level' % (base, base)
    elif name in NOT_DRAWN:
        entry['reach'] = 'no'
        entry['note'] = 'never drawn on the world map (vanilla filters it out)'
    elif name in NOT_REACHED:
        entry['reach'] = 'no'
        entry['note'] = NOT_REACHED[name]
    elif USER_PIN.match(name):
        entry['reach'] = 'no'
        entry['note'] = 'player-placed pin; built by UpdateUserMapPin, which API version 1 does not reach'
    elif name.endswith('Disabled'):
        entry['note'] = 'completed %s; its own type, so a claim on %s leaves it stock' % (base, base)
    if name in QUEST:
        entry['note'] = '; '.join(filter(None, [NOTES.get(name, ''),
                                               'quest pin: every quest pin shares one legend row']))
    elif name in NOTES and entry['reach'] == 'yes':
        entry['note'] = NOTES[name]
    if entry['reach'] == 'yes' and entry['category'] is None and name not in ALL_TAB_ONLY and not name.endswith('Disabled'):
        entry['reach'] = 'unknown'
        entry['note'] = 'stock glyph only; not among the types vanilla 5.01 sends to the world map'
    return entry


def build(labels, definitions, sprite_sha, source):
    need(sprite_sha == PIN_SPRITE_SHA, 'pin glyph sprite %s is not the pinned 5.01 sprite' % sprite_sha)
    need(legend_digest(definitions) == LEGEND_SHA, 'legend definitions are not the pinned 5.01 table')
    legend = {name: (category, priority) for name, category, priority in definitions}
    names = list(dict.fromkeys(labels + [name for name, _, _ in definitions]))
    types = [classify(name, set(labels), legend) for name in names]
    types.sort(key=lambda t: (CATEGORIES.index(t['category']) if t['category'] in CATEGORIES else len(CATEGORIES),
                              t['priority'] if t['priority'] is not None else 0, t['name'].lower()))
    return {'schema': 'cmf-pin-types-1', 'game': 'The Witcher 3 5.01', 'source': source,
            'pinSpriteSha256': sprite_sha, 'legendSha256': legend_digest(definitions), 'types': types}


def known_types(path=JSON_PATH):
    """name -> entry from the committed list (used by tools/cmf_pack.py)."""
    return {t['name']: t for t in json.loads(Path(path).read_text(encoding='utf-8'))['types']}


SECTIONS = [
    ('General', 'Legend tab "General".'),
    ('Quests', 'Legend tab "Quests". Every quest pin is drawn in **one shared legend row**, so give every quest type you change the same legend image (see the icon pack guide, section 6).'),
    ('Exploration', 'Legend tab "Exploration". The `_1`/`_2`/`_3` level variants are drawn by the map but API version 1 keys on the base name: register the base name and your image covers every level.'),
    ('NPCs', 'Legend tab "NPCs".'),
    ('Buffs', 'Legend tab "Buffs".'),
    (None, 'Types with no legend tab of their own (they appear under "All" only, or have no legend row), and stock glyphs API version 1 cannot or need not reach.'),
]
REACH = {'yes': 'yes', 'base': 'use base', 'no': 'no', 'unknown': 'unverified'}


def render(data):
    lines = ['# Pin types for icon packs', '',
             '<!-- Generated by tools/cmf_pin_types.py from tools/cmf_pin_types.json. Do not edit by hand. -->', '',
             'These are the pin type names the 5.01 world map uses, as the second argument of `CMFRegisterIcon`, '
             '`CMFRegisterLegendIcon` and `CMFRegisterTint` (write them as names, in single quotes: `\'Innkeeper\'`). '
             'Names are case-sensitive.', '',
             'Columns: **Stock art** says the map has a stock glyph for that name (one frame of the pin sprite). '
             '**API version 1** says whether a claim on that name changes anything today: *yes*; *use base* (register the '
             'base name instead); *no* (API version 1 never sees that pin); *unverified* (the map has a glyph but vanilla '
             '5.01 was not seen sending that type; it may come from quests or other mods).', '',
             'Source: the pin sprite and legend table of the pinned 5.01 map (pin sprite SHA-256 `%s`, legend '
             'table digest `%s`), plus CMF notes from reading vanilla `mapMenu.ws`. Names only; no game code is '
             'stored. %d names.' % (data['pinSpriteSha256'][:16], data['legendSha256'][:16], len(data['types'])), '']
    for category, intro in SECTIONS:
        rows = [t for t in data['types'] if (t['category'] == category if category else t['category'] not in CATEGORIES)]
        lines += ['## ' + (category or 'Other names'), '', intro, '', '| Type | Stock art | API version 1 | Notes |', '| --- | --- | --- | --- |']
        for t in rows:
            lines.append('| `%s` | %s | %s | %s |' % (t['name'], 'yes' if t['art'] else 'no', REACH[t['reach']], t['note']))
        lines.append('')
    return '\n'.join(lines)


def write(data, json_path=JSON_PATH, md_path=MD_PATH):
    Path(json_path).write_text(json.dumps(data, indent=1) + '\n', encoding='utf-8', newline='\n')
    Path(md_path).parent.mkdir(parents=True, exist_ok=True)
    Path(md_path).write_text(render(data), encoding='utf-8', newline='\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest='command', required=True)
    gen = sub.add_parser('generate')
    gen.add_argument('--redswf', help='vanilla panel_worldmap.redswf')
    gen.add_argument('--bundle', help='blob0.bundle of a CMF pin-field build (with --metadata)')
    gen.add_argument('--metadata')
    gen.add_argument('--legend-as', required=True, help='FFDec export of red/game/witcher3/menus/worldmap/HubMapPinPanel.as')
    sub.add_parser('render')
    args = parser.parse_args()
    if args.command == 'render':
        write(json.loads(JSON_PATH.read_text(encoding='utf-8')))
        return
    need(bool(args.redswf) != bool(args.bundle) and bool(args.bundle) == bool(args.metadata),
         'give --redswf, or --bundle with --metadata')
    sprite_sha, labels = sprite_labels(movie_body(movie_from(args.redswf, args.bundle, args.metadata)))
    definitions = legend_definitions(Path(args.legend_as).read_text(encoding='utf-8').replace('\r\n', '\n'))
    data = build(labels, definitions, sprite_sha, 'redswf' if args.redswf else 'cmf-build')
    write(data)
    print('%d types written to %s and %s' % (len(data['types']), JSON_PATH, MD_PATH))


if __name__ == '__main__':
    main()
