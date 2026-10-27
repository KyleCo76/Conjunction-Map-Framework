"""Build the CMF pin-field map panel from the pinned vanilla resource (developer only).

Steps: export the vanilla movie with FFDec, apply source/panel/pin-fields/edits.json,
compile the edited classes with -importScript, restore the opaque movie tail, swap
the movie into the CR2W resource, package it, then gate the result:
  * a full re-export may differ from vanilla only in the edited classes;
  * tools/cmf_panel.py read_cr2w / compare_cr2w / read_package must pass;
  * the bundle must extract back to the exact resource.
--probe-controller also applies source/panel/pin-fields/probe-controller-edits.json on top (a probe-only
build that treats input as an Xbox pad for button pictures; never used for a release).
--probe-layer-tint also applies source/panel/pin-fields/probe-layer-tint-edits.json (a probe-only build that
tints each map zoom level a fixed colour, for the map blur investigation; never used for a release).
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
from panel.cmf_abc import read_abc


def abc(data):
    """The parsed DoABC tag of a movie (the same reader as cmf_region_build.abc)."""
    return read_abc(next(t['payload'] for t in cmf_panel.read_movie(data)['tags'] if t['code'] == 82))

ROOT = Path(__file__).resolve().parents[1]
EDITS = ROOT/'source/panel/pin-fields/edits.json'
MOVIE_HELPER = "red/game/witcher3/menus/worldmap/CMFMovieMap.as"
MOVIE_WRAPPER = "script_476.as"
MOVIE_INITIALIZATION = "Extensions.enabled = true;\nExtensions.noInvisibleAdvance = true;"
MOVIE_WRAPPER_TEXT = ('include "red/game/witcher3/menus/worldmap/MapMenu.as";\n'
                      'include "red/game/witcher3/menus/worldmap/CMFMovieMap.as";\n\n' + MOVIE_INITIALIZATION + '\n')
PROBE_CONTROLLER = ROOT/'source/panel/pin-fields/probe-controller-edits.json'
PROBE_LAYER_TINT = ROOT/'source/panel/pin-fields/probe-layer-tint-edits.json'


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


def changed_classes(before, after, added=(), scripts=None):
    names = {p.relative_to(before).as_posix() for p in before.rglob('*.as')}
    other = {p.relative_to(after).as_posix() for p in after.rglob('*.as')}
    allowed = set(added)
    need(not allowed or allowed == {MOVIE_HELPER}, 'unapproved added-class metadata')
    scripts = scripts or {}
    need(not scripts or scripts == {MOVIE_WRAPPER:MOVIE_WRAPPER_TEXT}, 'unapproved added-script metadata')
    if scripts:
        need(text(after/MOVIE_WRAPPER).strip() == MOVIE_WRAPPER_TEXT.strip(), 'wrapper content changed')
        native = text(before/'red/game/witcher3/menus/worldmap/MapMenu.as')
        need(native.count(MOVIE_INITIALIZATION) == 1, 'original initialization statements changed')
    allowed |= set(scripts)
    need(not (names & allowed), 'helper already exists in pinned vanilla')
    need(other == names | allowed, 'class set changed: %s' % sorted((names | allowed) ^ other))
    return sorted(allowed | {n for n in names if text(before/n) != text(after/n)})


def verify_added_classes(before, after, added):
    def names(movie):
        return {(c['name']['namespace']['kind'], c['name']['namespace']['uri'], c['name']['name'])
                for c in abc(movie)['classes']}
    original, current = names(before), names(after)
    # Existing FFDec export/import behavior, independently checked on the reviewed Task9 panel.
    private_renames = {
        (5, '', 'MapDebugInfo'): (5, 'MapMenu.as$476', 'MapDebugInfo'),
        (5, '', 'CategoryDefinition'): (5, 'HubMapPinPanel.as$344', 'CategoryDefinition'),
        (5, '', 'PinTypeDefinition'): (5, 'HubMapPinPanel.as$344', 'PinTypeDefinition'),
        (5, '', 'TargetProxy'): (5, 'GTween.as$225', 'TargetProxy'),
    }
    original = {private_renames.get(name,name) for name in original}
    expected = {(23, 'red.game.witcher3.menus.worldmap', 'CMFMovieMap')} if added else set()
    need(not original & expected, 'helper QName already exists in vanilla')
    need(current == original | expected, 'unexpected ABC class QName changes')


def probe_overlay(probe_controller, probe_layer_tint):
    """The probe-only changes asked for, merged class by class (controller first), or None."""
    files = [f for f, on in ((PROBE_CONTROLLER, probe_controller), (PROBE_LAYER_TINT, probe_layer_tint)) if on]
    if not files:
        return None
    classes = {}
    for f in files:
        for name, changes in json.loads(f.read_text(encoding='utf-8'))['classes'].items():
            classes.setdefault(name, []).extend(changes)
    return {'classes': classes}


def build(vanilla, java, jar, out, probe_controller=False, probe_layer_tint=False):
    out = Path(out)
    need(not out.exists(), 'output directory already exists')
    edits = json.loads(EDITS.read_text(encoding='utf-8'))
    overlay = probe_overlay(probe_controller, probe_layer_tint)
    added = edits.get('addedClasses', [])
    scripts = edits.get('addedScripts', {})
    need(not added or added == [MOVIE_HELPER], 'unapproved added-class metadata')
    expected = sorted(set(edits['classes']) | set(added) | set(scripts) | set(overlay['classes'] if overlay else ()))
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
    changed = changed_classes(work/'export-vanilla'/'scripts', work/'export-panel'/'scripts', added, scripts)
    need(changed == expected, 'unexpected changed classes: %s' % changed)
    verify_added_classes(movie, candidate, added)
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
    if probe_controller:
        report['probeController'] = sha(PROBE_CONTROLLER.read_bytes())
    if probe_layer_tint:
        report['probeLayerTint'] = sha(PROBE_LAYER_TINT.read_bytes())
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
    parser.add_argument('--probe-layer-tint', action='store_true',
                        help='probe build only: also apply probe-layer-tint-edits.json (never for a release)')
    args = parser.parse_args()
    print(json.dumps(build(args.vanilla, args.java, args.ffdec, args.out, args.probe_controller, args.probe_layer_tint), indent=1))


if __name__ == '__main__':
    main()
