"""Extract kandy422's Map Icons 1.0 artwork for its CMF pack (permission 2026-10-30).

Usage: python cmf_map_icons_remastered_art.py ARCHIVE --java JAVA --ffdec JAR --out NEW_DIR
Requires Pillow/lz4 and FFDec 26.3.0. Reads only the pinned archive; never deploys or
executes mod code. All 143 visible world states are extracted; 138 are eligible claims.
Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile
import zlib

from PIL import Image

import cmf_pin_types
from cmf_minimap_panel import resource_from_bundle

ARCHIVE_SHA = '15c9699330777a2291a758a49db58996aeaa59f3c1473358888f6264bd1f3b0e'
RESOURCE_SHA = 'd994af5bd2d58017fe6c1b0e1fd40ffc381e5139788113cadda4071ed2e680c1'
MOVIE_SHA = '4e49fe606567f6d8e193b0f26ae68cdfd5015ce6183f063a097c44f3f01beb1e'
DEPOT = r'gameplay\gui_new\swf\worldmap\panel_worldmap.redswf'
EXCLUDED = {'QuestReturn', 'Enemy', 'EnemyDead', 'Teleport', 'GenericFocus', 'Rift'}
REGIONS = {'Toussaint': 'bob', 'PrologVillage': 'prolog_village', 'Skellige': 'skellige',
           'KaerMorhen': 'kaer_morhen', 'Novigrad': 'novigrad', 'NoMansLand': 'no_mans_land',
           'Wyzima': 'wyzima_castle'}


def need(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def safe_member(name):
    path = PurePosixPath(name.replace('\\', '/'))
    need(not path.is_absolute() and '..' not in path.parts and ':' not in name and '\0' not in name,
         'unsafe archive/resource path: ' + name)
    return path


def bundle_from_zip(data):
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        members = archive.infolist()
        for item in members:
            safe_member(item.filename)
        bundles = [i for i in members if i.filename.replace('\\', '/').endswith('/blob0.bundle')]
        need(len(bundles) == 1, 'expected exactly one blob0.bundle')
        return archive.read(bundles[0])


def world_resource(bundle):
    need(len(bundle) >= 32 and bundle[:8] == b'POTATO70', 'bundle signature')
    toc, version = struct.unpack_from('<IH', bundle, 16)
    need(version == 5 and toc % 304 == 0 and 32 + toc <= len(bundle), 'bundle table bounds/version')
    names = [bundle[p:p + 256].split(b'\0')[0].decode('ascii') for p in range(32, 32 + toc, 304)]
    need(names.count(DEPOT) == 1, 'expected one world-map resource')
    return resource_from_bundle(bundle, DEPOT)


def resource_parts(data):
    """Read multi-texture v164 CSwfResource; check all header/table/export CRCs."""
    need(len(data) >= 160 and data[:4] == b'CR2W', 'CR2W header')
    version, flags, stamp, build, size, buffersize, crc, chunks = struct.unpack_from('<IIQIIIII', data, 4)
    need(version == 164 and flags == stamp == build == 0 and size == buffersize == len(data), 'CR2W size/version')
    need(zlib.crc32(data[:32] + struct.pack('<I', 0xdeadbeef) + data[36:160]) == crc, 'CR2W header CRC')
    tables, ranges = [], [(0, 160)]
    for index, stride in enumerate((1, 8, 8, 16, 24, 24, 24, 0, 0, 0)):
        offset, count, stored = struct.unpack_from('<III', data, 40 + 12 * index)
        need(not count or (stride and offset >= 160 and offset + count * stride <= len(data)), 'CR2W table bounds')
        raw = data[offset:offset + count * stride] if count else b''
        need(zlib.crc32(raw) == stored, 'CR2W table CRC')
        tables.append(raw)
        if count:
            ranges.append((offset, offset + len(raw)))
    strings = tables[0]
    names = []
    for offset, _ in struct.iter_unpack('<II', tables[1]):
        need(offset < len(strings) and b'\0' in strings[offset:], 'CR2W name bounds')
        names.append(strings[offset:strings.index(0, offset)].decode('ascii'))
    exports = []
    for index, (name, flag, parent, length, offset, template, stored) in enumerate(struct.iter_unpack('<HHIIIII', tables[4])):
        need(name < len(names) and names[name] == ('CSwfResource' if index == 0 else 'CSwfTexture'), 'CR2W export class')
        need(flag == 8192 and parent == (0 if index == 0 else 1) and template == 0, 'CR2W export topology')
        need(offset >= 160 and offset + length <= len(data), 'CR2W export bounds')
        raw = data[offset:offset + length]
        need(zlib.crc32(raw) == stored and raw[:1] == b'\0', 'CR2W export CRC/prefix')
        ranges.append((offset, offset + length))
        pos, properties = 1, {}
        while True:
            need(pos + 2 <= len(raw), 'CR2W property bounds')
            name_id = struct.unpack_from('<H', raw, pos)[0]
            pos += 2
            if name_id == 0:
                break
            need(pos + 6 <= len(raw), 'CR2W property header')
            type_id, width = struct.unpack_from('<HI', raw, pos)
            pos += 6
            need(name_id < len(names) and type_id < len(names) and width >= 4 and pos + width - 4 <= len(raw), 'CR2W property bounds')
            properties[names[name_id]] = raw[pos:pos + width - 4]
            pos += width - 4
        exports.append({'properties': properties, 'buffer': raw[pos:]})
    ranges.sort()
    need(bool(exports) and ranges[-1][1] == len(data) and
         all(a[1] == b[0] for a, b in zip(ranges, ranges[1:])), 'CR2W gaps/overlap/export count')
    buf = exports[0]['buffer']
    need(len(buf) >= 8, 'movie boundary')
    length = struct.unpack_from('<I', buf)[0]
    need(length + 8 == len(buf) and buf[-4:] == b'\0' * 4, 'movie boundary')
    return {'movie': buf[4:4 + length], 'textures': exports[1:],
            'header_chunks': chunks, 'export_count': len(exports)}


def select_types(labels, known):
    need(len(labels) == len(set(labels)), 'duplicate pin labels')
    need(all(label in known for label in labels), 'unrecognized source label')
    return {label: 11 if label == 'Player' or re.fullmatch(r'User[1-7]', label) or
            re.search(r'_[123]$', label) else 1 for label in labels if label not in EXCLUDED}


def file_for(label):
    return re.sub(r'([a-z])([A-Z])', r'\1_\2', label).lower() + '.png'


def fit_icon(image):
    """Fit every nontransparent source pixel, including the faintest baked glow."""
    image = image.convert('RGBA')
    bounds = image.getchannel('A').getbbox()
    need(bounds is not None, 'source bitmap is fully transparent')
    image = image.crop(bounds)
    width, height = image.size
    need(width > 0 and height > 0, 'empty source dimensions')
    factor = 88 / max(width, height)
    fitted = (max(1, round(width * factor)), max(1, round(height * factor)))
    # Float premultiplication avoids the low-alpha colour quantization of 8-bit RGBa.
    pixels = list(image.get_flattened_data())
    channels = []
    for channel in range(4):
        plane = Image.new('F', image.size)
        plane.putdata([p[3] if channel == 3 else p[channel] * p[3] / 255 for p in pixels])
        plane = plane.resize(tuple(n * 4 for n in fitted), Image.Resampling.LANCZOS)
        channels.append(list(plane.resize(fitted, Image.Resampling.LANCZOS).get_flattened_data()))
    rgba = bytearray()
    for red, green, blue, alpha in zip(*channels):
        a = min(255, max(0, round(alpha)))
        rgba.extend([min(255, max(0, round(c * 255 / alpha))) if a and alpha > 0 else 0
                     for c in (red, green, blue)] + [a])
    glyph = Image.frombytes('RGBA', fitted, bytes(rgba))
    output = Image.new('RGBA', (96, 96))
    output.paste(glyph, ((96 - fitted[0]) // 2, (96 - fitted[1]) // 2))
    return output


def definitions(root):
    found = {}
    for tag in root.find('tags'):
        cid = next((tag.get(k) for k in ('spriteId', 'shapeId', 'characterID') if tag.get(k) not in (None, '-1')), None)
        if cid is not None:
            need(cid not in found, 'duplicate character definition')
            found[cid] = tag
    return found


def labelled_frames(sprite):
    shown, labels, frame = {}, [], 1
    for tag in sprite.find('subTags'):
        kind = tag.get('type')
        if kind == 'FrameLabelTag':
            labels.append(tag.get('name'))
        elif kind.startswith('PlaceObject'):
            # Pinned icon/crest frames replace their single shape, with no inherited transforms.
            depth = int(tag.get('depth'))
            if tag.get('placeFlagHasCharacter') == 'true':
                shown[depth] = tag
        elif kind.startswith('RemoveObject'):
            shown.pop(int(tag.get('depth')), None)
        elif kind == 'ShowFrameTag':
            for label in labels:
                yield frame, label, dict(shown)
            labels, frame = [], frame + 1


def pin_bindings(root):
    defs = definitions(root)
    need('588' in defs, 'pin sprite missing')
    result = []
    for frame, label, shown in labelled_frames(defs['588']):
        if label.startswith('Original_'):
            continue
        if label == 'QuestReturn':
            need(not shown, 'QuestReturn expected empty')
            result.append({'label': label, 'frame': frame, 'bitmap': '', 'shape': ''})
            continue
        need(len(shown) == 1, 'pin drawing must have exactly one shape')
        place = next(iter(shown.values()))
        need(place.get('placeFlagHasColorTransform') != 'true' and place.get('placeFlagHasFilterList') != 'true', 'unexpected pin effects')
        matrix = place.find('matrix')
        need(matrix is not None and matrix.get('hasScale') == matrix.get('hasRotate') == 'false' and
             int(matrix.get('translateX')) == int(matrix.get('translateY')) == 0, 'unexpected pin placement')
        shape_id = place.get('characterId')
        shape = defs.get(shape_id)
        need(shape is not None and shape.get('type') == 'DefineShape3Tag', 'pin is not bitmap wrapper shape')
        fills = [t for t in shape.iter() if t.get('type') == 'FILLSTYLE']
        need(len(fills) == 1 and fills[0].get('fillStyleType') == '65', 'pin fill topology')
        bitmap_id = fills[0].get('bitmapId')
        bitmap = defs.get(bitmap_id)
        need(bitmap is not None and bitmap.get('type') == 'DefineBitsLossless2Tag' and bitmap.get('bitmapFormat') == '5', 'pin bitmap topology')
        bm = fills[0].find('bitmapMatrix')
        need(bm is not None and bm.get('hasRotate') == 'false' and bm.get('scaleX') == bm.get('scaleY') == '5.0', 'pin bitmap transform')
        result.append({'label': label, 'frame': frame, 'bitmap': bitmap_id, 'shape': shape_id})
    return result


def texture_images(parts):
    result = {}
    for entry in parts['textures']:
        props, buf = entry['properties'], entry['buffer']
        width, height = (struct.unpack('<I', props[k])[0] for k in ('width', 'height'))
        name = props['linkageName'][1:].decode('ascii')
        need(safe_member(name).name == name and name.endswith('.dds') and name not in result, 'texture linkage')
        need(len(buf) >= 28 and struct.unpack_from('<IIII', buf) == (0, 1, width, height), 'texture header')
        payload = buf[28:]
        kind = b'DXT5' if len(payload) == width * height else b'DXT1'
        need(len(payload) == width * height // (1 if kind == b'DXT5' else 2), 'texture payload size')
        header = struct.pack('<4sIIIIIII44sII4sIIIIIIIIII', b'DDS ', 124, 0x81007, height, width,
                             len(payload), 0, 1, bytes(44), 32, 4, kind, 0, 0, 0, 0, 0, 0x1000, 0, 0, 0, 0)
        result[name] = (Image.open(io.BytesIO(header + payload)).convert('RGBA'), sha(payload))
    return result


def bitmap_refs(shape):
    return [x.get("bitmapId") for x in shape.iter() if x.get("bitmapId") not in (None, "0", "65535")]


def crest_art(root, textures):
    defs = definitions(root)
    external = {t.get('imageID'): t.get('fileName') for t in root.find('tags') if t.get('type') == 'DefineExternalImage2'}
    symbols = {}
    for tag in root.find('tags'):
        if tag.get('type') == 'SymbolClassTag':
            symbols.update(zip([t.text for t in tag.find('tags')], [t.text for t in tag.find('names')]))
    output = {}
    for sid, symbol in symbols.items():
        match = re.search(r'\.mcAreaIcon_(\w+)_\d+$', symbol)
        if not match:
            continue
        name = match.group(1)
        first = next(labelled_frames(defs[sid]))
        need(first[1] == 'active', 'crest active frame')
        if name == 'Custom':
            need(not first[2], 'Custom expected empty')
            continue
        need(name in REGIONS and len(first[2]) == 1, 'crest topology/name')
        shape = defs[next(iter(first[2].values())).get('characterId')]
        refs = bitmap_refs(shape)
        need(len(refs) == 1 and defs[refs[0]].get('type') == 'DefineSubImage', 'crest subimage topology')
        sub = defs[refs[0]]
        filename = external[sub.get('imageId')]
        sheet, texture_sha = textures[filename]
        crop = tuple(int(sub.get(k)) for k in ('x1', 'y1', 'x2', 'y2'))
        need(0 <= crop[0] < crop[2] <= sheet.width and 0 <= crop[1] < crop[3] <= sheet.height, 'crest crop bounds')
        native = sheet.crop(crop)
        target = (136, 132) if name == 'KaerMorhen' else (136, 116)
        output[REGIONS[name]] = (native.resize(target, Image.Resampling.LANCZOS),
                                {'texture': filename, 'texture_sha256': texture_sha, 'crop': list(crop),
                                 'source_rgba_sha256': sha(native.tobytes()), 'sprite': sid})
    need(set(output) == set(REGIONS.values()), 'missing crest')
    return output


def run_ffdec(java, ffdec, work, arguments, label):
    command = [str(Path(java).resolve()), '-Duser.home=' + str((work / 'tool-home').resolve()),
               '-Djava.awt.headless=true', '-Xmx2g', '-jar', str(Path(ffdec).resolve())] + arguments
    with (work / (label + '.log')).open('w', encoding='utf-8') as log:
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=180)
    need(result.returncode == 0, 'FFDec failed: ' + label)


def extract_art(archive, out, java, ffdec):
    out = Path(out)
    need(not out.exists(), 'output already exists')
    data = Path(archive).read_bytes()
    need(sha(data) == ARCHIVE_SHA, 'archive SHA mismatch')
    resource = world_resource(bundle_from_zip(data))
    need(sha(resource) == RESOURCE_SHA, 'resource SHA mismatch')
    parts = resource_parts(resource)
    need(sha(parts['movie']) == MOVIE_SHA, 'movie SHA mismatch')
    out.mkdir(parents=True)
    work = out / 'work'
    work.mkdir()
    try:
        movie = work / 'panel_worldmap.gfx'
        movie.write_bytes(parts['movie'])
        xml = work / 'movie.xml'
        run_ffdec(java, ffdec, work, ['-swf2xml', str(movie.resolve()), str(xml.resolve())], 'xml')
        root = ET.parse(xml).getroot()
        bindings = pin_bindings(root)
        need(len(bindings) == 144 and sum(bool(r['bitmap']) for r in bindings) == 143, 'pin state count')
        selection = select_types([r['label'] for r in bindings], cmf_pin_types.known_types())
        need(len(selection) == 138, 'selection drift')
        ids = sorted({r['bitmap'] for r in bindings if r['bitmap']}, key=int)
        exports = work / 'bitmaps'
        run_ffdec(java, ffdec, work, ['-selectid', ','.join(ids), '-format', 'image:png', '-export', 'image',
                                    str(exports.resolve()), str(movie.resolve())], 'bitmaps')
        art = out / 'art'
        art.mkdir()
        rows = []
        for binding in bindings:
            label, bid = binding['label'], binding['bitmap']
            row = dict(label=label, type=label, file='', sha256='', frame=binding['frame'],
                       bitmap=bid, shape=binding['shape'], included=label in selection,
                       api_floor=selection.get(label, ''), source_png_sha256='', source_size='', source_alpha_bbox='')
            if bid:
                matches = [p for p in exports.rglob('*.png') if re.match(r'^' + re.escape(bid) + r'(?:\D|$)', p.name)]
                need(len(matches) == 1, 'missing/ambiguous bitmap export ' + bid)
                image = Image.open(matches[0]).convert('RGBA')
                need(image.getchannel('A').getbbox() is not None, 'unexpected empty bitmap ' + label)
                filename = file_for(label)
                need(not (art / filename).exists(), 'filename collision')
                fit_icon(image).save(art / filename, optimize=True)
                row.update(file='art/' + filename, sha256=sha((art / filename).read_bytes()),
                           source_png_sha256=sha(matches[0].read_bytes()),
                           source_size=list(image.size), source_alpha_bbox=list(image.getchannel('A').getbbox()))
            rows.append(row)
        world = art / 'world'
        world.mkdir()
        crests = {}
        for region, (image, provenance) in crest_art(root, texture_images(parts)).items():
            filename = 'crest_' + region + '.png'
            image.save(world / filename, optimize=True)
            crests[region] = dict(provenance, file='art/world/' + filename, sha256=sha((world / filename).read_bytes()))
        with (out / 'labels.csv').open('w', encoding='utf-8', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator='\n')
            writer.writeheader()
            writer.writerows(rows)
        manifest = {'schema': 'cmf-map-icons-remastered-art-1', 'archive_sha256': ARCHIVE_SHA,
                    'resource_sha256': RESOURCE_SHA, 'movie_sha256': MOVIE_SHA, 'source_states': 143,
                    'claims': 138, 'fit_policy': 'all-nonzero-alpha-bounds; uniform contain88; canvas96; margin4',
                    'labels': rows, 'crests': crests,
                    'resource_header_chunks': parts['header_chunks'], 'resource_export_count': parts['export_count']}
        (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
        return manifest
    except Exception as error:
        (out / 'FAILED.txt').write_text(type(error).__name__ + ': ' + str(error) + '\n', encoding='utf-8')
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--java', type=Path, required=True)
    parser.add_argument('--ffdec', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    manifest = extract_art(args.archive, args.out, args.java, args.ffdec)
    print('Extracted %d source states; %d icon claims; %d crests' %
          (manifest['source_states'], manifest['claims'], len(manifest['crests'])))


if __name__ == '__main__':
    main()
