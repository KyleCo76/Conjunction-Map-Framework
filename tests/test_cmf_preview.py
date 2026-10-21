"""Preview packager: spec checks, deterministic ZIPs, verification and the committed preview.

The rebuild case reads the staged probe copies (CMF_PROBES, default the project's shared
the private development records) and skips when they are absent; a skipped case is not
qualification. The committed-preview case runs everywhere.
"""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_preview as preview

SPEC = ROOT/'source/previews/1.0.0-preview-1.json'
BUILT = ROOT/'previews/1.0.0-preview-1'
SPEC2 = ROOT/'source/previews/1.0.0-preview-2.json'
BUILT2 = ROOT/'previews/1.0.0-preview-2'
# Preview 2 was cut from this commit: its shipped text files equal the repository there. Later commits may
# change the sources; the preview stays frozen.
PREVIEW2_CUT = 'e166070e14f8cc05f588c2cee4fcab3a4666520e'
PROBES = Path(os.environ.get('CMF_PROBES', str(ROOT/'probes')))
# Shipped text files that also live in the repository; the accepted bytes must equal them.
REPO_COPIES = {
    'Mods/mod0000_ConjunctionMapFramework/content/scripts/local/cmfCore.ws': 'source/core/content/scripts/local/cmfCore.ws',
    'Mods/mod0000_ConjunctionMapFramework/content/scripts/local/cmfSettings.ws': 'source/core/content/scripts/local/cmfSettings.ws',
    'bin/config/r4game/user_config_matrix/pc/mod0000_ConjunctionMapFramework.xml': 'source/settings/menus/mod0000_ConjunctionMapFramework.xml',
    'Mods/modCMFMinimapPanel/content/scripts/local/cmfMinimap.ws': 'source/minimap/content/scripts/local/cmfMinimap.ws',
    'Mods/modCMFExampleIconPack/content/scripts/local/modcmfexampleiconpack_cmf.ws': 'examples/modCMFExampleIconPack/content/scripts/local/modcmfexampleiconpack_cmf.ws',
    'Mods/modCMFExampleIconPack/README.txt': 'examples/modCMFExampleIconPack/README.txt',
}
ADAPTERS = {'modCMFAdapterInkAndIron': 'ink-and-iron', 'modCMFAdapterMapQuestInsight': 'map-quest-insight',
            'modCMFAdapterWitcherGearMap': 'witcher-gear-map', 'modCMFAdapterGwentPlayersMap': 'gwent-players-map'}


