"""Bounded offline panel experiments. Never wired to the production build command.

Readers use only struct/zlib and do not call the serializers they validate.
The accepted CR2W topology is intentionally limited to the pinned map panel.
"""
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import time
import zlib

from cmf_build import confined, no_links, digest
from panel.cmf_abc import read_abc

ROOT = Path(__file__).resolve().parents[1]
PANEL_PATH = 'build/reference/panel-topology-2026-10-18/gameplay/gui_new/swf/worldmap/panel_worldmap.redswf'
PANEL_SHA = 'cbcd44c8e84a0b35bfa3dd548437385f632060e4c5c372ff3e7c58030c9d03fb'
TAIL_SHA = '031992dd5fe82d3be3eaca6a8c077f512bd7fd21798663a2029dea09c46cfcb3'
DEPOT = r'gameplay\gui_new\swf\worldmap\panel_worldmap.redswf'


def need(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def pinned(path, expected):
    data = no_links(path).read_bytes()
    need(sha(data) == expected, 'input hash mismatch')
    return data


def new_output(root, target):
    target = confined(root, target)
    need(not target.exists(), 'output already exists')
    target.mkdir(parents=True, exist_ok=False)
    return target


def require_artifacts(result, artifacts):
    need(result.get('returncode') == 0 and not result.get('timedOut') and
         not result.get('outputLimitExceeded'), 'child failed')
    need(bool(artifacts), 'no validated artifacts')
    for artifact in artifacts:
        need(Path(artifact).is_file() and Path(artifact).stat().st_size > 0, 'missing artifact')


def fnv64(data):
    value = 0xcbf29ce484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001b3) & 0xffffffffffffffff
    return value


def validate_lookup(records, depot=DEPOT):
    need(records == [(fnv64(depot.encode('ascii')), 1, 0)], 'empty/wrong lookup hash or file ID/upper word')


def read_package(bundle, metadata, depot=DEPOT):
    """Independent v5/v7 one-resource layout check. Extraction is a separate gate."""
    need(len(bundle) >= 4096 and bundle[:8] == b'POTATO70', 'bundle signature')
    total, toc, version = struct.unpack_from('<QIH', bundle, 8)
    need(total == len(bundle) and toc == 304 and version == 5, 'bundle version/EOF/TOC')
    need(struct.unpack_from('<Q', bundle, 22)[0] == 336 and bundle[30:32] == b'\0\0', 'bundle data boundary')
    entry = bundle[32:336]
    need(entry[:256] == depot.encode('ascii').ljust(256, b'\0'), 'bundle depot path')
    offset, size, packed, crc, codec = struct.unpack_from('<QIIII', entry, 272)
    need(offset == 4096 and size > 0 and packed > 0 and offset + packed == total and codec == 5, 'bundle range/codec')
    need(entry[256:272] == b'\0' * 16 and entry[296:304] == b'\0' * 8 and not any(bundle[336:offset]), 'bundle reserved/padding')
    need(len(metadata) >= 16 and metadata[:4] == b'\x03VTM', 'metadata signature')
    need(struct.unpack_from('<III', metadata, 4) == (7, packed, size), 'metadata version/maxima/stale pair')
    pos = 16
    def count():
        nonlocal pos
        need(pos < len(metadata), 'missing VLQ')
        byte = metadata[pos]; pos += 1
        negative, more, value, shift = byte & 128, byte & 64, byte & 63, 6
        for _ in range(4):
            if not more: break
            need(pos < len(metadata), 'short VLQ')
            byte = metadata[pos]; pos += 1
            value |= (byte & 127) << shift
            shift += 7; more = byte & 128
        need(not more and value <= 0x7fffffff and (not negative or value == 0), 'invalid VLQ')
        return value
    length = count()
    need(pos + length <= len(metadata), 'string table range')
    strings = metadata[pos:pos + length]; pos += length
    need(strings[:1] == b'\0', 'string sentinel')
    def text(offset):
        need(0 <= offset < len(strings) and (offset == 0 or strings[offset - 1] == 0), 'string offset')
        need(b'\0' in strings[offset:], 'string terminator')
        return strings[offset:strings.index(0, offset)].decode('ascii')
    def records(fmt, expected):
        nonlocal pos
        n = count(); width = struct.calcsize(fmt)
        need(n == expected and pos + n * width <= len(metadata), 'metadata count/range')
        values = list(struct.iter_unpack(fmt, metadata[pos:pos + n * width])); pos += n * width
        return values
    files = records('<8I', 2); entries = records('<Q4I', 2); bundles = records('<Q4I', 2)
    buffers = records('<I', 0); directories = records('<ii', 5); inits = records('<iii', 1)
    hashes = records('<QII', 1)
    need(pos == len(metadata), 'metadata trailing bytes')
    need(not any(files[0]) and not any(entries[0]) and not any(bundles[0]), 'null records')
    need(text(files[1][0]) == depot and files[1][1:] == (0, packed, size, 1, 0, 0, 5), 'file metadata/stale pair')
    need(entries[1] == (offset, packed, 0, 1, 1), 'entry relationship/stale pair')
    region, region_offset, name_offset, first, n = bundles[1]
    need((region, region_offset, first, n) == (total - 336, 336, 1, 1) and text(name_offset) == 'blob0.bundle', 'bundle metadata/stale pair')
    expected_dirs = [('', 0)] + [(name, i) for i, name in enumerate(depot.split('\\')[:-1])]
    need([(text(o), parent) for o, parent in directories] == expected_dirs, 'directory chain')
    need(inits[0][:2] == (1, 4) and text(inits[0][2]) == depot.split('\\')[-1], 'file init')
    validate_lookup(hashes, depot)
    return {'bundleSha256': sha(bundle), 'metadataSha256': sha(metadata), 'resourceSize': size,
            'packedSize': packed, 'offset': offset, 'crc32': crc, 'lookup': hashes,
            'pathHash': 0, 'pathHashRuntimeSemantics': 'UNOBSERVED', 'layout': 'PASS'}


