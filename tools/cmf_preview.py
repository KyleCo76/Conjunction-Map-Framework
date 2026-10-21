"""CMF preview packager: build, verify and promote immutable previews/ and dist/ folders.

A preview spec (source/previews/<label>.json) names each package (one mod folder per ZIP),
the README.txt that goes at that ZIP's root, and every shipped file with the staged copy it
comes from and the SHA-256 that was accepted in game. Nothing is rebuilt: the tool copies
accepted bytes and refuses any file whose hash differs.

  build   check the spec, then write <out>/<name>-<label>.zip per package, the notes file
          as README.md, SHA256SUMS and manifest.json (written last). Refuses an existing
          <out>, so a preview is never overwritten.
  verify  re-hash a built folder against SHA256SUMS and manifest.json, entry by entry. Takes a
          preview folder or a dist/<version> folder (the manifest schema says which).
  promote copy a release candidate (a preview folder that passed the final matrix) into
          dist/<version>/ byte for byte; only "-preview-N" leaves the ZIP names. A release spec
          (source/releases/<version>.json) supplies the release facts and three notes files.
          Refuses an existing <out>, a candidate whose own verify fails, a candidate other than
          the one the spec names, developer-only ZIP content and player README.txt files that
          still say "preview". ZIP contents are never rebuilt.

ZIPs are stored (uncompressed) with sorted entries and a fixed 1980-01-01 timestamp, so the
same inputs give the same bytes on any machine. Player packages never carry executables,
developer tooling, test packs or probe folders. Needs only the Python standard library.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = 'cmf-preview-spec-1'
MANIFEST_SCHEMA = 'cmf-preview-manifest-1'
DATE_TIME = (1980, 1, 1, 0, 0, 0)
ALLOWED_EXTS = {'.bundle', '.store', '.ws', '.w3strings', '.xml', '.cache', '.txt'}
# Never in a player package, whatever the spec says.
FORBIDDEN_EXTS = {'.exe', '.dll', '.asi', '.ps1', '.bat', '.cmd', '.py', '.sh', '.jar', '.zip'}
FORBIDDEN_NAMES = {'steam_appid.txt'}
DEV_FOLDER = re.compile(r'(test|probe)', re.I)
LABEL = '%s-preview-%d'
VERSION = re.compile(r'^\d+\.\d+\.\d+$')
SHA = re.compile(r'^[0-9a-f]{64}$')
MOD_NAME = re.compile(r'^mod[A-Za-z0-9_]+$')
ZIP_FORMAT = {'compression': 'stored', 'timestamp': '1980-01-01T00:00:00', 'order': 'sorted'}
SUMS_LINE = re.compile(r'^([0-9a-f]{64})  (\S+)$')
# Release (dist/) formats.
RELEASE_SPEC_SCHEMA = 'cmf-release-spec-1'
RELEASE_SCHEMA = 'cmf-release-manifest-1'
CANDIDATE = re.compile(r'^(\d+\.\d+\.\d+)-preview-([1-9]\d*)$')
COMMIT = re.compile(r'^[0-9a-f]{40}$')
RELEASE_ROLES = ('core', 'addon', 'adapter', 'example')
RELEASE_NOTES = ('README.md', 'rollback-notes.md', 'test-notes.md')
PLACEHOLDER = '<<FILL'
# Words that mark developer-only content in any part of a ZIP entry path (folders and file name).
DEV_WORDS = {'test', 'tests', 'probe', 'probes', 'tool', 'tools'}
SPEC_KEYS = {'schema', 'version', 'candidate', 'candidateManifestSha256', 'apiVersion', 'sourceCommit',
             'notes', 'matrix', 'notChecked', 'packages'}
PACKAGE_KEYS = {'role', 'needsApi', 'acceptance', 'adapts'}
MATRIX_KEYS = ('set', 'record', 'result', 'launched')


class SpecError(Exception):
    pass


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def label_of(spec):
    return LABEL % (spec['version'], spec['preview'])


def zip_name(package, label):
    return '%s-%s.zip' % (package['name'], label)


def check_archive_path(path, package_name):
    """Problems with one archive path, as a list of strings (empty when it may ship)."""
    problems = []
    pure = PurePosixPath(path)
    if '\\' in path or pure.is_absolute() or '..' in pure.parts or path != str(pure):
        return ['%s: not a plain relative path with forward slashes' % path]
    ext = pure.suffix.lower()
    if ext in FORBIDDEN_EXTS or pure.name.lower() in FORBIDDEN_NAMES:
        problems.append('%s: never ships in a player package' % path)
    elif ext not in ALLOWED_EXTS:
        problems.append('%s: extension %r is not on the allowlist' % (path, ext or '(none)'))
    menu = 'bin/config/r4game/user_config_matrix/pc/%s.xml' % package_name
    if pure.parts[0] == 'Mods':
        if len(pure.parts) < 3 or pure.parts[1] != package_name:
            problems.append('%s: outside Mods/%s/' % (path, package_name))
    elif path != menu:
        problems.append('%s: only Mods/%s/ and %s may ship' % (path, package_name, menu))
    if any(DEV_FOLDER.search(part) for part in pure.parts[:-1]):
        problems.append('%s: test or probe folder' % path)
    if path.lower() == 'readme.txt':
        problems.append('%s: the root README.txt comes from the package readme' % path)
    return problems


def check_spec(spec):
    """Every problem in a spec dictionary, as a list of strings."""
    problems = []
    if spec.get('schema') != SCHEMA:
        return ['schema is %r, expected %r' % (spec.get('schema'), SCHEMA)]
    if not VERSION.match(str(spec.get('version', ''))):
        problems.append('version must be X.Y.Z')
    if not isinstance(spec.get('preview'), int) or spec['preview'] < 1:
        problems.append('preview must be a whole number from 1')
    if not spec.get('gameBuild'):
        problems.append('gameBuild is missing')
    if not spec.get('notes'):
        problems.append('notes (the README.md for the preview folder) is missing')
    packages = spec.get('packages') or []
    if not packages:
        problems.append('no packages')
    names = set()
    for package in packages:
        name = package.get('name', '')
        if not MOD_NAME.match(name):
            problems.append('package name %r is not a mod folder name' % name)
            continue
        if DEV_FOLDER.search(name):
            problems.append('%s: test and probe packs never ship in a preview' % name)
        if name.lower() in names:
            problems.append('%s: listed twice' % name)
        names.add(name.lower())
        for key in ('role', 'readme', 'acceptance'):
            if not package.get(key):
                problems.append('%s: %s is missing' % (name, key))
        files = package.get('files') or {}
        if not any(p.startswith('Mods/%s/' % name) for p in files):
            problems.append('%s: ships no file under Mods/%s/' % (name, name))
        folded = set()
        for path, source in sorted(files.items()):
            problems.extend(check_archive_path(path, name))
            if path.lower() in folded:
                problems.append('%s: differs from another path only by case' % path)
            folded.add(path.lower())
            if not isinstance(source, dict) or not source.get('from'):
                problems.append('%s: no source' % path)
            elif not SHA.match(str(source.get('sha256', ''))):
                problems.append('%s: sha256 must be 64 lower-case hex digits' % path)
    return problems


def read_text_file(path):
    """Bytes of a README or notes file: ASCII, LF line endings, no BOM."""
    data = path.read_bytes()
    try:
        data.decode('ascii')
    except UnicodeDecodeError:
        raise SpecError('%s: not plain ASCII' % path)
    if b'\r' in data:
        raise SpecError('%s: has CR line endings; use LF' % path)
    if not data.strip():
        raise SpecError('%s: is empty' % path)
    return data


def collect(spec, sources, repo=ROOT):
    """Read every file the spec names and check its hash. Returns {package name: {path: bytes}}."""
    problems = check_spec(spec)
    if problems:
        raise SpecError('\n'.join(problems))
    out, errors = {}, []
    for package in spec['packages']:
        entries = {'README.txt': read_text_file(repo/package['readme'])}
        for path, source in sorted(package['files'].items()):
            origin = Path(sources)/source['from']
            if not origin.is_file():
                errors.append('%s: source %s is missing' % (path, origin))
                continue
            data = origin.read_bytes()
            if sha256(data) != source['sha256']:
                errors.append('%s: %s has SHA-256 %s, accepted %s' % (path, origin, sha256(data), source['sha256']))
                continue
            entries[path] = data
        out[package['name']] = entries
    if errors:
        raise SpecError('\n'.join(errors))
    return out


def make_zip(entries):
    """Deterministic stored ZIP of {archive path: bytes}, entries in sorted order."""
    raw = io.BytesIO()
    with zipfile.ZipFile(raw, 'w', compression=zipfile.ZIP_STORED) as archive:
        for path in sorted(entries):
            info = zipfile.ZipInfo(path, date_time=DATE_TIME)
            info.compress_type = zipfile.ZIP_STORED
            info.external_attr = 0o100644 << 16
            info.create_system = 0
            archive.writestr(info, entries[path])
    return raw.getvalue()


def build(spec, sources, out, repo=ROOT):
    """Write the preview folder; returns the manifest dictionary."""
    out = Path(out)
    if out.exists():
        raise SpecError('%s already exists; a preview is never overwritten (use the next preview number)' % out)
    label = label_of(spec)
    if out.name != label:
        raise SpecError('output folder must be named %s' % label)
    contents = collect(spec, sources, repo)
    notes = read_text_file(repo/spec['notes'])
    written, packages = {}, []
    for package in spec['packages']:
        entries = contents[package['name']]
        data = make_zip(entries)
        name = zip_name(package, label)
        written[name] = data
        packages.append({
            'zip': name, 'sha256': sha256(data), 'size': len(data), 'mod': package['name'],
            'role': package['role'], 'acceptance': package['acceptance'],
            'files': [{'path': p, 'sha256': sha256(entries[p]), 'size': len(entries[p]),
                       'source': package['files'][p]['from'] if p in package['files'] else package['readme']}
                      for p in sorted(entries)]})
    written['README.md'] = notes
    manifest = {
        'schema': MANIFEST_SCHEMA, 'label': label, 'version': spec['version'], 'preview': spec['preview'],
        'gameBuild': spec['gameBuild'], 'spec': spec.get('specPath', ''),
        'zip': {'compression': 'stored', 'timestamp': '1980-01-01T00:00:00', 'order': 'sorted'},
        'packages': packages,
        'other': [{'path': 'README.md', 'sha256': sha256(notes), 'source': spec['notes']}],
    }
    out.mkdir(parents=True)
    for name in sorted(written):
        (out/name).write_bytes(written[name])
    sums = ''.join('%s  %s\n' % (sha256(written[n]), n) for n in sorted(written))
    (out/'SHA256SUMS').write_bytes(sums.encode('ascii'))
    (out/'manifest.json').write_bytes((json.dumps(manifest, indent=1) + '\n').encode('ascii'))
    return manifest


def verify(folder):
    """Every problem with a built preview folder, as a list of strings."""
    folder = Path(folder)
    problems = []
    try:
        manifest = json.loads((folder/'manifest.json').read_text(encoding='ascii'))
        sums = (folder/'SHA256SUMS').read_text(encoding='ascii')
    except (OSError, ValueError) as error:
        return ['cannot read manifest.json or SHA256SUMS: %s' % error]
    if manifest.get('schema') == RELEASE_SCHEMA:
        try:
            return verify_release(folder, manifest, sums)
        except (KeyError, TypeError, AttributeError) as error:
            return ['manifest.json is malformed: %r' % error]
    if manifest.get('schema') != MANIFEST_SCHEMA:
        problems.append('manifest schema is %r' % manifest.get('schema'))
    if folder.name != manifest.get('label'):
        problems.append('folder name %s does not match label %s' % (folder.name, manifest.get('label')))
    listed, malformed = parse_sums(sums)
    problems.extend(malformed)
    present = {p.name for p in folder.iterdir() if p.is_file()} - {'SHA256SUMS', 'manifest.json'}
    for name in sorted(present ^ set(listed)):
        problems.append('%s: %s' % (name, 'not in SHA256SUMS' if name in present else 'listed but missing'))
    for name in sorted(present & set(listed)):
        if sha256((folder/name).read_bytes()) != listed[name]:
            problems.append('%s: SHA-256 differs from SHA256SUMS' % name)
    expected_zips = {p['zip'] for p in manifest.get('packages', [])}
    other = {o['path'] for o in manifest.get('other', [])}
    if expected_zips | other != set(listed):
        problems.append('SHA256SUMS and manifest.json list different files')
    for other_file in manifest.get('other', []):
        if listed.get(other_file['path']) != other_file['sha256']:
            problems.append('%s: manifest SHA-256 differs from SHA256SUMS' % other_file['path'])
    for package in manifest.get('packages', []):
        path = folder/package['zip']
        if not path.is_file():
            continue
        if listed.get(package['zip']) != package['sha256']:
            problems.append('%s: manifest SHA-256 differs from SHA256SUMS' % package['zip'])
        problems.extend(verify_zip(path, package))
    return problems


def parse_sums(text):
    """({file name: SHA-256} in file order, [problems]) from SHA256SUMS text."""
    listed, problems = {}, []
    for line in text.splitlines():
        match = SUMS_LINE.match(line)
        if not match:
            problems.append('SHA256SUMS line %r is malformed' % line)
            continue
        listed[match.group(2)] = match.group(1)
    return listed, problems


def verify_zip(path, package):
    try:
        return read_zip_problems(path, package)
    except (zipfile.BadZipFile, OSError, EOFError) as error:
        return ['%s: unreadable ZIP (%s)' % (path.name, error)]


def read_zip_problems(path, package):
    problems = []
    expected = {f['path']: f['sha256'] for f in package['files']}
    with zipfile.ZipFile(path) as archive:
        infos = archive.infolist()
        names = [i.filename for i in infos]
        if names != sorted(names):
            problems.append('%s: entries are not in sorted order' % path.name)
        if set(names) != set(expected) or len(names) != len(expected):
            problems.append('%s: entries differ from the manifest' % path.name)
        for info in infos:
            if tuple(info.date_time) != DATE_TIME or info.compress_type != zipfile.ZIP_STORED:
                problems.append('%s: %s is not stored with the fixed timestamp' % (path.name, info.filename))
            if info.filename != 'README.txt':
                problems.extend('%s: %s' % (path.name, p) for p in check_archive_path(info.filename, package['mod']))
            if info.filename in expected and sha256(archive.read(info)) != expected[info.filename]:
                problems.append('%s: %s SHA-256 differs from the manifest' % (path.name, info.filename))
    return problems


def word_list(name):
    """Lower-case words of one path part, in order: camelCase, digits and separators split it."""
    return [w.lower() for w in re.findall(r'[A-Z]+(?![a-z])|[A-Z]?[a-z]+|\d+', name)]


def name_words(name):
    return set(word_list(name))


def is_dev_part(part):
    words = word_list(part)
    app_id = 'appid' in words or any(a == 'app' and b == 'id' for a, b in zip(words, words[1:]))
    return app_id or bool(set(words) & DEV_WORDS)


def dev_content_problems(path):
    """Problems if a ZIP entry looks like developer-only content (test, probe, tool, App ID hint)."""
    pure = PurePosixPath(path)
    if any(is_dev_part(part) for part in list(pure.parts[:-1]) + [pure.stem]):
        return ['%s: developer-only content (test, probe, tool or App ID hint) never ships' % path]
    return []


def scan_release_zip(data, zip_label, mod):
    """Problems with the content of one ZIP that is to ship as a release: every archive rule,
    developer-only content, and player README.txt files that still say "preview"."""
    problems = []
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for info in archive.infolist():
                path = info.filename
                if path != 'README.txt':
                    problems.extend('%s: %s' % (zip_label, p) for p in check_archive_path(path, mod))
                problems.extend('%s: %s' % (zip_label, p) for p in dev_content_problems(path))
                if PurePosixPath(path).name.lower() == 'readme.txt' and b'preview' in archive.read(info).lower():
                    problems.append('%s: %s still says "preview"; the candidate\'s player text must be the '
                                    'release text (cut a new candidate)' % (zip_label, path))
    except (zipfile.BadZipFile, OSError, EOFError) as error:
        problems.append('%s: unreadable ZIP (%s)' % (zip_label, error))
    return problems


def has_placeholder(value):
    if isinstance(value, str):
        return PLACEHOLDER in value
    if isinstance(value, dict):
        return any(has_placeholder(k) or has_placeholder(v) for k, v in value.items())
    if isinstance(value, list):
        return any(has_placeholder(v) for v in value)
    return False


def is_count(value):
    return isinstance(value, int) and not isinstance(value, bool) and value >= 1


def check_release_spec(spec):
    """Every problem in a release spec dictionary, as a list of strings."""
    if not isinstance(spec, dict) or spec.get('schema') != RELEASE_SPEC_SCHEMA:
        return ['schema is %r, expected %r' % (spec.get('schema') if isinstance(spec, dict) else None,
                                               RELEASE_SPEC_SCHEMA)]
    problems = []
    if has_placeholder(spec):
        problems.append('the spec still has template placeholders (%s ...>>)' % PLACEHOLDER)
    for key in sorted(set(spec) - SPEC_KEYS - {'specPath'}):
        problems.append('unknown key %r' % key)
    version = str(spec.get('version', ''))
    if not VERSION.match(version):
        problems.append('version must be X.Y.Z')
    match = CANDIDATE.match(str(spec.get('candidate', '')))
    if not match or match.group(1) != version:
        problems.append('candidate must be %s-preview-<N>' % version)
    if not SHA.match(str(spec.get('candidateManifestSha256', ''))):
        problems.append('candidateManifestSha256 must be 64 lower-case hex digits')
    api = spec.get('apiVersion')
    if not is_count(api):
        problems.append('apiVersion must be a whole number from 1 (CMFGetVersion() at freeze)')
        api = None
    if not COMMIT.match(str(spec.get('sourceCommit', ''))):
        problems.append('sourceCommit must be the full 40-digit freeze commit')
    notes = spec.get('notes')
    if not isinstance(notes, dict) or sorted(notes) != sorted(RELEASE_NOTES) or \
            not all(isinstance(v, str) and v for v in notes.values()):
        problems.append('notes must name a repository file for each of %s' % ', '.join(RELEASE_NOTES))
    matrix = spec.get('matrix')
    if not isinstance(matrix, list) or not matrix:
        problems.append('matrix is empty; a release needs the final matrix records')
        matrix = []
    sets = set()
    for item in matrix:
        if not isinstance(item, dict) or sorted(item) != sorted(MATRIX_KEYS) or \
                not all(isinstance(item[k], str) and item[k] for k in MATRIX_KEYS):
            problems.append('matrix entry %r must have exactly %s' % (item, ', '.join(MATRIX_KEYS)))
            continue
        if item['set'] in sets:
            problems.append('matrix set %s listed twice' % item['set'])
        sets.add(item['set'])
        if item['result'] != 'PASS':
            problems.append('matrix set %s is %s; every set must PASS before promotion' % (item['set'], item['result']))
    not_checked = spec.get('notChecked')
    if not isinstance(not_checked, list) or not not_checked or \
            not all(isinstance(v, str) and v for v in not_checked):
        problems.append('notChecked must list what the release states as not checked')
    packages = spec.get('packages')
    if not isinstance(packages, dict) or not packages:
        return problems + ['no packages']
    for mod, package in sorted(packages.items()):
        if not MOD_NAME.match(mod) or name_words(mod) & DEV_WORDS:
            problems.append('%s: not a player mod folder name' % mod)
        if not isinstance(package, dict):
            problems.append('%s: must be an object' % mod)
            continue
        for key in sorted(set(package) - PACKAGE_KEYS):
            problems.append('%s: unknown key %r' % (mod, key))
        role = package.get('role')
        if role not in RELEASE_ROLES:
            problems.append('%s: role must be one of %s' % (mod, ', '.join(RELEASE_ROLES)))
        if not isinstance(package.get('acceptance'), str) or not package.get('acceptance'):
            problems.append('%s: acceptance is missing' % mod)
        needs = package.get('needsApi')
        if not is_count(needs) or (api is not None and needs > api):
            problems.append('%s: needsApi must be a whole number from 1 to apiVersion' % mod)
        adapts = package.get('adapts')
        if (adapts is not None) != (role == 'adapter'):
            problems.append('%s: adapts is required on adapters and only on adapters' % mod)
        elif adapts is not None:
            if not isinstance(adapts, dict) or not MOD_NAME.match(str(adapts.get('folder', ''))) or \
                    not adapts.get('name') or not adapts.get('version') or \
                    set(adapts) - {'folder', 'name', 'nexus', 'version'} or \
                    ('nexus' in adapts and not is_count(adapts['nexus'])):
                problems.append('%s: adapts needs folder, name and version (nexus optional, a number)' % mod)
    return problems


def read_notes(path):
    """Bytes of a release notes file; refuses unfilled template placeholders."""
    data = read_text_file(path)
    if PLACEHOLDER.encode('ascii') in data:
        raise SpecError('%s: still has template placeholders (%s ...>>)' % (path, PLACEHOLDER))
    return data


def promote(candidate, spec, out, repo=ROOT):
    """Copy a passing candidate into a new dist/<version> folder; returns the release manifest."""
    candidate, out = Path(candidate), Path(out)
    if out.exists():
        raise SpecError('%s already exists; a release is never overwritten (fixes become the next version)' % out)
    problems = check_release_spec(spec)
    if problems:
        raise SpecError('\n'.join(problems))
    version = spec['version']
    if out.name != version:
        raise SpecError('output folder must be named %s' % version)
    if candidate.name != spec['candidate']:
        raise SpecError('candidate folder %s is not %s, the candidate the spec names' % (candidate.name, spec['candidate']))
    problems = verify(candidate)
    if problems:
        raise SpecError('candidate %s fails its own verify:\n%s' % (candidate, '\n'.join(problems)))
    manifest_data = (candidate/'manifest.json').read_bytes()
    source = json.loads(manifest_data.decode('ascii'))
    if source.get('schema') != MANIFEST_SCHEMA:
        raise SpecError('%s is not a preview candidate (manifest schema %r)' % (candidate, source.get('schema')))
    if source['version'] != version:
        raise SpecError('candidate %s leads to version %s, not %s' % (candidate.name, source['version'], version))
    if sha256(manifest_data) != spec['candidateManifestSha256']:
        raise SpecError('%s/manifest.json has SHA-256 %s, not the %s the spec records for the tested candidate'
                        % (candidate, sha256(manifest_data), spec['candidateManifestSha256']))
    mods = [package['mod'] for package in source['packages']]
    errors = ['%s: in the candidate but not in the release spec' % m for m in mods if m not in spec['packages']]
    errors += ['%s: in the release spec but not in the candidate' % m for m in sorted(spec['packages']) if m not in mods]
    contents = {}
    for package in source['packages']:
        expected = '%s-%s.zip' % (package['mod'], source['label'])
        if package['zip'] != expected:
            errors.append('%s: candidate ZIP name should be %s' % (package['zip'], expected))
        data = (candidate/package['zip']).read_bytes()
        if sha256(data) != package['sha256']:
            errors.append('%s: changed while promoting' % package['zip'])
        errors.extend(scan_release_zip(data, package['zip'], package['mod']))
        contents[package['mod']] = data
    notes = {}
    for name in RELEASE_NOTES:
        try:
            notes[name] = read_notes(repo/spec['notes'][name])
        except (SpecError, OSError) as error:
            errors.append(str(error))
    if errors:
        raise SpecError('\n'.join(errors))
    written, packages = {}, []
    for package in source['packages']:
        data, release = contents[package['mod']], spec['packages'][package['mod']]
        entry = {'zip': '%s-%s.zip' % (package['mod'], version), 'sha256': sha256(data), 'size': len(data),
                 'mod': package['mod'], 'role': release['role'], 'version': version}
        if 'adapts' in release:
            entry['adapts'] = release['adapts']
        entry.update({'needsApi': release['needsApi'], 'acceptance': release['acceptance'],
                      'candidateZipSha256': package['sha256'], 'files': package['files']})
        written[entry['zip']] = data
        packages.append(entry)
    written.update(notes)
    manifest = {
        'schema': RELEASE_SCHEMA, 'label': version, 'version': version, 'gameBuild': source['gameBuild'],
        'apiVersion': spec['apiVersion'], 'sourceCommit': spec['sourceCommit'], 'spec': spec.get('specPath', ''),
        'promotedFrom': {'label': source['label'], 'manifestSha256': sha256(manifest_data)},
        'matrix': [{k: item[k] for k in MATRIX_KEYS} for item in spec['matrix']],
        'notChecked': spec['notChecked'], 'zip': source['zip'], 'packages': packages,
        'other': [{'path': n, 'sha256': sha256(notes[n]), 'source': spec['notes'][n]} for n in RELEASE_NOTES],
    }
    # The manifest is written first and listed in SHA256SUMS, so that one file vouches for everything.
    written['manifest.json'] = (json.dumps(manifest, indent=1) + '\n').encode('ascii')
    out.mkdir(parents=True)
    for name in sorted(written):
        (out/name).write_bytes(written[name])
    sums = ''.join('%s  %s\n' % (sha256(written[n]), n) for n in sorted(written))
    (out/'SHA256SUMS').write_bytes(sums.encode('ascii'))
    for package in source['packages']:
        if (out/('%s-%s.zip' % (package['mod'], version))).read_bytes() != contents[package['mod']]:
            raise SpecError('%s: written bytes differ from the candidate' % package['zip'])
    return manifest


def verify_release(folder, manifest, sums):
    """Every problem with a dist/<version> folder whose manifest has the release schema."""
    listed, problems = parse_sums(sums)
    if list(listed) != sorted(listed):
        problems.append('SHA256SUMS is not sorted by file name')
    version = manifest.get('version')
    if not VERSION.match(str(version)) or manifest.get('label') != version:
        problems.append('label and version must both be the release version X.Y.Z')
    if folder.name != version:
        problems.append('folder name %s does not match version %s' % (folder.name, version))
    if manifest.get('zip') != ZIP_FORMAT:
        problems.append('zip format is not stored, sorted, fixed timestamp')
    if not COMMIT.match(str(manifest.get('sourceCommit', ''))) or not is_count(manifest.get('apiVersion')):
        problems.append('sourceCommit or apiVersion is missing')
    promoted = manifest.get('promotedFrom') or {}
    match = CANDIDATE.match(str(promoted.get('label', '')))
    if not match or match.group(1) != version or not SHA.match(str(promoted.get('manifestSha256', ''))):
        problems.append('promotedFrom must name a %s-preview-<N> candidate and its manifest SHA-256' % version)
    matrix = manifest.get('matrix') or []
    if not matrix or any(item.get('result') != 'PASS' for item in matrix):
        problems.append('matrix must list the final sets, all PASS')
    if not manifest.get('notChecked'):
        problems.append('notChecked is empty')
    entries = list(folder.iterdir())
    problems.extend('%s: unexpected folder' % p.name for p in entries if not p.is_file())
    present = {p.name for p in entries if p.is_file()} - {'SHA256SUMS'}
    for name in sorted(present ^ set(listed)):
        problems.append('%s: %s' % (name, 'not in SHA256SUMS' if name in present else 'listed but missing'))
    for name in sorted(present & set(listed)):
        if sha256((folder/name).read_bytes()) != listed[name]:
            problems.append('%s: SHA-256 differs from SHA256SUMS' % name)
    zips = {p['zip'] for p in manifest.get('packages', [])}
    other = {o['path'] for o in manifest.get('other', [])}
    if not zips:
        problems.append('no packages')
    if zips | other | {'manifest.json'} != set(listed):
        problems.append('SHA256SUMS and manifest.json list different files')
    if sorted(other) != sorted(RELEASE_NOTES):
        problems.append('other must list %s' % ', '.join(RELEASE_NOTES))
    for other_file in manifest.get('other', []):
        if listed.get(other_file['path']) != other_file['sha256']:
            problems.append('%s: manifest SHA-256 differs from SHA256SUMS' % other_file['path'])
        path = folder/other_file['path']
        if path.is_file() and PLACEHOLDER.encode('ascii') in path.read_bytes():
            problems.append('%s: still has template placeholders' % other_file['path'])
    for package in manifest.get('packages', []):
        name, mod = package['zip'], package['mod']
        if name != '%s-%s.zip' % (mod, version) or package.get('version') != version:
            problems.append('%s: must be %s-%s.zip with version %s' % (name, mod, version, version))
        if package.get('role') not in RELEASE_ROLES:
            problems.append('%s: role %r is not one of %s' % (name, package.get('role'), ', '.join(RELEASE_ROLES)))
        if ('adapts' in package) != (package.get('role') == 'adapter'):
            problems.append('%s: adapts belongs on adapters and only on adapters' % name)
        if package.get('sha256') != package.get('candidateZipSha256'):
            problems.append('%s: SHA-256 differs from the candidate\'s ZIP; a release copies it byte for byte' % name)
        if listed.get(name) != package['sha256']:
            problems.append('%s: manifest SHA-256 differs from SHA256SUMS' % name)
        path = folder/name
        if path.is_file():
            problems.extend(verify_zip(path, package))
            problems.extend(p for p in scan_release_zip(path.read_bytes(), name, mod) if p not in problems)
    return problems


def load_release_spec(path):
    spec = json.loads(Path(path).read_text(encoding='utf-8'))
    if isinstance(spec, dict):
        try:
            spec['specPath'] = Path(path).resolve().relative_to(ROOT).as_posix()
        except ValueError:
            spec['specPath'] = Path(path).name
    return spec


def load_spec(path):
    spec = json.loads(Path(path).read_text(encoding='utf-8'))
    try:
        spec['specPath'] = Path(path).resolve().relative_to(ROOT).as_posix()
    except ValueError:
        spec['specPath'] = Path(path).name
    return spec


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest='command', required=True)
    b = sub.add_parser('build', help='write a new preview folder from a spec')
    b.add_argument('--spec', required=True, help='source/previews/<label>.json')
    b.add_argument('--sources', required=True, help='folder the spec\'s "from" paths are relative to (the shared probes folder)')
    b.add_argument('--out', required=True, help='new folder previews/<label>; must not exist')
    v = sub.add_parser('verify', help='check a built preview or dist folder')
    v.add_argument('folder')
    p = sub.add_parser('promote', help='copy a passing release candidate into dist/<version>, byte for byte')
    p.add_argument('--candidate', required=True, help='the preview folder that passed the final matrix')
    p.add_argument('--version', required=True, help='the release version, X.Y.Z')
    p.add_argument('--spec', help='release spec; default source/releases/<version>.json')
    p.add_argument('--out', required=True, help='new folder dist/<version>; must not exist')
    args = parser.parse_args(argv)
    try:
        if args.command == 'build':
            manifest = build(load_spec(args.spec), args.sources, args.out)
            for package in manifest['packages']:
                print('%s  %s  (%d files)' % (package['sha256'], package['zip'], len(package['files'])))
            problems = verify(args.out)
        elif args.command == 'promote':
            spec = load_release_spec(args.spec or ROOT/('source/releases/%s.json' % args.version))
            if not isinstance(spec, dict) or spec.get('version') != args.version:
                raise SpecError('release spec is not for version %s' % args.version)
            manifest = promote(args.candidate, spec, args.out)
            for package in manifest['packages']:
                print('%s  %s  (from %s)' % (package['sha256'], package['zip'], manifest['promotedFrom']['label']))
            problems = verify(args.out)
        else:
            problems = verify(args.folder)
    except SpecError as error:
        print('REFUSED\n%s' % error, file=sys.stderr)
        return 1
    for problem in problems:
        print('ERROR   ' + problem, file=sys.stderr)
    print('verify: %s' % ('FAIL' if problems else 'PASS'))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
