"""Build CMF's own map-space test movie and the modCMFTestMapSpace test pack (developer only).

The movie is CMF's own: one AS3 class, source/panel/test-movie/CMFTestMapSpace.as, whose public function
cmfMapSpace(data, map) is what CMF's map calls for a "movie" drawing. Steps: write a minimal AS3 movie
whose stub root class is named CMFTestMapSpace, compile the real class into it with FFDec -importScript,
wrap it in a one-export CSwfResource (the original-resource topology the S03 asset probes loaded in game),
and package it at MOVIE_DEPOT, which the map loads as MOVIE_URL. Gates: the movie parses, its only class
is CMFTestMapSpace and a re-export shows cmfMapSpace, the resource reads back with tools/cmf_panel.py and
the bundle extracts to the exact resource. TEST ONLY: never part of a player package. Never deploys or
launches anything.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import zlib

import lz4.block

import cmf_package
import cmf_panel
from panel.cmf_abc import read_abc

ROOT = Path(__file__).resolve().parents[1]
CLASS = 'CMFTestMapSpace'
SOURCE = ROOT/'source/panel/test-movie'/(CLASS + '.as')
PACK = ROOT/'source/providers/modCMFTestMapSpace'
MOVIE_URL = 'swf/cmftestmapspace/cmftestmapspace.swf'
MOVIE_DEPOT = 'gameplay\\gui_new\\swf\\cmftestmapspace\\cmftestmapspace.redswf'
LINKAGE = 'cmftestmapspace.swf'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def need(ok, why):
    if not ok:
        raise ValueError(why)


def u30(value):
    out = bytearray()
    while True:
        byte = value & 127
        value >>= 7
        out.append(byte | (128 if value else 0))
        if not value:
            return bytes(out)


def tag(code, data=b''):
    size = len(data)
    if size < 63:
        return struct.pack('<H', code * 64 + size) + data
    return struct.pack('<HI', code * 64 + 63, size) + data


def stub_abc(name):
    """ABC 46.16 with one class `name` extending flash.display.MovieClip, an empty constructor and nothing
    else; FFDec replaces the whole script with the compiled class."""
    strings = [name, '', 'flash.display', 'MovieClip']
    out = bytearray(struct.pack('<HH', 16, 46))
    out += u30(0) + u30(0) + u30(0)  # int, uint and double pools: empty
    out += u30(len(strings) + 1)
    for text in strings:
        raw = text.encode('utf-8')
        out += u30(len(raw)) + raw
    out += u30(3) + bytes([0x16]) + u30(2) + bytes([0x16]) + u30(3)  # package "" and flash.display
    out += u30(0)  # namespace sets
    out += u30(3) + bytes([0x07]) + u30(1) + u30(1) + bytes([0x07]) + u30(2) + u30(4)  # QNames name, MovieClip
    out += u30(3)
    for _ in range(3):  # class init, constructor, script init: no parameters, any return, no name, no flags
        out += u30(0) + u30(0) + u30(0) + bytes([0])
    out += u30(0)  # metadata
    out += u30(1) + u30(1) + u30(2) + bytes([0x01]) + u30(0) + u30(1) + u30(0)  # instance: sealed, iinit 1
    out += u30(0) + u30(0)  # class: cinit 0, no static traits
    out += u30(1) + u30(2) + u30(1) + u30(1) + bytes([0x04]) + u30(1) + u30(0)  # script: class slot 1
    bodies = [
        (0, 1, 1, 0, 1, bytes([0xd0, 0x30, 0x47])),
        (1, 1, 1, 0, 1, bytes([0xd0, 0x30, 0xd0, 0x49, 0x00, 0x47])),
        (2, 3, 1, 0, 3, bytes([0xd0, 0x30, 0x65, 0x00, 0x60, 0x02, 0x30, 0x60, 0x02, 0x58, 0x00, 0x1d, 0x68,
                               0x01, 0x47])),
    ]
    out += u30(len(bodies))
    for method, stack, local, init, depth, code in bodies:
        out += u30(method) + u30(stack) + u30(local) + u30(init) + u30(depth) + u30(len(code)) + code
        out += u30(0) + u30(0)
    return bytes(out)


def stub_movie(name):
    """FWS 10, 64x64 px, 24 fps, one frame: FileAttributes (AS3), DoABC, SymbolClass (root = name)."""
    body = cmf_panel_rect(64, 64) + struct.pack('<HH', 24 * 256, 1)
    body += tag(69, struct.pack('<I', 8))
    body += tag(82, struct.pack('<I', 1) + b'\0' + stub_abc(name))
    body += tag(76, struct.pack('<HH', 1, 0) + name.encode('ascii') + b'\0')
    body += tag(1) + tag(0)
    return b'FWS\x0a' + struct.pack('<I', len(body) + 8) + body


def cmf_panel_rect(width, height):
    values = (0, width * 20, 0, height * 20)
    bits = max(v.bit_length() for v in values) + 1
    text = format(bits, '05b') + ''.join(format(v, '0%db' % bits) for v in values)
    text += '0' * (-len(text) % 8)
    return bytes(int(text[i:i + 8], 2) for i in range(0, len(text), 8))


def fnv1a32(raw):
    if not raw:
        return 0
    value = 0x811c9dc5
    for byte in raw + b'\0':
        value = ((value ^ byte) * 0x01000193) & 0xffffffff
    return value


def make_resource(movie, linkage):
    """A one-export CR2W v164 CSwfResource: linkageName, then the movie buffer and Unk1 = 0 (the layout the
    S03 original resources had: no imports, no property rows, no textures, no fonts)."""
    linkage_raw = linkage.encode('ascii')
    need(0 < len(linkage_raw) < 64, 'linkage name length')
    names = ['', 'CSwfResource', 'linkageName', 'String']
    strings = bytearray()
    offsets = []
    for text in names:
        offsets.append(len(strings))
        strings += text.encode('ascii') + b'\0'
    name_table = b''.join(struct.pack('<II', o, fnv1a32(n.encode('ascii'))) for o, n in zip(offsets, names))
    value = bytes([0x80 | len(linkage_raw)]) + linkage_raw
    export = b'\0' + struct.pack('<HHI', 2, 3, 4 + len(value)) + value + struct.pack('<H', 0)
    export += struct.pack('<I', len(movie)) + movie + struct.pack('<I', 0)
    strings_at = 160
    names_at = strings_at + len(strings)
    exports_at = names_at + len(name_table)
    data_at = exports_at + 24
    export_table = struct.pack('<HHIIIII', 1, 8192, 0, len(export), data_at, 0, zlib.crc32(export))
    tables = [(strings_at, len(strings), zlib.crc32(bytes(strings))),
              (names_at, len(names), zlib.crc32(name_table)), (0, 0, 0), (0, 0, 0),
              (exports_at, 1, zlib.crc32(export_table))] + [(0, 0, 0)] * 5
    total = data_at + len(export)
    head = bytearray(b'CR2W' + struct.pack('<IIQIIIII', 164, 0, 0, 0, total, total, 0, 1))
    for row in tables:
        head += struct.pack('<III', *row)
    need(len(head) == 160, 'CR2W header size')
    struct.pack_into('<I', head, 32, zlib.crc32(bytes(head[:32]) + struct.pack('<I', 0xdeadbeef) + bytes(head[36:160])))
    return bytes(head) + bytes(strings) + name_table + export_table + export


def ffdec(java, jar, *args):
    result = subprocess.run([java, '-Djava.awt.headless=true', '-jar', str(jar)] + [str(a) for a in args],
                            stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=600)
    need(result.returncode == 0, 'FFDec failed: ' + (result.stderr or result.stdout)[-2000:])
    return result.stdout


def movie_classes(movie):
    names = []
    for item in cmf_panel.read_movie(movie)['tags']:
        if item['code'] == 82:
            for entry in read_abc(item['payload'])['classes']:
                names.append(entry['name']['name'])
    return names


def build(java, jar, out):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    work = out/'work'
    (work/'src').mkdir(parents=True)
    stub = stub_movie(CLASS)
    need(movie_classes(stub) == [CLASS], 'stub class read-back')
    (work/'stub.swf').write_bytes(stub)
    shutil.copyfile(SOURCE, work/'src'/(CLASS + '.as'))
    ffdec(java, jar, '-onerror', 'abort', '-importScript', work/'stub.swf', work/'movie.swf', work/'src')
    movie = (work/'movie.swf').read_bytes()
    need(movie_classes(movie) == [CLASS], 'compiled movie must hold exactly the class %s' % CLASS)
    ffdec(java, jar, '-export', 'script', work/'export', work/'movie.swf')
    exported = (work/'export'/'scripts'/(CLASS + '.as')).read_text(encoding='utf-8')
    need('function cmfMapSpace(' in exported, 'compiled class lost cmfMapSpace')
    resource = make_resource(movie, LINKAGE)
    readback = cmf_panel.read_cr2w(resource, 'mod-movie')
    need(readback['movieBytes'] == movie, 'resource movie read-back')
    bundle = cmf_package.make_bundle(resource, depot=MOVIE_DEPOT)
    metadata = cmf_package.make_metadata(bundle, depot=MOVIE_DEPOT)
    layout = cmf_panel.read_package(bundle, metadata, depot=MOVIE_DEPOT)
    offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 32 + 272)
    need(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size) == resource,
         'bundle does not extract to the resource')
    pack = out/'Mods'/PACK.name
    files = {}
    for path in sorted(p for p in PACK.rglob('*') if p.is_file()):
        target = pack/path.relative_to(PACK)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(path.read_bytes())
        files[target.relative_to(out).as_posix()] = sha(path.read_bytes())
    (pack/'content').mkdir(parents=True, exist_ok=True)
    for name, data in (('blob0.bundle', bundle), ('metadata.store', metadata)):
        (pack/'content'/name).write_bytes(data)
        files[(pack/'content'/name).relative_to(out).as_posix()] = sha(data)
    report = {'schema': 'cmf-test-movie-build-1', 'class': CLASS, 'source': sha(SOURCE.read_bytes()),
              'url': MOVIE_URL, 'depot': MOVIE_DEPOT, 'movie': sha(movie), 'movieSize': len(movie),
              'resource': sha(resource), 'bundle': sha(bundle), 'metadata': sha(metadata),
              'layout': layout['layout'], 'files': files, 'testOnly': True}
    (out/'test-movie-build.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--java', required=True)
    parser.add_argument('--ffdec', required=True, help='FFDec 26.3.0 ffdec.jar (with flashlib beside it)')
    parser.add_argument('--out', required=True, help='new output directory')
    args = parser.parse_args()
    print(json.dumps(build(args.java, args.ffdec, args.out), indent=1))


if __name__ == '__main__':
    main()