def read_movie(data):
    need(len(data) > 8 and data[:3] in (b'CFX', b'GFX', b'CWS', b'FWS'), 'movie signature')
    declared = struct.unpack_from('<I', data, 4)[0]
    if data[:1] == b'C':
        decoder = zlib.decompressobj()
        body = decoder.decompress(data[8:], 16 * 1024 * 1024)
        need(decoder.eof and not decoder.unused_data and not decoder.unconsumed_tail, 'compressed framing')
    else:
        body = data[8:]
    need(8 < declared <= len(body) + 8, 'declared movie range')
    rect = (5 + 4 * (body[0] >> 3) + 7) // 8
    position = rect + 4
    framing = body[:position]
    tags = []
    while position < declared - 8:
        start = position
        need(position + 2 <= declared - 8, 'short tag')
        header = struct.unpack_from('<H', body, position)[0]
        position += 2
        code, size = header >> 6, header & 63
        if size == 63:
            need(position + 4 <= declared - 8, 'short tag length')
            size = struct.unpack_from('<I', body, position)[0]
            position += 4
        need(position + size <= declared - 8, 'tag outside declared movie')
        payload = body[position:position + size]
        position += size
        tags.append({'code': code, 'sha256': sha(body[start:position]), 'size': size,
                     'payload': payload})
        if code == 0:
            need(size == 0 and position == declared - 8, 'End boundary')
            break
    need(tags and tags[-1]['code'] == 0, 'missing End')
    tail = body[declared - 8:]
    return {'sha256': sha(data), 'bytes': len(data), 'version': data[3],
            'declared': declared, 'actual': len(body) + 8, 'framing': framing,
            'tail': tail, 'tailSha256': sha(tail), 'tags': tags}


def compare_movies(before, after, abc_change):
    need(before['tail'] == after['tail'], 'opaque movie tail changed')
    need(before['framing'] == after['framing'] and before['version'] == after['version'], 'movie framing changed')
    need([t['code'] for t in before['tags']] == [t['code'] for t in after['tags']], 'tag execution/timeline order changed')
    need([t for t in before['tags'] if t['code'] != 82] ==
         [t for t in after['tags'] if t['code'] != 82], 'non-ABC tags changed')
    need(sum(t['code'] == 82 for t in before['tags']) ==
         sum(t['code'] == 82 for t in after['tags']), 'ABC topology changed')
    def envelopes(movie):
        result = []
        for tag in movie['tags']:
            if tag['code'] == 82:
                payload = tag['payload']
                need(len(payload) >= 5 and b'\0' in payload[4:], 'invalid DoABC envelope')
                result.append(payload[:payload.index(0, 4) + 1])
        return result
    need(envelopes(before) == envelopes(after), 'DoABC flags/raw name changed')
    if not abc_change:
        need(before['tags'] == after['tags'], 'unexpected ABC change')


