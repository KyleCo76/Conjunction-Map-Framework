"""Read-only ABC structure inventory; never emits or patches bytecode."""
import struct
import hashlib


def read_abc(tag):
    def need(ok):
        if not ok:
            raise ValueError('unsupported/truncated ABC structure')
    need(len(tag) >= 9)
    flags = struct.unpack_from('<I', tag)[0]
    end = tag.index(0, 4)
    name, data = tag[4:end], tag[end + 1:]
    pos = 0
    def take(n):
        nonlocal pos
        need(n >= 0 and pos + n <= len(data))
        b = data[pos:pos + n]; pos += n
        return b
    def byte(): return take(1)[0]
    def uint():
        value = 0
        for shift in range(0, 35, 7):
            b = byte(); value |= (b & 127) << shift
            if b < 128: return value
        raise ValueError('overlong ABC integer')
    minor, major = struct.unpack('<HH', take(4))
    tables = {}
    def begin_table(key, sentinel=False, count=None):
        start = pos
        n = uint() if count is None else count
        table = {'count': n, 'countRaw': data[start:pos], 'records': []}
        tables[key] = table
        return range(max(0, n - int(sentinel)))
    def pool(key, read):
        values = []
        for _ in begin_table(key, True):
            start = pos; values.append(read()); tables[key]['records'].append(data[start:pos])
        return values
    ints = [0] + pool('ints', uint)
    uints = [0] + pool('uints', uint)
    doubles = [None] + pool('doubles', lambda: take(8).hex())
    strings = [''] + pool('strings', lambda: take(uint()).decode('utf-8'))
    namespaces = [None]
    for _ in begin_table('namespaces', True):
        start = pos
        kind, index = byte(), uint()
        need(kind in (5, 8, 22, 23, 24, 25, 26) and index < len(strings))
        namespaces.append({'kind': kind, 'uri': strings[index]})
        tables['namespaces']['records'].append(data[start:pos])
    sets = [None] + pool('sets', lambda: [uint() for _ in range(uint())])
    names = [None]
    for _ in begin_table('names', True):
        start = pos
        kind = byte()
        if kind in (7, 13): record = (kind, uint(), uint())
        elif kind in (15, 16): record = (kind, uint())
        elif kind in (17, 18): record = (kind,)
        elif kind in (9, 14): record = (kind, uint(), uint())
        elif kind in (27, 28): record = (kind, uint())
        elif kind == 29: record = (kind, uint(), [uint() for _ in range(uint())])
        else: raise ValueError('unsupported multiname kind: ' + str(kind))
        names.append(record)
        tables['names']['records'].append(data[start:pos])
    def resolve(index):
        need(index < len(names))
        if index == 0: return {'name': '*'}
        r = names[index]
        if r[0] in (7, 13): return {'kind': r[0], 'name': strings[r[2]], 'namespace': namespaces[r[1]]}
        if r[0] in (9, 14): return {'kind': r[0], 'name': strings[r[1]], 'namespaces': [namespaces[n] for n in sets[r[2]]]}
        if r[0] in (15, 16): return {'kind': r[0], 'name': strings[r[1]]}
        if r[0] in (27, 28): return {'kind': r[0], 'namespaces': [namespaces[n] for n in sets[r[1]]]}
        if r[0] == 29: return {'kind': r[0], 'base': resolve(r[1]), 'parameters': [resolve(n) for n in r[2]]}
        return {'kind': r[0]}
    methods = []
    for _ in begin_table('methods'):
        start = pos
        n, result = uint(), uint()
        parameters = [uint() for _ in range(n)]
        name_index, method_flags = uint(), byte()
        optional = [(uint(), byte()) for _ in range(uint())] if method_flags & 8 else []
        param_names = [strings[uint()] for _ in range(n)] if method_flags & 128 else []
        methods.append({'return': resolve(result), 'parameters': [resolve(i) for i in parameters],
                        'name': strings[name_index], 'flags': method_flags, 'optionalRaw': optional, 'parameterNames': param_names})
        tables['methods']['records'].append(data[start:pos])
    for _ in begin_table('metadata'):
        start = pos
        uint(); n = uint()
        for _ in range(2 * n): uint()
        tables['metadata']['records'].append(data[start:pos])
    def traits(raw_target=None):
        result = []
        count_start = pos; count = uint()
        raw = {'count': count, 'countRaw': data[count_start:pos], 'records': []}
        for _ in range(count):
            start = pos
            name_index, attr = uint(), byte()
            kind = attr & 15
            rec = {'name': resolve(name_index), 'kind': kind, 'attributes': attr >> 4}
            if kind in (0, 6):
                rec['slot'], typ, value = uint(), uint(), uint()
                rec['type'], rec['valueIndex'] = resolve(typ), value
                if value: rec['valueKind'] = byte()
            elif kind in (1, 2, 3):
                rec['dispatch'] = uint(); index = uint()
                need(index < len(methods)); rec['method'] = methods[index]; rec['methodIndex'] = index
            elif kind in (4, 5): rec['slot'], rec['index'] = uint(), uint()
            else: raise ValueError('unsupported trait')
            if attr & 64: rec['metadata'] = [uint() for _ in range(uint())]
            result.append(rec)
            raw['records'].append(data[start:pos])
        if raw_target is not None: raw_target.update(raw)
        return result
    classes = []
    instances_raw = []
    for _ in begin_table('instances'):
        start = pos
        name_index, super_index, class_flags = uint(), uint(), byte()
        protected = uint() if class_flags & 8 else 0
        interfaces = [resolve(uint()) for _ in range(uint())]
        initializer = uint()
        raw = {'headerRaw': data[start:pos], 'traits': {}}
        classes.append({'name': resolve(name_index), 'super': resolve(super_index), 'flags': class_flags,
                        'protected': namespaces[protected], 'interfaces': interfaces,
                        'initializer': methods[initializer], 'traits': traits(raw['traits'])})
        tables['instances']['records'].append(data[start:pos]); instances_raw.append(raw)
    for index in begin_table('classes', count=len(classes)):
        start = pos; c = classes[index]
        c['staticInitializer'] = methods[uint()]
        c['staticTraits'] = traits()
        tables['classes']['records'].append(data[start:pos])
    scripts = []
    for _ in begin_table('scripts'):
        start = pos
        index = uint(); scripts.append({'initializer': methods[index], 'traits': traits()})
        tables['scripts']['records'].append(data[start:pos])
    prefix = data[:pos]
    count_start = pos
    bodies = uint()
    preserved_prefix = data[:pos]
    body_count_raw = data[count_start:pos]
    body_records = []
    for _ in range(bodies):
        start = pos
        header = [uint() for _ in range(5)]
        header_end = pos
        code_length = uint()
        code_start = pos
        code = take(code_length)
        code_end = pos
        exceptions = [[uint() for _ in range(5)] for _ in range(uint())]
        body_traits = traits()
        body_records.append({'header': header, 'code': code, 'exceptions': exceptions, 'traits': body_traits,
                             'raw': data[start:pos], 'headerRaw': data[start:header_end],
                             'codeLengthRaw': data[header_end:code_start], 'suffixRaw': data[code_end:pos]})
    need(pos == len(data))
    return {'flags': flags, 'name': name.hex(), 'version': [minor, major], 'classes': classes,
            'scripts': scripts, 'namespaces': namespaces[1:], 'methodCount': len(methods), 'bodyCount': bodies,
            'prefixSha256': hashlib.sha256(prefix).hexdigest(), 'bodyRecords': body_records,
            'envelopeRaw': tag[:end + 1], 'bodyCountRaw': body_count_raw,
            'preservedPrefixRaw': preserved_prefix, 'tables': tables, 'instancesRaw': instances_raw,
            'pool': {'ints': ints, 'uints': uints, 'doubles': doubles, 'strings': strings,
                     'namespaces': namespaces, 'sets': sets, 'names': names}, 'methods': methods}
