"""Build the CMF minimap add-on and stage modCMFMinimapPanel (developer only).

The add-on replaces no game file. Steps: read the game's unused hud_watermark.redswf
(CR2W, one CSwfResource; taken from content0/bundles/startup.bundle when given that),
export its movie with FFDec, compile source/minimap/overlay/HudModuleWatermark.as over its
one class with -importScript, restore the opaque movie tail, swap the movie into the
resource, and package it under the HUD's unused hud_pickeditemsinfo depot path. The
watermark movie is the only HUD movie that imports assets from an empty address (every
other one imports gfxfontlib.swf or nothing), which may stop the HUD from loading it, so
the import and the one text field that uses it are dropped. Then gate:
  * a full re-export may differ from the base movie only in that class;
  * every other non-ABC tag, the opaque tail and the CR2W head stay byte identical;
  * the pin types listed in cmfMinimap.ws are exactly the game minimap's class<Type> symbols;
  * tools/cmf_panel.py read_package must pass and the bundle must extract to the resource.
Writes <out>/Mods/modCMFMinimapPanel plus build.json with every hash.
Never deploys or launches anything.

make_bundle/make_metadata are copies of tools/cmf_package.py with the depot as a
parameter; switch to cmf_package once it takes one.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import zlib

import lz4.block

import cmf_package
import cmf_panel
from cmf_pin_panel import changed_classes, ffdec

ROOT = Path(__file__).resolve().parents[1]
PINS = ROOT/'source/minimap/overlay/overlay.json'
CLASS_SOURCE = ROOT/'source/minimap/overlay/HudModuleWatermark.as'
SCRIPT = ROOT/'source/minimap/content/scripts/local/cmfMinimap.ws'
MOD = 'modCMFMinimapPanel'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def need(ok, why):
    if not ok:
        raise ValueError(why)


def read_resource(data):
    """Validate a HUD movie CR2W (one CSwfResource, optionally one CSwfTexture) and return its parts."""
    need(len(data) >= 160 and data[:4] == b'CR2W', 'CR2W signature')
    version, flags, stamp, build, size, buffersize, crc, _ = struct.unpack_from('<IIQIIIII', data, 4)
    need(version == 164 and flags == stamp == build == 0 and size == buffersize == len(data), 'CR2W header')
    need(zlib.crc32(data[:32] + struct.pack('<I', 0xdeadbeef) + data[36:160]) == crc, 'header CRC')
    tables = []
    for i, stride in enumerate((1, 8, 8, 16, 24, 24, 24, 0, 0, 0)):
        offset, count, stored = struct.unpack_from('<III', data, 40 + 12 * i)
        need(i not in (2, 5, 6, 7, 8, 9) or offset == count == 0, 'unsupported CR2W table %d' % i)
        raw = data[offset:offset + count * stride] if count else b''
        need(zlib.crc32(raw) == stored, 'table %d CRC' % i)
        tables.append(raw)
    strings = tables[0]
    names = [strings[o:strings.index(0, o)].decode('ascii') for o, _ in struct.iter_unpack('<II', tables[1])]
    exports = list(struct.iter_unpack('<HHIIIII', tables[4]))
    need([names[e[0]] for e in exports] in (['CSwfResource'], ['CSwfResource', 'CSwfTexture']), 'export topology')
    for name, _, _, length, offset, _, stored in exports:
        need(zlib.crc32(data[offset:offset + length]) == stored, names[name] + ' export CRC')
    _, _, _, length, offset, _, _ = exports[0]
    end = exports[1][4] + exports[1][3] if len(exports) > 1 else offset + length
    need((len(exports) == 1 or exports[1][4] == offset + length) and end == len(data), 'export order/EOF')
    raw = data[offset:offset + length]
    pos = 1
    while True:
        name_id = struct.unpack_from('<H', raw, pos)[0]
        pos += 2
        if name_id == 0:
            break
        width = struct.unpack_from('<HI', raw, pos)[1]
        pos += 6 + width - 4
    movie_length = struct.unpack_from('<I', raw, pos)[0]
    need(raw[pos + 4 + movie_length:] == b'\0' * 4, 'movie/Unk1 boundary')
    return {'names': names, 'properties': tables[3], 'head': raw[:pos],
            'texture': data[offset + length:], 'movie': raw[pos + 4:pos + 4 + movie_length]}


def resource_from_bundle(bundle, depot):
    """Extract one resource from a game v5 bundle such as content0/bundles/startup.bundle."""
    need(bundle[:8] == b'POTATO70', 'bundle signature')
    toc, version = struct.unpack_from('<IH', bundle, 16)
    need(version == 5, 'bundle version')
    for i in range(toc // 304):
        entry = bundle[32 + 304 * i:32 + 304 * (i + 1)]
        if entry[:256].split(b'\0')[0] != depot.encode('ascii'):
            continue
        offset, size, packed, crc, codec = struct.unpack_from('<QIIII', entry, 272)
        raw = bundle[offset:offset + packed]
        if codec == 0:
            data = raw[:size]
        elif codec == 1:
            data = zlib.decompress(raw)
        else:
            need(codec in (4, 5), 'unsupported codec %d' % codec)
            data = lz4.block.decompress(raw, uncompressed_size=size)
        need(len(data) == size and zlib.crc32(data) == crc, 'bundle entry size/CRC')
        return data
    raise ValueError('depot path not in bundle')


def compare_resources(before, after, movie):
    for key in ('names', 'properties', 'head', 'texture'):
        need(before[key] == after[key], 'resource %s changed' % key)
    need(after['movie'] == movie, 'movie bytes changed')


def restore_tail(original, candidate, tail_sha):
    """Re-attach the opaque bytes past the vanilla End tag, which FFDec drops (as cmf_panel does for the map)."""
    before, after = cmf_panel.read_movie(original), cmf_panel.read_movie(candidate)
    need(before['tailSha256'] == tail_sha, 'opaque tail pin')
    need(original[:4] == candidate[:4] and candidate[:1] == b'C', 'candidate signature/version')
    need(not after['tail'], 'candidate already has an opaque tail')
    cmf_panel.compare_movies(before, dict(after, tail=before['tail']), True)
    result = candidate[:8] + zlib.compress(zlib.decompress(candidate[8:]) + before['tail'])
    cmf_panel.compare_movies(before, cmf_panel.read_movie(result), True)
    return result


def make_bundle(resource, depot):
    """One-resource Remastered v5 bundle, LZ4HC payload at offset 4096 (cmf_package.make_bundle)."""
    packed = lz4.block.compress(resource, mode='high_compression', compression=9, store_size=False)
    need(lz4.block.decompress(packed, uncompressed_size=len(resource)) == resource, 'LZ4 round trip')
    head = b'POTATO70' + struct.pack('<QIH', 4096 + len(packed), 304, 5) + struct.pack('<Q', 336) + b'\0\0'
    entry = depot.encode('ascii').ljust(256, b'\0') + b'\0' * 16
    entry += struct.pack('<QIIII', 4096, len(resource), len(packed), zlib.crc32(resource), 5) + b'\0' * 8
    return head + entry + b'\0' * (4096 - 336) + packed


def make_metadata(bundle, depot):
    """v7 metadata.store for a make_bundle output (cmf_package.make_metadata)."""
    total = struct.unpack_from('<Q', bundle, 8)[0]
    offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 32 + 272)
    parts = depot.split('\\')
    strings = bytearray(b'\0')
    where = {}
    for text in [depot, 'blob0.bundle'] + parts:
        where[text] = len(strings)
        strings += text.encode('ascii') + b'\0'
    records = bytearray()

    def table(fmt, rows):
        records.extend(cmf_package._count(len(rows)))
        for row in rows:
            records.extend(struct.pack(fmt, *row))

    table('<8I', [(0,) * 8, (where[depot], 0, packed, size, 1, 0, 0, 5)])
    table('<Q4I', [(0,) * 5, (offset, packed, 0, 1, 1)])
    table('<Q4I', [(0,) * 5, (total - 336, 336, where['blob0.bundle'], 1, 1)])
    table('<I', [])
    table('<ii', [(0, 0)] + [(where[name], i) for i, name in enumerate(parts[:-1])])
    table('<iii', [(1, len(parts) - 1, where[parts[-1]])])
    table('<QII', [(cmf_package.fnv64(depot.encode('ascii')), 1, 0)])
    return (b'\x03VTM' + struct.pack('<III', 7, packed, size) + cmf_package._count(len(strings))
            + bytes(strings) + bytes(records))


def script_pin_types(text):
    """Pin type names pushed by cmfMinimap.ws (the PushBack list in CMFMinimapPinTypes)."""
    return re.findall(r"types\.PushBack\('([A-Za-z0-9_]+)'\);", text)


def movie_pin_types(scripts):
    """Base type names of the movie's class<Type> symbols, the alternate-level postfix _<digit> removed."""
    names = {p.stem[5:] for p in scripts.glob('class*.as')}
    return sorted({re.sub(r'_[0-9]+$', '', n) for n in names}), len(names)