def restore_opaque_tail(original, candidate):
    """S02b1 experiment only: retain pinned opaque bytes beyond declared End.

    FFDec drops these bytes. Reassociate only when every non-ABC tag (including
    SymbolClass) remains exactly identical. Never fold the tail into FileLength.
    This is movie framing, not CR2W offset surgery or an engine acceptance claim.
    """
    need(sha(original) == '0cb272773faf936aabac6cd142c09eabea74f9e9b392694f569390fcb29a9f39', 'original movie pin')
    before, after = read_movie(original), read_movie(candidate)
    need(before['tailSha256'] == TAIL_SHA and len(before['tail']) == 1798, 'opaque tail pin')
    need(original[:4] == candidate[:4] == b'CFX\x0c', 'candidate signature/version')
    need(not after['tail'], 'candidate already has an opaque tail')
    comparable = dict(after, tail=before['tail'])
    compare_movies(before, comparable, True)
    decoded = zlib.decompress(candidate[8:])
    result = candidate[:8] + zlib.compress(decoded + before['tail'])
    compare_movies(before, read_movie(result), True)
    return result


def validate_abc_edit(before, after, body_index, expected_code):
    need(before['envelopeRaw'] == after['envelopeRaw'], 'DoABC flags/raw name changed')
    need(before['prefixSha256'] == after['prefixSha256'], 'ABC constants/definitions/namespaces changed')
    need(before['preservedPrefixRaw'] == after['preservedPrefixRaw'], 'raw ABC prefix/body-count encoding changed')
    need(before['bodyCount'] == after['bodyCount'], 'method body count changed')
    need(len(before['bodyRecords']) == len(after['bodyRecords']) == before['bodyCount'], 'body inventory count')
    need(0 <= body_index < before['bodyCount'], 'method body index')
    for index, (old, new) in enumerate(zip(before['bodyRecords'], after['bodyRecords'])):
        if index == body_index:
            need(new['code'] == expected_code, 'intended method instructions differ')
            permitted = ('code', 'raw', 'codeLengthRaw')
            need({k: v for k, v in old.items() if k not in permitted} ==
                 {k: v for k, v in new.items() if k not in permitted}, 'raw method header/exceptions/traits changed')
            if len(old['code']) == len(expected_code):
                need(old['codeLengthRaw'] == new['codeLengthRaw'], 'unchanged code-length encoding changed')
            else:
                # The sole permitted length-field change is this exact new
                # canonical u30. This calculates comparison bytes, not an asset.
                length, encoded = len(expected_code), bytearray()
                while length >= 128:
                    encoded.append((length & 127) | 128)
                    length >>= 7
                encoded.append(length)
                need(new['codeLengthRaw'] == bytes(encoded), 'unexpected changed code-length encoding')
        else:
            need(old['raw'] == new['raw'] and old == new, 'unrelated raw method changed')


