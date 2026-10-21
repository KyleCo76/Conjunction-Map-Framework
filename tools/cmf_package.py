"""Panel resource packaging: CR2W movie swap, Remastered v5 bundle and v7 metadata.

Layouts are the ones tools/cmf_panel.py read_cr2w/read_package accept. Rebuilding
build/panel-runs/10-noop-package-output from its own resource reproduces that
engine-loaded pair byte for byte (tests/test_cmf_pin_fields.py).
"""
import struct
import zlib

import lz4.block

DEPOT = 'gameplay\\gui_new\\swf\\worldmap\\panel_worldmap.redswf'


def fnv64(data):
    value = 0xcbf29ce484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001b3) & 0xffffffffffffffff
    return value


def swap_movie(cr2w, movie):
    """Replace the CSwfResource movie buffer; fix sizes, offsets and CRCs."""
    data = bytearray(cr2w)
    if data[:4] != b'CR2W':
        raise ValueError('not a CR2W file')
    export_offset, export_count, _ = struct.unpack_from('<III', data, 40 + 12 * 4)
    exports = [list(struct.unpack_from('<HHIIIII', data, export_offset + 24 * i)) for i in range(export_count)]
    size, start = exports[0][3], exports[0][4]
    raw = bytes(data[start:start + size])
    pos = 1
    while True:
        name_id = struct.unpack_from('<H', raw, pos)[0]
        pos += 2
        if name_id == 0:
            break
        _, width = struct.unpack_from('<HI', raw, pos)
        pos += 6 + width - 4
    old_length = struct.unpack_from('<I', raw, pos)[0]
    tail = raw[pos + 4 + old_length:]
    if tail != b'\0' * 4:
        raise ValueError('unexpected data after the movie buffer')
    for export in exports[1:]:
        if export[4] < start + size:
            raise ValueError('an export precedes the movie export')
    for i in range(10):
        offset, count, _ = struct.unpack_from('<III', data, 40 + 12 * i)
        if count and offset >= start:
            raise ValueError('a table follows the movie export')
    new_raw = raw[:pos] + struct.pack('<I', len(movie)) + movie + tail
    delta = len(new_raw) - len(raw)
    out = bytearray(data[:start]) + new_raw + data[start + size:]
    exports[0][3], exports[0][6] = len(new_raw), zlib.crc32(new_raw)
    for export in exports[1:]:
        export[4] += delta
    for i, export in enumerate(exports):
        struct.pack_into('<HHIIIII', out, export_offset + 24 * i, *export)
    struct.pack_into('<I', out, 40 + 12 * 4 + 8, zlib.crc32(bytes(out[export_offset:export_offset + 24 * export_count])))
    struct.pack_into('<II', out, 24, len(out), len(out))
    struct.pack_into('<I', out, 32, zlib.crc32(bytes(out[:32]) + struct.pack('<I', 0xdeadbeef) + bytes(out[36:160])))
    return bytes(out)


def make_bundle(resource, packed=None, depot=DEPOT):
    """One-resource Remastered v5 bundle, LZ4HC payload at offset 4096 (depot: the resource's game path)."""
    if packed is None:
        packed = lz4.block.compress(resource, mode='high_compression', compression=9, store_size=False)
    if lz4.block.decompress(packed, uncompressed_size=len(resource)) != resource:
        raise ValueError('LZ4 payload does not round-trip')
    head = b'POTATO70' + struct.pack('<QIH', 4096 + len(packed), 304, 5) + struct.pack('<Q', 336) + b'\0\0'
    entry = depot.encode('ascii').ljust(256, b'\0') + b'\0' * 16
    entry += struct.pack('<QIIII', 4096, len(resource), len(packed), zlib.crc32(resource), 5) + b'\0' * 8
    return head + entry + b'\0' * (4096 - 336) + packed


def _count(value):
    # w3edit's variable-length count; it writes an empty array as 0x80.
    if value == 0:
        return b'\x80'
    out = bytearray([(value & 63) | (64 if value >> 6 else 0)])
    value >>= 6
    while value:
        out.append((value & 127) | (128 if value >> 7 else 0))
        value >>= 7
    return bytes(out)


def make_metadata(bundle, depot=DEPOT):
    """v7 metadata.store for a make_bundle output (one file, one lookup hash)."""
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
        records.extend(_count(len(rows)))
        for row in rows:
            records.extend(struct.pack(fmt, *row))

    table('<8I', [(0,) * 8, (where[depot], 0, packed, size, 1, 0, 0, 5)])
    table('<Q4I', [(0,) * 5, (offset, packed, 0, 1, 1)])
    table('<Q4I', [(0,) * 5, (total - 336, 336, where['blob0.bundle'], 1, 1)])
    table('<I', [])
    table('<ii', [(0, 0)] + [(where[name], i) for i, name in enumerate(parts[:-1])])
    table('<iii', [(1, len(parts) - 1, where[parts[-1]])])
    table('<QII', [(fnv64(depot.encode('ascii')), 1, 0)])
    return (b'\x03VTM' + struct.pack('<III', 7, packed, size) + _count(len(strings))
            + bytes(strings) + bytes(records))