# The base movie's empty-address import, its text field and the placement of that field.
UNUSED_TEXT_TAGS = (71, 37, 70)


def is_unused_text_tag(tag):
    code, payload = tag['code'], tag['payload']
    if code == 71:
        return payload == b'\0\x01\0\0\0'
    if code == 37:
        return payload[:2] == b'\x01\0'
    if code == 70:
        return payload[:1] == b'\x06' and payload[2:5] == b'\x01\0\x01'
    return False


def drop_unused_text(data):
    """Drop the empty-address ImportAssets2, the DefineEditText it serves and its PlaceObject3."""
    movie = cmf_panel.read_movie(data)
    need(data[:1] == b'C', 'compressed movie expected')
    dropped = [t for t in movie['tags'] if is_unused_text_tag(t)]
    need([t['code'] for t in dropped] == list(UNUSED_TEXT_TAGS), 'unused text tags not found exactly once')
    body = zlib.decompress(data[8:])
    kept, position = [], len(movie['framing'])
    for tag in movie['tags']:
        start = position
        position += 2 + (4 if struct.unpack_from('<H', body, position)[0] & 63 == 63 else 0) + tag['size']
        raw = body[start:position]
        need(sha(raw) == tag['sha256'], 'tag walk')
        if not is_unused_text_tag(tag):
            kept.append(raw)
    new_body = movie['framing'] + b''.join(kept)
    result = data[:4] + struct.pack('<I', len(new_body) + 8) + zlib.compress(new_body + movie['tail'])
    after = cmf_panel.read_movie(result)
    need([t for t in after['tags']] == [t for t in movie['tags'] if not is_unused_text_tag(t)], 'kept tags changed')
    need(after['tail'] == movie['tail'], 'opaque movie tail changed')
    return result


