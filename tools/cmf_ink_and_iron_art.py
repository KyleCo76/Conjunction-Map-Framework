"""Ink and Iron's map art for its CMF adapter, taken from Ink and Iron's own Nexus downloads (adapter 1.2.0, CMF 9).

  python tools/cmf_ink_and_iron_art.py world WORLD_MAP.zip --out FOLDER
  python tools/cmf_ink_and_iron_art.py buttons ALL_IN_ONE.zip --out FOLDER

WinterElfeas, Ink and Iron's author, let CMF carry this art (2026-10-23: "You can go ahead to carry it in the CMF
pack"); the record is the private development records The pictures are cut from the
files exactly as the author ships them: nothing is re-drawn.

Both downloads carry a copy of the map file gameplay\\gui_new\\swf\\worldmap\\panel_worldmap.redswf in their
content\\blob0.bundle (LZ4). Its CR2W exports hold five CSwfTexture sheets; three matter here, told apart by their
pixel data's size, which is the last bytes of each export:
  _i313  2100 x 1380 DXT1  the world overview's painting
  _i1    1024 x 1020 DXT5  the region crests (rows 328-886) and the lower controller button rows
  _i49    988 x  544 DXT5  the other controller buttons

world writes FOLDER/painting.png and FOLDER/crest_<region>.png from the World Map file (0.9.0 re-draws only the
painting and the seven crests; the All In One keeps the game's). The crest rectangles are the map file's
DefineSubImage cut-outs of _i1 used by each region's UniverseArea.mcIcon. A crest is resized to the next multiple
of 4 (BC3), which the map stretches back to the game's own size: 136 x 116 (135 x 116), Kaer Morhen 136 x 132
(135 x 130).

buttons writes FOLDER/art/buttons/<family>_<button>.png for every button of every controller family from the All
In One (its gold-outlined sheets) with tools/cmf_button_sheet.py, and FOLDER/register.ws with the adapter's
CMFRegisterButtonPicture lines under Ink and Iron's provider name.

Needs Pillow (DDS decoding) and lz4.
"""
import argparse
import io
from pathlib import Path
import struct
import sys
import zipfile

import lz4.block
from PIL import Image

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import cmf_button_sheet
import cmf_pack

MAP = 'gameplay\\gui_new\\swf\\worldmap\\panel_worldmap.redswf'
PROVIDER = 'modInkAndIronUI'
PACK = 'modCMFAdapterInkAndIron'
SHEETS = {'_i313': (2100, 1380, b'DXT1'), '_i1': (1024, 1020, b'DXT5'), '_i49': (988, 544, b'DXT5')}
# Region (the overview's own name) -> (x1, y1, x2, y2) in _i1, with the map file's DefineSubImage character id.
CRESTS = {
    'kaer_morhen': (743, 328, 878, 458),       # 759, the wolf medallion, 135 x 130
    'skellige': (0, 770, 135, 886),            # 769, the longship
    'novigrad': (137, 770, 272, 886),          # 749, the city arms
    'no_mans_land': (274, 770, 409, 886),      # 739, Velen's tree and lily
    'wyzima_castle': (411, 770, 546, 886),     # 729, the Nilfgaardian sun
    'bob': (666, 646, 801, 762),               # 782, Toussaint's knight
    'prolog_village': (803, 646, 938, 762),    # 777, White Orchard's tree
}


def map_file(download):
    """The map file's bytes from a Nexus download zip (Ink and Iron's POTATO70 bundle: 320-byte entries)."""
    with zipfile.ZipFile(download) as archive:
        names = [n for n in archive.namelist() if n.lower().endswith('content/blob0.bundle')]
        if len(names) != 1:
            raise ValueError('%s: expected one content/blob0.bundle, found %d' % (download, len(names)))
        bundle = archive.read(names[0])
    if bundle[:8] != b'POTATO70':
        raise ValueError('not a bundle')
    at = 32
    while at + 320 <= len(bundle):
        name = bundle[at:at + 256].split(b'\0')[0]
        if not name:
            break
        size, packed, offset = struct.unpack_from('<III', bundle, at + 276)
        if name.decode('ascii', 'replace').lower() == MAP:
            raw = bundle[offset:offset + packed]
            kind = bundle[at + 316]
            if kind == 0:
                return raw
            if kind == 5:
                return lz4.block.decompress(raw, uncompressed_size=size)
            raise ValueError('compression %d not handled' % kind)
        at += 320
    raise ValueError('%s: no %s in the bundle' % (download, MAP))


def sheets(resource):
    """{name: RGBA Image} for the three sheets, from the CR2W export table (header at 40, 12-byte table rows,
    exports in table 4 as 24-byte rows: class, flags, parent, size, offset, template, crc)."""
    if resource[:4] != b'CR2W':
        raise ValueError('the map file is not CR2W')
    exports_at, count, _ = struct.unpack_from('<III', resource, 40 + 12 * 4)
    found = {}
    for i in range(count):
        size, offset = struct.unpack_from('<II', resource, exports_at + 24 * i + 8)
        for name, (width, height, kind) in SHEETS.items():
            need = width * height // (2 if kind == b'DXT1' else 1)
            if need <= size < need + 256:
                found[name] = decode(resource[offset + size - need:offset + size], width, height, kind)
    missing = sorted(set(SHEETS) - set(found))
    if missing:
        raise ValueError('sheets not found: %s' % ', '.join(missing))
    return found


def decode(data, width, height, kind):
    header = struct.pack('<4sIIIIIII44sII4sIIIIIIIIII', b'DDS ', 124, 0x81007, height, width, len(data), 0, 1,
                         bytes(44), 32, 4, kind, 0, 0, 0, 0, 0, 0x1000, 0, 0, 0, 0)
    return Image.open(io.BytesIO(header + data)).convert('RGBA')


def save(image, path):
    path.write_bytes(cmf_pack.write_png(image.width, image.height, image.tobytes()))


def world(download, out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=False)
    found = sheets(map_file(download))
    save(found['_i313'], out/'painting.png')
    for region, box in CRESTS.items():
        crest = found['_i1'].crop(box)
        size = tuple(-(-side // 4) * 4 for side in crest.size)
        save(crest.resize(size, Image.LANCZOS) if size != crest.size else crest, out/('crest_%s.png' % region))
    return sorted(p.name for p in out.iterdir())


def buttons(download, out):
    out = Path(out)
    found = sheets(map_file(download))
    work = out.with_name(out.name + '-sheets')
    work.mkdir(parents=True, exist_ok=False)
    for name in ('_i1', '_i49'):
        save(found[name], work/('%s.png' % name))
    button_map = cmf_button_sheet.json.loads(cmf_button_sheet.MAP.read_text(encoding='utf-8'))
    lines = cmf_button_sheet.cut(button_map, {'_i1': work/'_i1.png', '_i49': work/'_i49.png'}, PACK, out)
    lines = [line.replace('("%s",' % PACK, '("%s",' % PROVIDER, 1) for line in lines]
    (out/'register.ws').write_text('\n'.join(lines) + '\n', encoding='ascii', newline='\n')
    for name in ('_i1', '_i49'):
        (work/('%s.png' % name)).unlink()
    work.rmdir()
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('command', choices=('world', 'buttons'))
    parser.add_argument('download', help='the Nexus zip: World Map 0.9.0 for world, All In One 0.9.0 for buttons')
    parser.add_argument('--out', required=True, help='new output folder')
    args = parser.parse_args()
    if args.command == 'world':
        print('\n'.join(world(args.download, args.out)))
    else:
        print('%d button pictures' % len(buttons(args.download, args.out)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