def at_cut(path):
    """The repository file as committed at PREVIEW2_CUT; skips the case where git or the commit is missing."""
    try:
        return subprocess.run(['git', 'show', '%s:%s' % (PREVIEW2_CUT, path)], cwd=ROOT, capture_output=True,
                              check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        raise unittest.SkipTest('git history with commit %s absent' % PREVIEW2_CUT[:7])


def sha(data):
    return hashlib.sha256(data).hexdigest()


def spec():
    return json.loads(SPEC.read_text(encoding='utf-8'))


def spec2():
    return json.loads(SPEC2.read_text(encoding='utf-8'))


def synthetic(tmp):
    """A two-package spec over small files written under tmp/src, with READMEs in tmp/repo."""
    src, repo = tmp/'src', tmp/'repo'
    files = {
        'modCMFDemo': {'Mods/modCMFDemo/content/scripts/local/demo.ws': b'function CMFDemo() {}\n',
                       'Mods/modCMFDemo/content/blob0.bundle': bytes(range(256)) * 4,
                       'bin/config/r4game/user_config_matrix/pc/modCMFDemo.xml': b'<UserConfig/>\n'},
        'modCMFDemoPack': {'Mods/modCMFDemoPack/content/texture.cache': b'\x00cache' * 10},
    }
    packages = []
    for name, entries in files.items():
        listed = {}
        for path, data in entries.items():
            (src/name/path).parent.mkdir(parents=True, exist_ok=True)
            (src/name/path).write_bytes(data)
            listed[path] = {'from': '%s/%s' % (name, path), 'sha256': sha(data)}
        (repo/name).mkdir(parents=True)
        (repo/name/'README.txt').write_bytes(b'%s readme\n' % name.encode())
        packages.append({'name': name, 'role': 'demo', 'readme': '%s/README.txt' % name,
                         'acceptance': 'synthetic', 'files': listed})
    (repo/'NOTES.md').write_bytes(b'# notes\n')
    return {'schema': preview.SCHEMA, 'version': '1.0.0', 'preview': 3, 'gameBuild': '5.0.1048522',
            'notes': 'NOTES.md', 'packages': packages}, src, repo


class SpecTests(unittest.TestCase):
    @unittest.skipUnless(SPEC.is_file(), 'committed previews live in the private development repository')
    def test_committed_spec_is_valid(self):
        self.assertEqual(preview.check_spec(spec()), [])
        self.assertEqual(preview.label_of(spec()), '1.0.0-preview-1')

    @unittest.skipUnless(SPEC.is_file(), 'committed previews live in the private development repository')

    def test_spec_ships_core_minimap_and_example_pack_only(self):
        names = [p['name'] for p in spec()['packages']]
        self.assertEqual(names, ['mod0000_ConjunctionMapFramework', 'modCMFMinimapPanel', 'modCMFExampleIconPack'])
        core = spec()['packages'][0]['files']
        self.assertEqual(len([p for p in core if p.endswith('.w3strings')]), 18)
        self.assertIn('Mods/mod0000_ConjunctionMapFramework/content/blob0.bundle', core)

    @unittest.skipUnless(SPEC.is_file(), 'committed previews live in the private development repository')

    def test_accepted_text_files_equal_repository_sources(self):
        listed = {p: s['sha256'] for package in spec2()['packages'] for p, s in package['files'].items()}
        for path, source in REPO_COPIES.items():
            if path in listed:
                self.assertEqual(listed[path], sha(at_cut(source)), path)
        for name, folder in ADAPTERS.items():
            repo = 'source/adapters/%s/%s/' % (folder, name)
            for path in [p for p in listed if p.startswith('Mods/%s/' % name) and not p.endswith('.cache')]:
                self.assertEqual(listed[path], sha(at_cut(repo + path.split('/', 2)[2])), path)

    @unittest.skipUnless(SPEC.is_file(), 'committed previews live in the private development repository')

    def test_preview2_spec_ships_the_launched_set(self):
        self.assertEqual(preview.check_spec(spec2()), [])
        self.assertEqual(preview.label_of(spec2()), '1.0.0-preview-2')
        names = [p['name'] for p in spec2()['packages']]
        self.assertEqual(names, ['mod0000_ConjunctionMapFramework', 'modCMFAdapterInkAndIron',
                                 'modCMFAdapterMapQuestInsight', 'modCMFAdapterWitcherGearMap',
                                 'modCMFAdapterGwentPlayersMap', 'modCMFMinimapPanel'])
        core = spec2()['packages'][0]['files']
        self.assertEqual(core['Mods/mod0000_ConjunctionMapFramework/content/blob0.bundle']['sha256'],
                         '15657c05feffa7818640943b8ded3a7d8cdb916aecd11a002750580b2b70a6c5')
        for package in spec2()['packages']:
            text = preview.read_text_file(ROOT/package['readme']).decode('ascii')
            self.assertIn('1.0.0-preview-2', text, package['name'])
            self.assertIn('not approved/endorsed by CD PROJEKT RED', text, package['name'])
            self.assertIn('UNINSTALL', text, package['name'])

    @unittest.skipUnless(SPEC.is_file(), 'committed previews live in the private development repository')

    def test_readmes_are_plain_and_claim_no_test(self):
        for package in spec()['packages']:
            text = preview.read_text_file(ROOT/package['readme']).decode('ascii')
            self.assertIn('not approved/endorsed by CD PROJEKT RED', text, package['name'])
            self.assertIn('1.0.0-preview-1', text, package['name'])
            self.assertNotRegex(text.lower(), r'\btested (on|with|in)\b', package['name'])
            self.assertIn('UNINSTALL', text, package['name'])
        core = (ROOT/spec()['packages'][0]['readme']).read_text(encoding='ascii')
        self.assertIn('5.0.1048522', core)

    def test_archive_path_rules(self):
        ok = 'Mods/modX/content/scripts/local/x.ws'
        self.assertEqual(preview.check_archive_path(ok, 'modX'), [])
        self.assertEqual(preview.check_archive_path('bin/config/r4game/user_config_matrix/pc/modX.xml', 'modX'), [])
        bad = ['Mods/modX/tool.exe', 'Mods/modX/build.py', 'Mods/modX/steam_appid.txt',
               'Mods/modY/content/a.ws', 'Mods/modX/content/test/a.ws', 'Mods\\modX\\a.ws',
               'Mods/modX/../modY/a.ws', 'bin/config/r4game/user_config_matrix/pc/modY.xml',
               'Mods/modX/content/a.png', 'README.txt', 'Mods/modX']
        for path in bad:
            self.assertTrue(preview.check_archive_path(path, 'modX'), path)

    @unittest.skipUnless(SPEC.is_file(), 'committed previews live in the private development repository')

    def test_spec_refuses_test_packs_and_bad_hashes(self):
        broken = copy.deepcopy(spec())
        broken['packages'].append({'name': 'modCMFTestIconPack', 'role': 'x', 'readme': 'r', 'acceptance': 'a',
                                   'files': {'Mods/modCMFTestIconPack/content/a.ws': {'from': 'a', 'sha256': '0' * 64}}})
        broken['packages'][0]['files']['Mods/mod0000_ConjunctionMapFramework/content/blob0.bundle']['sha256'] = 'ABC'
        problems = '\n'.join(preview.check_spec(broken))
        self.assertIn('modCMFTestIconPack: test and probe packs never ship', problems)
        self.assertIn('sha256 must be', problems)


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.spec, self.src, self.repo = synthetic(self.root)

    def tearDown(self):
        self.tmp.cleanup()

    def build(self, name='1.0.0-preview-3'):
        return preview.build(self.spec, self.src, self.root/'out'/name, self.repo)

    def test_build_writes_verifiable_deterministic_folder(self):
        manifest = self.build()
        out = self.root/'out/1.0.0-preview-3'
        self.assertEqual(sorted(p.name for p in out.iterdir()),
                         ['README.md', 'SHA256SUMS', 'manifest.json', 'modCMFDemo-1.0.0-preview-3.zip',
                          'modCMFDemoPack-1.0.0-preview-3.zip'])
        self.assertEqual(preview.verify(out), [])
        with zipfile.ZipFile(out/'modCMFDemo-1.0.0-preview-3.zip') as archive:
            self.assertEqual(archive.namelist(), sorted(archive.namelist()))
            self.assertIn('README.txt', archive.namelist())
            self.assertEqual(archive.read('Mods/modCMFDemo/content/blob0.bundle'), bytes(range(256)) * 4)
        second = preview.build(self.spec, self.src, self.root/'again/1.0.0-preview-3', self.repo)
        self.assertEqual([p['sha256'] for p in manifest['packages']], [p['sha256'] for p in second['packages']])

    def test_build_never_overwrites(self):
        self.build()
        with self.assertRaisesRegex(preview.SpecError, 'never overwritten'):
            self.build()

    def test_build_refuses_wrong_folder_name(self):
        with self.assertRaisesRegex(preview.SpecError, 'must be named 1.0.0-preview-3'):
            self.build('1.0.0-preview-4')

    def test_build_refuses_changed_or_missing_source(self):
        (self.src/'modCMFDemoPack/Mods/modCMFDemoPack/content/texture.cache').write_bytes(b'changed')
        with self.assertRaisesRegex(preview.SpecError, 'accepted'):
            self.build()
        (self.src/'modCMFDemoPack/Mods/modCMFDemoPack/content/texture.cache').unlink()
        with self.assertRaisesRegex(preview.SpecError, 'missing'):
            self.build()
        self.assertFalse((self.root/'out').exists())

    def test_build_refuses_crlf_readme(self):
        (self.repo/'modCMFDemo/README.txt').write_bytes(b'readme\r\n')
        with self.assertRaisesRegex(preview.SpecError, 'CR line endings'):
            self.build()

    def test_verify_catches_tampering_and_extra_files(self):
        self.build()
        out = self.root/'out/1.0.0-preview-3'
        (out/'extra.txt').write_bytes(b'x')
        self.assertTrue(any('extra.txt' in p for p in preview.verify(out)))
        (out/'extra.txt').unlink()
        data = bytearray((out/'modCMFDemoPack-1.0.0-preview-3.zip').read_bytes())
        data[40] ^= 1
        (out/'modCMFDemoPack-1.0.0-preview-3.zip').write_bytes(bytes(data))
        self.assertTrue(any('differs from SHA256SUMS' in p for p in preview.verify(out)))

    def test_verify_catches_a_rewritten_zip_with_matching_sums(self):
        self.build()
        out = self.root/'out/1.0.0-preview-3'
        name = 'modCMFDemoPack-1.0.0-preview-3.zip'
        data = preview.make_zip({'README.txt': b'x\n', 'Mods/modCMFDemoPack/content/texture.cache': b'other'})
        (out/name).write_bytes(data)
        sums = (out/'SHA256SUMS').read_text(encoding='ascii').splitlines()
        sums = ['%s  %s' % (sha(data), name) if line.endswith(name) else line for line in sums]
        (out/'SHA256SUMS').write_text('\n'.join(sums) + '\n', encoding='ascii')
        problems = '\n'.join(preview.verify(out))
        self.assertIn('manifest SHA-256 differs', problems)
        self.assertIn('texture.cache SHA-256 differs from the manifest', problems)


class CommittedPreviewTests(unittest.TestCase):
    @unittest.skipUnless(BUILT.is_dir() and BUILT2.is_dir(), 'committed previews live in the private development repository')
    def test_committed_preview_verifies_and_matches_spec(self):
        self.assertEqual(preview.verify(BUILT), [])
        manifest = json.loads((BUILT/'manifest.json').read_text(encoding='ascii'))
        self.assertEqual(manifest['label'], preview.label_of(spec()))
        for package, listed in zip(manifest['packages'], spec()['packages']):
            shipped = {f['path']: f['sha256'] for f in package['files'] if f['path'] != 'README.txt'}
            self.assertEqual(shipped, {p: s['sha256'] for p, s in listed['files'].items()})
            readme = [f['sha256'] for f in package['files'] if f['path'] == 'README.txt']
            self.assertEqual(readme, [sha((ROOT/listed['readme']).read_bytes())])

    @unittest.skipUnless((PROBES/'2026-10-19-cmf-stage0').is_dir(), 'staged probe copies not available')
    @unittest.skipUnless(BUILT.is_dir() and BUILT2.is_dir(), 'committed previews live in the private development repository')
    def test_rebuild_from_staged_copies_is_byte_identical(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)/'1.0.0-preview-1'
            preview.build(preview.load_spec(SPEC), PROBES, out)
            for name in (BUILT/'SHA256SUMS').read_text(encoding='ascii').split()[1::2]:
                self.assertEqual((out/name).read_bytes(), (BUILT/name).read_bytes(), name)

    @unittest.skipUnless((PROBES/'2026-10-20-cmf-preview-2').is_dir(), 'staged probe copies not available')
    @unittest.skipUnless(BUILT.is_dir() and BUILT2.is_dir(), 'committed previews live in the private development repository')
    def test_preview2_rebuild_from_staged_copies_is_byte_identical(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)/'1.0.0-preview-2'
            preview.build(preview.load_spec(SPEC2), PROBES, out)
            for name in (BUILT2/'SHA256SUMS').read_text(encoding='ascii').split()[1::2]:
                self.assertEqual((out/name).read_bytes(), (BUILT2/name).read_bytes(), name)


if __name__ == '__main__':
    unittest.main()