def read_cr2w(data, topology='panel'):
    # mod-movie: a one-export original resource around a movie with code (CMF's own map-space test movie).
    need(topology in ('panel', 'original-vector', 'mod-movie'), 'unsupported topology mode')
    count_expected = 6 if topology == 'panel' else 1
    need(len(data) >= 160 and data[:4] == b'CR2W', 'CR2W signature/header')
    version, flags, stamp, build, size, buffersize, crc, chunks = struct.unpack_from('<IIQIIIII', data, 4)
    need(version == 164 and flags == stamp == build == 0 and size == buffersize == len(data) and chunks == count_expected, 'unsupported header')
    need(zlib.crc32(data[:32] + struct.pack('<I', 0xdeadbeef) + data[36:160]) == crc, 'header CRC')
    tables, ranges = [], [(0, 160)]
    for i, stride in enumerate((1, 8, 8, 16, 24, 24, 24, 0, 0, 0)):
        offset, count, crc = struct.unpack_from('<III', data, 40 + 12 * i)
        need(not count or (stride and offset >= 160 and offset + count * stride <= len(data)), 'table range')
        need(i not in (2, 5, 6, 7, 8, 9) or (offset == count == 0), 'unsupported topology')
        raw = data[offset:offset + count * stride] if count else b''
        need(zlib.crc32(raw) == crc, 'table CRC')
        tables.append((offset, count, raw))
        if count:
            ranges.append((offset, offset + len(raw)))
    need(tables[3][1] == (1 if topology == 'panel' else 0) and tables[4][1] == count_expected, 'property/export topology')
    strings = tables[0][2]
    names = []
    for offset, stored in struct.iter_unpack('<II', tables[1][2]):
        need(offset < len(strings) and b'\0' in strings[offset:], 'name offset')
        raw = strings[offset:strings.index(0, offset)]
        value = 0x811c9dc5 if raw else 0
        if raw:
            for byte in raw + b'\0':
                value = ((value ^ byte) * 0x01000193) & 0xffffffff
        need(value == stored, 'name hash')
        names.append(raw.decode('ascii'))
    exports, movie_bytes = [], None
    for i, (name, flag, parent, length, offset, template, stored) in enumerate(struct.iter_unpack('<HHIIIII', tables[4][2])):
        need(name < len(names) and offset >= 160 and offset + length <= len(data), 'export range')
        need(names[name] == ('CSwfResource' if i == 0 else 'CSwfTexture') and flag == 8192 and parent == (0 if i == 0 else 1) and template == 0, 'export topology')
        raw = data[offset:offset + length]
        need(zlib.crc32(raw) == stored, 'export CRC')
        ranges.append((offset, offset + length))
        need(raw[0] == 0, 'export prefix')
        pos, properties = 1, []
        while True:
            need(pos + 2 <= len(raw), 'property bounds')
            name_id = struct.unpack_from('<H', raw, pos)[0]
            pos += 2
            if name_id == 0:
                break
            need(pos + 6 <= len(raw), 'property header')
            type_id, count = struct.unpack_from('<HI', raw, pos)
            pos += 6
            need(name_id < len(names) and type_id < len(names) and count >= 4 and pos + count - 4 <= len(raw), 'property range')
            value = raw[pos:pos + count - 4]
            pos += count - 4
            if names[type_id] in ('CName', 'ETextureCompression'):
                need(len(value) == 2, 'name property width')
                index = struct.unpack('<H', value)[0]
                need(index < len(names), 'name property index')
                value = names[index]
            else:
                value = value.hex()
            properties.append({'name': names[name_id], 'type': names[type_id], 'value': value})
        buffer = raw[pos:]
        exports.append({'type': names[name], 'flags': flag, 'parent': parent, 'template': template,
                        'properties': properties, 'bufferSha256': sha(buffer), 'bufferSize': len(buffer)})
        if i == 0:
            length = struct.unpack_from('<I', buffer)[0]
            need(length + 8 == len(buffer) and buffer[-4:] == b'\0' * 4, 'movie/Unk1 boundary')
            movie_bytes = buffer[4:4 + length]
    ranges.sort()
    need(ranges[0][0] == 0 and ranges[-1][1] == len(data) and all(a[1] == b[0] for a, b in zip(ranges, ranges[1:])), 'gaps/overlap/EOF')
    if topology == 'mod-movie':
        need(len(exports[0]['properties']) == 1 and exports[0]['properties'][0]['name'] == 'linkageName'
             and exports[0]['properties'][0]['type'] == 'String', 'original resource property topology')
    if topology == 'original-vector':
        from cmf_asset_read import vector_movie
        vector_movie(movie_bytes)
        need(len(exports[0]['properties']) == 1 and exports[0]['properties'][0]['name'] == 'linkageName'
             and exports[0]['properties'][0]['type'] == 'String', 'original resource property topology')
        need(exports[0]['properties'][0]['value'] in ('8869636f6e2e737766', '88677269642e737766'), 'original linkage name')
    return {'sha256': sha(data), 'size': len(data), 'names': names, 'propertyTable': tables[3][2].hex(),
            'exports': exports, 'movieBytes': movie_bytes, 'movie': read_movie(movie_bytes)}