def base_resource(path, depot):
    data = Path(path).read_bytes()
    if data[:8] == b'POTATO70':
        data = resource_from_bundle(data, depot)
    return data


def build(vanilla, java, jar, out, minimap_path=None):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    pins = json.loads(PINS.read_text(encoding='utf-8'))
    depot = pins['depot']
    script = SCRIPT.read_bytes()
    need(b'\r' not in script and all(b < 128 for b in script), 'cmfMinimap.ws must be ASCII/LF')
    source = CLASS_SOURCE.read_bytes()
    need(b'\r' not in source and all(b < 128 for b in source), 'HudModuleWatermark.as must be ASCII/LF')
    original = base_resource(vanilla, pins['baseDepot'])
    need(sha(original) == pins['baseRedswfSha256'], 'base resource hash mismatch')
    before = read_resource(original)
    movie = before['movie']
    need(sha(movie) == pins['baseMovieSha256'], 'base movie hash mismatch')
    minimap = base_resource(minimap_path or vanilla, pins['minimapDepot'])
    need(sha(minimap) == pins['minimapRedswfSha256'], 'game minimap resource hash mismatch')
    minimap_movie = read_resource(minimap)['movie']
    need(sha(minimap_movie) == pins['minimapMovieSha256'], 'game minimap movie hash mismatch')
    work = out/'work'
    work.mkdir(parents=True)
    (work/'base.gfx').write_bytes(movie)
    (work/'minimap.gfx').write_bytes(minimap_movie)
    ffdec(java, jar, '-export', 'script', work/'export-minimap', work/'minimap.gfx')
    types, symbols = movie_pin_types(work/'export-minimap'/'scripts')
    listed = script_pin_types(script.decode('ascii'))
    need(listed == types, 'cmfMinimap.ws pin types differ from the game minimap: %s'
         % sorted(set(listed) ^ set(types)))
    ffdec(java, jar, '-export', 'script', work/'export-base', work/'base.gfx')
    base_scripts = work/'export-base'/'scripts'
    need((base_scripts/pins['class']).is_file(), 'base movie lacks ' + pins['class'])
    target = work/'src'/pins['class']
    target.parent.mkdir(parents=True)
    target.write_bytes(source)
    ffdec(java, jar, '-onerror', 'abort', '-importScript', work/'base.gfx', work/'compiled.gfx', work/'src')
    candidate = restore_tail(movie, (work/'compiled.gfx').read_bytes(), pins['baseMovieTailSha256'])
    candidate = drop_unused_text(candidate)
    cmf_panel.compare_movies(cmf_panel.read_movie(drop_unused_text(movie)), cmf_panel.read_movie(candidate), True)
    (work/'addon.gfx').write_bytes(candidate)
    ffdec(java, jar, '-export', 'script', work/'export-addon', work/'addon.gfx')
    changed = changed_classes(base_scripts, work/'export-addon'/'scripts')
    need(changed == [pins['class']], 'unexpected changed classes: %s' % changed)
    exported = (work/'export-addon'/'scripts'/pins['class']).read_text(encoding='utf-8')
    for name in re.findall(r'GetMemberFlashFunction\("([A-Za-z]+)"\)', script.decode('ascii')):
        need(('public function %s(' % name) in exported, 'add-on movie lacks ' + name)
    need('return "PickedItemsInfoModule";' in exported, 'add-on movie module name')
    resource = cmf_package.swap_movie(original, candidate)
    compare_resources(before, read_resource(resource), candidate)
    bundle = make_bundle(resource, depot)
    metadata = make_metadata(bundle, depot)
    layout = cmf_panel.read_package(bundle, metadata, depot)
    offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 32 + 272)
    need(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size) == resource,
         'bundle does not extract to the resource')
    files = {MOD + '/content/blob0.bundle': bundle, MOD + '/content/metadata.store': metadata,
             MOD + '/content/scripts/local/cmfMinimap.ws': script}
    for name, data in files.items():
        target = out/'Mods'/name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    report = {'schema': 'cmf-minimap-addon-build-1', 'pins': sha(PINS.read_bytes()), 'depot': depot,
              'classSource': sha(source), 'baseRedswf': sha(original), 'baseMovie': sha(movie),
              'movie': sha(candidate), 'resource': sha(resource), 'changedClasses': changed,
              'minimapClassSymbols': symbols, 'pinTypes': len(types), 'layout': layout['layout'],
              'files': {'Mods/' + name: sha(data) for name, data in sorted(files.items())}}
    (out/'build.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--vanilla', required=True, help='the game startup.bundle, or the extracted hud_watermark.redswf')
    parser.add_argument('--minimap', help='the extracted hud_minimap2.redswf when --vanilla is not startup.bundle')
    parser.add_argument('--java', required=True)
    parser.add_argument('--ffdec', required=True, help='FFDec 26.3.0 ffdec.jar (with flashlib beside it)')
    parser.add_argument('--out', required=True, help='new output directory')
    args = parser.parse_args()
    print(json.dumps(build(args.vanilla, args.java, args.ffdec, args.out, args.minimap), indent=1))


if __name__ == '__main__':
    main()
