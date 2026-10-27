"""Build Map Quest Insight adapter 2.1.0 with its Quest List movie and words (developer only, Kyle's PC).

The adapter's Quest List is its own small AS3 movie (source/adapters/map-quest-insight/movie-src/
MqiAdapterQuestList.as), shown by CMF API 13 as a screen movie drawing, plus the adapter's own string table
(source/adapters/map-quest-insight/strings.json). The cloud cannot compile Flash or write string tables, so this
tool runs on Kyle's PC with FFDec and Java (as the panel and the rev 13 test movie are built) and the creation
skill's w3strings.py.

Steps: tools/cmf_pack.py builds the adapter as for 2.0.0 (scripts, README, texture.cache); the movie is compiled
into a stub root of the same class with FFDec -importScript, wrapped in a one-export CSwfResource and packaged
at DEPOT (the game loads it as URL); w3strings.py writes the 18 language tables. Gates: the movie's only class is
MqiAdapterQuestList and a re-export shows cmfScreen and handleInput, the resource and the bundle read back, the
pack check has no errors, and the payload is exactly the expected file list. Writes build.json with every
file's SHA-256. Never deploys, never launches anything.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ADAPTER_SRC = ROOT/'source/adapters/map-quest-insight'
ADAPTER = ADAPTER_SRC/'modCMFAdapterMapQuestInsight'
MOD = ADAPTER.name
PROVIDER = 'modMapQuestInsight'
CLASS = 'MqiAdapterQuestList'
SOURCE = ADAPTER_SRC/'movie-src'/(CLASS + '.as')
STRINGS = ADAPTER_SRC/'strings.json'
URL = 'swf/modcmfadaptermqi/questlist.swf'
DEPOT = 'gameplay\\gui_new\\swf\\modcmfadaptermqi\\questlist.redswf'
LINKAGE = 'questlist.swf'
LANGUAGES = 'ar br cn cz de en es esmx fr hu it jp kr pl ru tr ua zh'.split()
DEFAULT_W3STRINGS = Path(os.environ.get('CMF_W3STRINGS', 'w3strings.py'))


def sha(data):
    return hashlib.sha256(data).hexdigest()


def need(ok, why):
    if not ok:
        raise ValueError(why)


def expected_files(pack_files):
    content = 'Mods/%s/content/' % MOD
    files = {'Mods/%s/%s' % (MOD, name) for name in pack_files}
    files |= {content + 'blob0.bundle', content + 'metadata.store'}
    files |= {content + lang + '.w3strings' for lang in LANGUAGES}
    return files


def build_movie(java, jar, work):
    """The compiled movie, its CSwfResource, bundle and metadata, each read back."""
    import lz4.block
    import cmf_package
    import cmf_panel
    from cmf_test_movie import ffdec, make_resource, movie_classes, stub_movie
    (work/'src').mkdir(parents=True)
    (work/'stub.swf').write_bytes(stub_movie(CLASS))
    (work/'src'/(CLASS + '.as')).write_bytes(SOURCE.read_bytes())
    ffdec(java, jar, '-onerror', 'abort', '-importScript', work/'stub.swf', work/'movie.swf', work/'src')
    movie = (work/'movie.swf').read_bytes()
    need(movie_classes(movie) == [CLASS], 'movie class set changed: %s' % movie_classes(movie))
    ffdec(java, jar, '-export', 'script', work/'export', work/'movie.swf')
    exported = (work/'export/scripts'/(CLASS + '.as')).read_text()
    need('function cmfScreen(' in exported and 'function handleInput(' in exported, 'movie entries missing')
    resource = make_resource(movie, LINKAGE)
    need(cmf_panel.read_cr2w(resource, 'mod-movie')['movieBytes'] == movie, 'resource readback mismatch')
    bundle = cmf_package.make_bundle(resource, depot=DEPOT)
    metadata = cmf_package.make_metadata(bundle, depot=DEPOT)
    cmf_panel.read_package(bundle, metadata, depot=DEPOT)
    offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 304)
    need(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size) == resource,
         'bundle readback mismatch')
    return movie, resource, bundle, metadata


def build(java, jar, w3strings, out):
    sys.path.insert(0, str(ROOT/'tools'))
    import cmf_pack
    out = Path(out)
    need(not out.exists(), 'output directory already exists; give a new one')
    tool = Path(w3strings or os.environ.get('CMF_W3STRINGS') or DEFAULT_W3STRINGS)
    need(tool.is_file(), 'w3strings.py not found: pass --w3strings or set CMF_W3STRINGS')
    payload = out/'payload'
    report, manifest = cmf_pack.build_pack(ADAPTER, payload, adapts=PROVIDER)
    need(not report.errors, 'pack check failed: %s' % report.errors)
    (payload/'pack-build.json').replace(out/'pack-build.json')
    content = payload/'Mods'/MOD/'content'
    need(not (content/'blob0.bundle').exists(), 'the adapter source already holds a bundle')
    movie, resource, bundle, metadata = build_movie(java, jar, out/'work')
    (content/'blob0.bundle').write_bytes(bundle)
    (content/'metadata.store').write_bytes(metadata)
    subprocess.run([sys.executable, '-B', str(tool), 'build', str(STRINGS), '--out', str(content)], check=True)
    pack_files = [name[len('Mods/%s/' % MOD):] for name in manifest['files']]
    actual = {p.relative_to(payload).as_posix() for p in payload.rglob('*') if p.is_file()}
    expected = expected_files(pack_files)
    need(actual == expected, 'unexpected or missing payload files: %s' % sorted(actual ^ expected))
    files = {name: sha((payload/name).read_bytes()) for name in sorted(expected)}
    record = {'schema': 'cmf-mqi-questlist-build-1', 'mod': MOD, 'provider': PROVIDER, 'url': URL, 'depot': DEPOT,
              'source': sha(SOURCE.read_bytes()), 'strings': sha(STRINGS.read_bytes()), 'movie': sha(movie),
              'resource': sha(resource), 'w3strings': sha(tool.read_bytes()), 'files': files,
              'packWarnings': report.warnings}
    (out/'build.json').write_text(json.dumps(record, indent=1) + '\n', encoding='utf-8', newline='\n')
    # Independent readback catches incomplete writes; the record never hashes itself.
    for name, digest in json.loads((out/'build.json').read_text(encoding='utf-8'))['files'].items():
        need(sha((payload/name).read_bytes()) == digest, 'payload readback failed: ' + name)
    (out/'SHA256SUMS').write_text(''.join('%s  %s\n' % (digest, name) for name, digest in files.items()),
                                  encoding='utf-8', newline='\n')
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--java', required=True)
    parser.add_argument('--ffdec', required=True, help='ffdec.jar')
    parser.add_argument('--w3strings', help='the creation skill\'s w3strings.py (default: Kyle\'s skill path or '
                        'CMF_W3STRINGS)')
    parser.add_argument('--out', required=True, help='a new folder; the adapter lands in <out>/payload')
    args = parser.parse_args()
    record = build(args.java, args.ffdec, args.w3strings, args.out)
    for name, digest in record['files'].items():
        print(digest, name)
    return 0


if __name__ == '__main__':
    sys.exit(main())