def compare_cr2w(before, after, expected_movie):
    need(after['names'] == before['names'] or
         (set(after['names']) == set(before['names']) | {'handle:CSwfTexture'} and
          len(after['names']) == len(before['names']) + 1), 'unexplained name normalization')
    need(before['propertyTable'] == after['propertyTable'], 'property table changed')
    need(before['exports'][1:] == after['exports'][1:], 'texture properties/payload changed')
    need({k: v for k, v in before['exports'][0].items() if k not in ('bufferSha256', 'bufferSize')} ==
         {k: v for k, v in after['exports'][0].items() if k not in ('bufferSha256', 'bufferSize')}, 'resource properties changed')
    need(after['movieBytes'] == expected_movie, 'movie bytes changed')


def public_report(value):
    """JSON evidence records hashes instead of redistributing retail bytes."""
    if isinstance(value, bytes):
        return {'bytes': len(value), 'sha256': sha(value)}
    if isinstance(value, dict):
        return {k: public_report(v) for k, v in value.items()}
    if isinstance(value, (tuple, list)):
        return [public_report(v) for v in value]
    return value


def save_json(path, value):
    with Path(path).open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(public_report(value), stream, indent=2)
        stream.write('\n')


def private_environment(run):
    env = os.environ.copy()
    for key in list(env):
        if key.startswith(('CARGO_', 'RUST', 'SCCACHE', 'CC_', 'CXX_', 'AR_', 'JAVA_', '_JAVA', 'JDK_', 'DOTNET_', 'COMPLUS_')) or key in ('CC', 'CXX', 'AR', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS'):
            del env[key]
    mapping = {'APPDATA': 'appdata', 'LOCALAPPDATA': 'localappdata', 'USERPROFILE': 'home',
               'HOME': 'home', 'TEMP': 'temp', 'TMP': 'temp', 'TMPDIR': 'temp',
               'XDG_CONFIG_HOME': 'config', 'XDG_CACHE_HOME': 'cache', 'NUGET_PACKAGES': 'nuget',
               'DOTNET_CLI_HOME': 'home'}
    for key, name in mapping.items():
        path = run / name
        path.mkdir(exist_ok=True)
        env[key] = str(path)
    env['HOMEDRIVE'], env['HOMEPATH'] = os.path.splitdrive(env['USERPROFILE'])
    return env


def run_tool(argv, run, timeout=60, overrides=None, initial_files=None):
    """Suspended child joins kill-on-close Windows job before it can spawn.

    This scoped compiler route permits 60 seconds; stdout/stderr have a 16MiB
    cap each. The job, not process-name matching, owns compiler descendants.
    """
    need(os.name == 'nt' and 0 < timeout <= 60, 'Windows bounded tool runner required')
    import ctypes
    from ctypes import wintypes
    run = new_output(ROOT / 'build/panel-runs', run)
    env = private_environment(run)
    env.update(overrides or {})
    for relative, content in (initial_files or {}).items():
        path = confined(run, run / relative)
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open('xb') as stream:
            stream.write(content)
    k = ctypes.WinDLL('kernel32', use_last_error=True)
    k.CreateJobObjectW.restype = wintypes.HANDLE
    k.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR]
    k.SetInformationJobObject.argtypes = [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD]
    k.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE]
    k.CloseHandle.argtypes = [wintypes.HANDLE]
    job = k.CreateJobObjectW(None, None)
    need(bool(job), 'CreateJobObject failed')
    # JOBOBJECT_EXTENDED_LIMIT_INFORMATION x64: LimitFlags at byte 16.
    limits = ctypes.create_string_buffer(144)
    struct.pack_into('<I', limits, 16, 0x2000)
    process = None
    start = time.monotonic()
    timed_out = exceeded = False
    try:
        need(k.SetInformationJobObject(job, 9, limits, len(limits)), 'job limits failed')
        with (run / 'stdout.log').open('xb') as stdout, (run / 'stderr.log').open('xb') as stderr:
            process = subprocess.Popen([str(a) for a in argv], cwd=run, env=env, stdin=subprocess.DEVNULL,
                                       stdout=stdout, stderr=stderr, creationflags=0x08000004)
            need(k.AssignProcessToJobObject(job, int(process._handle)), 'job assignment failed')
            nt = ctypes.WinDLL('ntdll')
            nt.NtResumeProcess.argtypes = [wintypes.HANDLE]
            need(nt.NtResumeProcess(int(process._handle)) == 0, 'resume failed')
            while process.poll() is None:
                timed_out = time.monotonic() - start > timeout
                exceeded = any((run / f'{name}.log').stat().st_size > 16 * 1024 * 1024 for name in ('stdout', 'stderr'))
                if timed_out or exceeded:
                    break
                time.sleep(0.1)
    finally:
        k.CloseHandle(job)
        if process is not None:
            if process.poll() is None:
                process.kill()
            process.wait(timeout=5)
    result = {'argv': [str(a) for a in argv], 'cwd': str(run), 'pid': process.pid,
              'returncode': process.returncode, 'timedOut': timed_out,
              'outputLimitExceeded': exceeded, 'seconds': time.monotonic() - start,
              'timeoutSeconds': timeout, 'ownership': 'suspended child assigned to kill-on-close job',
              'environmentOverrides': {key: value for key, value in env.items() if os.environ.get(key) != value}}
    save_json(run / 'command.json', result)
    return result


