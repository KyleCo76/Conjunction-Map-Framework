"""Multi-entry v7 texture.cache writer for single-mip BC3 GUI images.

Mirrors the copied w3edit TextureCache insert/write layout (insertion order,
one page-aligned stream per entry, FNV-1a64 over strings + entries). A
single-entry cache built from the S03b frame reproduces that engine-loaded
cache byte for byte (tests/test_cmf_pin_fields.py).
"""
import struct
import zlib

from cmf_cooked_cache import ENTRY, FOOTER, PAGE, fnv64, name_hash31


def frame_bc3(stream):
    """Frame one BC3 block stream the way w3edit does: sizes, mip countdown, zlib."""
    packed = zlib.compress(stream, 6)
    return struct.pack('<II', len(packed), len(stream)) + b'\0' + packed


def build_cache(entries):
    """entries: [(gui_key, width, height, framed_stream)] in insertion order."""
    pages = bytearray()
    strings = bytearray(b'\0')
    table = bytearray()
    seen = set()
    for key, width, height, framed in entries:
        raw = key.encode('ascii')
        if not raw or raw != raw.lower() or b'\0' in raw or raw in seen:
            raise ValueError('GUI key must be unique, lower-case ASCII: %r' % key)
        if width % 4 or height % 4 or width <= 0 or height <= 0:
            raise ValueError('BC3 dimensions must be positive multiples of 4')
        packed_len, plain_len = struct.unpack_from('<II', framed)
        if plain_len != width * height or len(framed) != 9 + packed_len or framed[8] != 0:
            raise ValueError('framed stream does not match a single-mip BC3 image')
        seen.add(raw)
        page = len(pages) // PAGE
        name_offset = len(strings)
        pages += framed
        pages += b'\0' * (-len(pages) % PAGE)
        strings += raw + b'\0'
        table += ENTRY.pack(name_hash31(raw), name_offset, page, len(framed), plain_len, 16,
                            width, height, 1, 1, 0, 0x10000, 0, 8, 4, 0, 0)
    footer = FOOTER.pack(fnv64(bytes(strings) + bytes(table)), len(pages) // PAGE, len(entries),
                         len(strings), 0, b'HCXT', 7)
    return bytes(pages) + bytes(strings) + bytes(table) + footer


def read_entries(data):
    """Return [(key, width, height, plain BC3 stream)] for a cache build_cache can emit."""
    fingerprint, page_count, count, strings_size, mip_count, magic, version = FOOTER.unpack(data[-FOOTER.size:])
    if magic != b'HCXT' or version != 7 or mip_count != 0:
        raise ValueError('unsupported cache footer')
    table_end = len(data) - FOOTER.size
    table_start = table_end - count * ENTRY.size
    strings_start = table_start - strings_size
    if strings_start != page_count * PAGE:
        raise ValueError('page/table extent mismatch')
    strings = data[strings_start:table_start]
    if fnv64(strings + data[table_start:table_end]) != fingerprint:
        raise ValueError('footer FNV64 mismatch')
    result = []
    for index in range(count):
        fields = ENTRY.unpack_from(data, table_start + index * ENTRY.size)
        name_hash, name_offset, page, size, plain, _, width, height = fields[:8]
        key = strings[name_offset:strings.index(0, name_offset)]
        if name_hash != name_hash31(key):
            raise ValueError('GUI hash31 mismatch')
        start = page * PAGE
        packed_len, plain_len = struct.unpack_from('<II', data, start)
        stream = zlib.decompress(data[start + 9:start + 9 + packed_len])
        if plain_len != plain or len(stream) != plain or size != 9 + packed_len:
            raise ValueError('entry frame mismatch')
        result.append((key.decode('ascii'), width, height, stream))
    return result
