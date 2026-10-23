"""Build the CMF pin-field map panel from the pinned vanilla resource (developer only).

Steps: export the vanilla movie with FFDec, apply source/panel/pin-fields/edits.json,
compile the edited classes with -importScript, restore the opaque movie tail, swap
the movie into the CR2W resource, package it, then gate the result:
  * a full re-export may differ from vanilla only in the edited classes;
  * tools/cmf_panel.py read_cr2w / compare_cr2w / read_package must pass;
  * the bundle must extract back to the exact resource.
--probe-controller also applies source/panel/pin-fields/probe-controller-edits.json on top (a probe-only
build that treats input as an Xbox pad for button pictures; never used for a release).
Never deploys or launches anything.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess

import lz4.block

import cmf_package
import cmf_panel

ROOT = Path(__file__).resolve().parents[1]
EDITS = ROOT/'source/panel/pin-fields/edits.json'
PROBE_CONTROLLER = ROOT/'source/panel/pin-fields/probe-controller-edits.json'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def need(ok, why):
    if not ok:
        raise ValueError(why)


def text(path):
    return path.read_text(encoding='utf-8').replace('\r\n', '\n')


def apply_edits(export_root, edits, out_root, overlay=None):
    """Write each edited class under out_root; every find must match exactly 'count' times.

    The overlay's changes (if any) apply after the class's own edits."""
    extra = overlay['classes'] if overlay else {}
    for relative in list(edits['classes']) + [c for c in extra if c not in edits['classes']]:
        source = text(export_root/relative)
        for change in edits['classes'].get(relative, []) + extra.get(relative, []):
            found = source.count(change['find'])
            need(found == change['count'], '%s: expected %d match(es), found %d for %r'
                 % (relative, change['count'], found, change['find'][:60]))
            source = source.replace(change['find'], change['replace'])
        target = out_root/relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source, encoding='utf-8', newline='\n')


def ffdec(java, jar, *args):
    result = subprocess.run([java, '-Djava.awt.headless=true', '-jar', str(jar)] + [str(a) for a in args],
                            stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=600)
    need(result.returncode == 0, 'FFDec failed: ' + (result.stderr or result.stdout)[-2000:])
    return result.stdout


def changed_classes(before, after):
    names = {p.relative_to(before).as_posix() for p in before.rglob('*.as')}
    other = {p.relative_to(after).as_posix() for p in after.rglob('*.as')}
    need(names == other, 'class set changed: %s' % sorted(names ^ other))
    return sorted(n for n in names if text(before/n) != text(after/n))


def build(vanilla, java, jar, out, probe_controller=False):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    edits = json.loads(EDITS.read_text(encoding='utf-8'))
    overlay = json.loads(PROBE_CONTROLLER.read_text(encoding='utf-8')) if probe_controller else None
    expected = sorted(set(edits['classes']) | set(overlay['classes'] if overlay else ()))
    original = Path(vanilla).read_bytes()
    need(sha(original) == edits['vanillaRedswfSha256'], 'vanilla resource hash mismatch')
    before = cmf_panel.read_cr2w(original)
    movie = before['movieBytes']
    need(sha(movie) == edits['vanillaMovieSha256'], 'vanilla movie hash mismatch')
    work = out/'work'
    work.mkdir(parents=True)
    (work/'vanilla.gfx').write_bytes(movie)
    ffdec(java, jar, '-export', 'script', work/'export-vanilla', work/'vanilla.gfx')
    apply_edits(work/'export-vanilla'/'scripts', edits, work/'src', overlay)
    ffdec(java, jar, '-onerror', 'abort', '-importScript', work/'vanilla.gfx', work/'compiled.gfx', work/'src')
    candidate = cmf_panel.restore_opaque_tail(movie, (work/'compiled.gfx').read_bytes())
    cmf_panel.compare_movies(cmf_panel.read_movie(movie), cmf_panel.read_movie(candidate), True)
    (work/'panel.gfx').write_bytes(candidate)
    ffdec(java, jar, '-export', 'script', work/'export-panel', work/'panel.gfx')
    changed = changed_classes(work/'export-vanilla'/'scripts', work/'export-panel'/'scripts')
    need(changed == expected, 'unexpected changed classes: %s' % changed)
    resource = cmf_package.swap_movie(original, candidate)
    cmf_panel.compare_cr2w(before, cmf_panel.read_cr2w(resource), candidate)
    bundle = cmf_package.make_bundle(resource)
    metadata = cmf_package.make_metadata(bundle)
    layout = cmf_panel.read_package(bundle, metadata)
    offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 32 + 272)
    need(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size) == resource,
         'bundle does not extract to the resource')
    content = out/'content'
    content.mkdir()
    (content/'blob0.bundle').write_bytes(bundle)
    (content/'metadata.store').write_bytes(metadata)
    report = {'schema': 'cmf-pin-panel-build-1', 'edits': sha(EDITS.read_bytes()), 'vanillaRedswf': sha(original),
              'movie': sha(candidate), 'resource': sha(resource), 'bundle': sha(bundle), 'metadata': sha(metadata),
              'changedClasses': changed, 'layout': layout['layout']}
    if overlay:
        report['probeController'] = sha(PROBE_CONTROLLER.read_bytes())
    (out/'build.json').write_text(json.dumps(report, indent=1) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--vanilla', required=True, help='pinned vanilla panel_worldmap.redswf')
    parser.add_argument('--java', required=True)
    parser.add_argument('--ffdec', required=True, help='FFDec 26.3.0 ffdec.jar (with flashlib beside it)')
    parser.add_argument('--out', required=True, help='new output directory')
    parser.add_argument('--probe-controller', action='store_true',
                        help='probe build only: also apply probe-controller-edits.json (never for a release)')
    args = parser.parse_args()
    print(json.dumps(build(args.vanilla, args.java, args.ffdec, args.out, args.probe_controller), indent=1))


if __name__ == '__main__':
    main()
