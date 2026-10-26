"""Compile the original API13 screen-movie fixture; offline only, never deploys."""
import argparse
import json
from pathlib import Path
import struct
import lz4.block
from cmf_test_movie import stub_movie, movie_classes, ffdec, make_resource, need, sha
import cmf_package
import cmf_panel

ROOT = Path(__file__).resolve().parents[1]
CLASS = 'CMFTestRev13Movie'
SOURCE = ROOT / 'source/panel/rev13-test-movie' / (CLASS + '.as')
URL = 'swf/cmftestrev13movie/cmftestrev13movie.swf'
DEPOT = r'gameplay\gui_new\swf\cmftestrev13movie\cmftestrev13movie.redswf'


def build(java, jar, out):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    work = out / 'work'
    (work / 'src').mkdir(parents=True)
    (work / 'stub.swf').write_bytes(stub_movie(CLASS))
    (work / 'src' / (CLASS + '.as')).write_bytes(SOURCE.read_bytes())
    ffdec(java, jar, '-onerror', 'abort', '-importScript', work / 'stub.swf', work / 'movie.swf', work / 'src')
    movie = (work / 'movie.swf').read_bytes()
    need(movie_classes(movie) == [CLASS], 'fixture class set changed')
    ffdec(java, jar, '-export', 'script', work / 'export', work / 'movie.swf')
    exported = (work / 'export/scripts' / (CLASS + '.as')).read_text()
    need('function cmfScreen(' in exported and 'function handleInput(' in exported, 'fixture entries missing')
    resource = make_resource(movie, 'cmftestrev13movie.swf')
    need(cmf_panel.read_cr2w(resource, 'mod-movie')['movieBytes'] == movie, 'resource readback mismatch')
    bundle = cmf_package.make_bundle(resource, depot=DEPOT)
    metadata = cmf_package.make_metadata(bundle, depot=DEPOT)
    cmf_panel.read_package(bundle, metadata, depot=DEPOT)
    offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 304)
    need(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size) == resource, 'bundle readback mismatch')
    content = out / 'Mods/modCMFTestRev13Movie/content'
    content.mkdir(parents=True)
    (content / 'blob0.bundle').write_bytes(bundle)
    (content / 'metadata.store').write_bytes(metadata)
    report = dict(schema='cmf-rev13-test-movie-1', testOnly=True, source=sha(SOURCE.read_bytes()),
                  movie=sha(movie), resource=sha(resource), bundle=sha(bundle), metadata=sha(metadata), url=URL, depot=DEPOT)
    (out / 'test-movie-build.json').write_text(json.dumps(report, indent=1) + '\n')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--java', required=True)
    parser.add_argument('--ffdec', required=True)
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.java, args.ffdec, args.out), indent=1))


if __name__ == '__main__':
    main()