def package_resource(input_path, expected_sha, run_id, host_sha):
    """Developer-only host wrapper; pin, parse, package, extract, then judge.

    The reviewed host hash is explicit. Source hash and independent extraction
    bind the pair; a host's zero exit status is never an acceptance result.
    """
    import re
    import sys
    source = pinned(input_path, expected_sha)
    read_cr2w(source)
    need(bool(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,63}', run_id)), 'invalid run ID')
    runs = ROOT / 'build/panel-runs'
    output = confined(runs, runs / (run_id + '-output'))
    extract = confined(runs, runs / (run_id + '-extract'))
    need(not output.exists() and not extract.exists() and not (runs / (run_id + '-host')).exists()
         and not (runs / (run_id + '-reader')).exists(), 'occupied package run')
    host = ROOT / 'build/panel-runs/rust-target/x86_64-pc-windows-gnu/debug/examples/cmf_bundle_host.exe'
    pinned(host, host_sha)
    reader = ROOT / 'build/toolchains/s02b1/bundle_read.py'
    pinned(reader, 'f72dbeee7377c9705a003a54e243dfadbd18726302cc7609847bd8339760bfd1')
    result = run_tool([host, Path(input_path).absolute(), output], runs / (run_id + '-host'))
    require_artifacts(result, [output / 'blob0.bundle', output / 'metadata.store'])
    report = read_package((output / 'blob0.bundle').read_bytes(), (output / 'metadata.store').read_bytes())
    result = run_tool([sys.executable, '-B', reader, '--game', ROOT.parent / 'The Witcher 3',
                       'extract', output / 'blob0.bundle', '--out', extract, '--any-type', '--json'],
                      runs / (run_id + '-reader'))
    emitted = extract / Path(DEPOT.replace('\\', '/'))
    require_artifacts(result, [emitted])
    need(emitted.read_bytes() == source, 'independent extraction differs')
    pinned(input_path, expected_sha)
    report.update(result='PASS', scope='offline package only', sourceSha256=expected_sha,
                  hostSha256=host_sha, extractedSha256=digest(emitted))
    save_json(output / 'validation.json', report)
    return report


def main():
    """Offline readback/boundary CLI; never invokes production builds or games."""
    import argparse
    import re
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=('inspect-cr2w', 'inspect-movie', 'inspect-pair', 'restore-tail'))
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--second', type=Path)
    parser.add_argument('--second-sha256')
    parser.add_argument('--run-id', required=True)
    args = parser.parse_args()
    need(bool(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,63}', args.run_id)), 'invalid run ID')
    source = pinned(args.input, args.sha256)
    second = pinned(args.second, args.second_sha256) if args.second else None
    artifact = None
    if args.operation == 'inspect-cr2w': result = read_cr2w(source)
    elif args.operation == 'inspect-movie': result = read_movie(source)
    elif args.operation == 'inspect-pair':
        need(second is not None, 'metadata required as second input')
        result = read_package(source, second)
    else:
        need(second is not None, 'candidate movie required as second input')
        artifact = restore_opaque_tail(source, second)
        result = read_movie(artifact)
    output = new_output(ROOT / 'build/panel-runs', ROOT / 'build/panel-runs' / args.run_id)
    if artifact is not None:
        with (output / 'tail-preserved.gfx').open('xb') as stream:
            stream.write(artifact)
    save_json(output / 'inspection.json', {'scope': 'offline independent inspection', 'result': result})
    print(str(output / 'inspection.json'))


if __name__ == '__main__':
    main()
