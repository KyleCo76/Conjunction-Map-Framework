"""Independent, strict reader for the bounded one-entry v7 BC3 candidate."""
import hashlib
import struct
import zlib

PAGE = 4096
ENTRY = struct.Struct('<IiIIIIHHHHiIqBBBB')
FOOTER = struct.Struct('<QIIII4sI')


def _need(ok, why):
    if not ok:
        raise ValueError(why)


def name_hash31(name):
    value = 0
    for byte in name:
        value = (31 * value + byte) & 0xffffffff
    return value


def fnv64(data):
    value = 0xcbf29ce484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001b3) & 0xffffffffffffffff
    return value


def parse_cache(data, expected_name, expected_dimensions=None):
    """Parse every byte of one candidate cache; return exact decompressed block stream."""
    try:
        expected = expected_name.encode('ascii')
    except UnicodeEncodeError as error:
        raise ValueError('ASCII GUI key required') from error
    _need(b'\0' not in expected and expected and expected.lower() == expected, 'invalid GUI key')
    _need(len(data) >= FOOTER.size + ENTRY.size + 2, 'truncated cache')
    footer = data[-FOOTER.size:]
    fingerprint, pages, count, strings_size, mip_count, magic, version = FOOTER.unpack(footer)
    _need(magic == b'HCXT' and version == 7 and count == 1 and mip_count == 0, 'wrong footer/version/counts')
    table_start = len(data) - FOOTER.size - ENTRY.size - strings_size
    _need(table_start == pages * PAGE and table_start >= PAGE, 'page/table extent mismatch')
    string_table = data[table_start:table_start + strings_size]
    entry_bytes = data[table_start + strings_size:-FOOTER.size]
    _need(len(entry_bytes) == ENTRY.size and string_table == b'\0' + expected + b'\0', 'entry name/string sentinel')
    _need(fnv64(string_table + entry_bytes) == fingerprint, 'footer FNV64 mismatch')
    fields = dict(zip(('hash', 'string_table_offset', 'page_offset', 'compressed_size',
                       'uncompressed_size', 'base_alignment', 'width', 'height', 'mipcount',
                       'slice_count', 'mip_offset_index', 'num_mip_offsets', 'time_stamp',
                       'type1', 'type2', 'is_cube', 'unknown'), ENTRY.unpack(entry_bytes)))
    _need(fields['hash'] == name_hash31(expected), 'GUI hash31 mismatch')
    _need(fields['string_table_offset'] == 1 and fields['page_offset'] == 0, 'string/page offset')
    _need(fields['base_alignment'] == 16 and fields['mipcount'] == 1 and fields['slice_count'] == 1,
          'alignment/mip/slice candidate')
    _need(fields['mip_offset_index'] == 0 and fields['num_mip_offsets'] == 0x10000,
          'v7 mip flag or offset mismatch')
    _need((fields['type1'], fields['type2'], fields['is_cube'], fields['unknown'], fields['time_stamp'])
          == (8, 4, 0, 0, 0), 'candidate format/timestamp differs')
    width, height = fields['width'], fields['height']
    _need(width > 0 and height > 0 and width % 4 == 0 and height % 4 == 0,
          'invalid BC3 dimensions')
    if expected_dimensions is not None:
        _need((width, height) == tuple(expected_dimensions), 'unexpected dimensions')
    _need(fields['uncompressed_size'] == width * height, 'BC3 byte length differs')
    start = fields['page_offset'] * PAGE
    end = start + fields['compressed_size']
    _need(9 <= fields['compressed_size'] <= table_start and end <= table_start,
          'stream range outside pages')
    _need(table_start == (end + PAGE - 1) // PAGE * PAGE and not any(data[end:table_start]),
          'page padding/length mismatch')
    compressed_len, plain_len = struct.unpack_from('<II', data, start)
    _need(plain_len == fields['uncompressed_size'] and fields['compressed_size'] == 9 + compressed_len,
          'frame lengths mismatch')
    _need(data[start + 8] == 0, 'single-mip countdown mismatch')
    decoder = zlib.decompressobj()
    try:
        stream = decoder.decompress(data[start + 9:end]) + decoder.flush()
    except zlib.error as error:
        raise ValueError('zlib frame invalid') from error
    _need(decoder.eof and not decoder.unused_data and not decoder.unconsumed_tail
          and len(stream) == plain_len, 'zlib trailer or plain length invalid')
    return {'name': expected_name, 'fields': fields, 'stream': stream,
            'streamSha256': hashlib.sha256(stream).hexdigest(),
            'cacheSha256': hashlib.sha256(data).hexdigest(), 'footerFnv64': format(fingerprint, '016x'),
            'pageCount': pages, 'frameCompressedBytes': compressed_len,
            'pagePaddingBytes': table_start - end}
