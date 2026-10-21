"""Release promotion: a passing candidate copied byte for byte into dist/<version>, and its verify.

Every case builds a tiny synthetic candidate with the preview build path in a temporary folder;
nothing is written under the repository's dist/.
"""
import contextlib
import copy
import hashlib
import io
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_preview as preview

TEMPLATES = ROOT/'source/releases/templates'
COMMIT = '0123456789abcdef0123456789abcdef01234567'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def candidate_spec(tmp, extra=None, readme=b'%s 1.0.0 readme\n'):
    """A preview spec over a core and an adapter package, with sources in tmp/src and READMEs in tmp/repo."""
    src, repo = tmp/'src', tmp/'repo'
    files = {
        'mod0000_CMFDemo': {'Mods/mod0000_CMFDemo/content/scripts/local/demo.ws': b'function CMFDemo() {}\n',
                            'Mods/mod0000_CMFDemo/content/blob0.bundle': bytes(range(256)) * 4,
                            'bin/config/r4game/user_config_matrix/pc/mod0000_CMFDemo.xml': b'<UserConfig/>\n'},
        'modCMFAdapterDemo': {'Mods/modCMFAdapterDemo/content/scripts/local/adapter.ws': b'function CMFA() {}\n'},
    }
    for path, data in (extra or {}).items():
        files['modCMFAdapterDemo'][path] = data
    packages = []
    for name, entries in files.items():
        listed = {}
        for path, data in entries.items():
            (src/name/path).parent.mkdir(parents=True, exist_ok=True)
            (src/name/path).write_bytes(data)
            listed[path] = {'from': '%s/%s' % (name, path), 'sha256': sha(data)}
        (repo/name).mkdir(parents=True, exist_ok=True)
        (repo/name/'README.txt').write_bytes(readme % name.encode())
        packages.append({'name': name, 'role': 'demo', 'readme': '%s/README.txt' % name,
                         'acceptance': 'synthetic', 'files': listed})
    (repo/'NOTES.md').write_bytes(b'# release candidate notes\n')
    return {'schema': preview.SCHEMA, 'version': '1.0.0', 'preview': 3, 'gameBuild': '5.0.1048522',
            'notes': 'NOTES.md', 'packages': packages}, src, repo


def release_spec(candidate_folder):
    return {
        'schema': preview.RELEASE_SPEC_SCHEMA, 'version': '1.0.0', 'candidate': candidate_folder.name,
        'candidateManifestSha256': sha((candidate_folder/'manifest.json').read_bytes()),
        'apiVersion': 6, 'sourceCommit': COMMIT,
        'notes': {'README.md': 'rel/README.md', 'rollback-notes.md': 'rel/rollback-notes.md',
                  'test-notes.md': 'rel/test-notes.md'},
        'matrix': [{'set': 'M1', 'record': 'probes/x-m1/README.md', 'result': 'PASS', 'launched': '2026-10-21T10:00Z'},
                   {'set': 'M5b', 'record': 'probes/x-m5b/README.md', 'result': 'PASS', 'launched': '2026-10-21T12:00Z'}],
        'notChecked': ['Proton/Linux', 'controller'],
        'packages': {
            'mod0000_CMFDemo': {'role': 'core', 'needsApi': 6, 'acceptance': 'M1, M5b'},
            'modCMFAdapterDemo': {'role': 'adapter', 'needsApi': 5, 'acceptance': 'M1',
                                  'adapts': {'folder': 'modDemo', 'name': 'Demo', 'nexus': 1, 'version': '1.2.3'}},
        },
    }


class PromoteCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def make_candidate(self, **kwargs):
        spec, src, repo = candidate_spec(self.root, **kwargs)
        self.repo = repo
        self.candidate = self.root/'previews/1.0.0-preview-3'
        preview.build(spec, src, self.candidate, repo)
        for name in preview.RELEASE_NOTES:
            (repo/'rel').mkdir(exist_ok=True)
            (repo/'rel'/name).write_bytes(b'# %s for 1.0.0\n' % name.encode())
        self.spec = release_spec(self.candidate)
        self.out = self.root/'dist/1.0.0'

    def promote(self):
        return preview.promote(self.candidate, self.spec, self.out, self.repo)

    def refused(self, pattern):
        with self.assertRaisesRegex(preview.SpecError, pattern):
            self.promote()
        self.assertFalse(self.out.exists())

    def rewrite_candidate_zip(self, mod, entries):
        """Replace one candidate ZIP and update its manifest and SHA256SUMS so the candidate stays consistent."""
        manifest = json.loads((self.candidate/'manifest.json').read_text(encoding='ascii'))
        package = [p for p in manifest['packages'] if p['mod'] == mod][0]
        data = preview.make_zip(entries)
        (self.candidate/package['zip']).write_bytes(data)
        package.update(sha256=sha(data), size=len(data),
                       files=[{'path': p, 'sha256': sha(entries[p]), 'size': len(entries[p]), 'source': 'x'}
                              for p in sorted(entries)])
        (self.candidate/'manifest.json').write_bytes((json.dumps(manifest, indent=1) + '\n').encode('ascii'))
        names = sorted(n.name for n in self.candidate.iterdir() if n.name not in ('SHA256SUMS', 'manifest.json'))
        sums = ''.join('%s  %s\n' % (sha((self.candidate/n).read_bytes()), n) for n in names)
        (self.candidate/'SHA256SUMS').write_bytes(sums.encode('ascii'))
        self.spec['candidateManifestSha256'] = sha((self.candidate/'manifest.json').read_bytes())


class PromoteTests(PromoteCase):
    def setUp(self):
        super().setUp()
        self.make_candidate()

    def test_promote_copies_candidate_bytes_and_verifies(self):
        manifest = self.promote()
        self.assertEqual(sorted(p.name for p in self.out.iterdir()),
                         ['README.md', 'SHA256SUMS', 'manifest.json', 'mod0000_CMFDemo-1.0.0.zip',
                          'modCMFAdapterDemo-1.0.0.zip', 'rollback-notes.md', 'test-notes.md'])
        for mod in ('mod0000_CMFDemo', 'modCMFAdapterDemo'):
            self.assertEqual((self.out/('%s-1.0.0.zip' % mod)).read_bytes(),
                             (self.candidate/('%s-1.0.0-preview-3.zip' % mod)).read_bytes(), mod)
        self.assertEqual(preview.verify(self.out), [])
        self.assertEqual(manifest['schema'], 'cmf-release-manifest-1')
        self.assertEqual((manifest['label'], manifest['version'], manifest['apiVersion']), ('1.0.0', '1.0.0', 6))
        self.assertEqual(manifest['promotedFrom'], {'label': '1.0.0-preview-3',
                                                    'manifestSha256': self.spec['candidateManifestSha256']})
        self.assertEqual(manifest['zip'], preview.ZIP_FORMAT)
        core, adapter = manifest['packages']
        self.assertEqual((core['role'], core['version'], core['needsApi']), ('core', '1.0.0', 6))
        self.assertNotIn('adapts', core)
        self.assertEqual(adapter['adapts']['version'], '1.2.3')
        for package in manifest['packages']:
            self.assertEqual(package['sha256'], package['candidateZipSha256'])
        candidate = json.loads((self.candidate/'manifest.json').read_text(encoding='ascii'))
        self.assertEqual([p['files'] for p in manifest['packages']], [p['files'] for p in candidate['packages']])
        self.assertEqual(manifest, json.loads((self.out/'manifest.json').read_text(encoding='ascii')))

    def test_a_new_package_can_keep_its_own_version(self):
        # A first adapter shipped in a later CMF release (the Coloured Map Markers adapter 1.0.0 in CMF 1.1.0).
        self.spec['packages']['modCMFAdapterDemo']['version'] = '0.9.0'
        manifest = self.promote()
        self.assertTrue((self.out/'modCMFAdapterDemo-0.9.0.zip').is_file())
        self.assertFalse((self.out/'modCMFAdapterDemo-1.0.0.zip').exists())
        self.assertEqual([(p['zip'], p['version']) for p in manifest['packages']],
                         [('mod0000_CMFDemo-1.0.0.zip', '1.0.0'), ('modCMFAdapterDemo-0.9.0.zip', '0.9.0')])
        self.assertEqual(preview.verify(self.out), [])

    def test_refuses_a_package_version_that_is_not_x_y_z(self):
        self.spec['packages']['modCMFAdapterDemo']['version'] = '1.0'
        self.refused('version must be X.Y.Z')

    def test_sha256sums_covers_everything_in_sha256sum_format(self):
        self.promote()
        lines = (self.out/'SHA256SUMS').read_bytes().decode('ascii')
        self.assertTrue(lines.endswith('\n'))
        self.assertNotIn('\r', lines)
        names = [line.split('  ', 1)[1] for line in lines.splitlines()]
        self.assertEqual(names, sorted(names))
        self.assertEqual(set(names), {p.name for p in self.out.iterdir()} - {'SHA256SUMS'})
        for line in lines.splitlines():
            digest, name = line.split('  ', 1)
            self.assertEqual(digest, sha((self.out/name).read_bytes()), name)

    def test_cli_promotes_and_reports_pass(self):
        spec_path = self.repo/'release.json'
        self.spec['notes'] = {k: str(self.repo/v) for k, v in self.spec['notes'].items()}
        spec_path.write_text(json.dumps(self.spec), encoding='utf-8')
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = preview.main(['promote', '--candidate', str(self.candidate), '--version', '1.0.0',
                                 '--spec', str(spec_path), '--out', str(self.out)])
        self.assertEqual(code, 0)
        self.assertIn('verify: PASS', output.getvalue())
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(preview.main(['verify', str(self.out)]), 0)

    def test_cli_refuses_a_version_other_than_the_spec(self):
        spec_path = self.repo/'release.json'
        spec_path.write_text(json.dumps(self.spec), encoding='utf-8')
        with contextlib.redirect_stderr(io.StringIO()) as errors:
            code = preview.main(['promote', '--candidate', str(self.candidate), '--version', '1.0.1',
                                 '--spec', str(spec_path), '--out', str(self.root/'dist/1.0.1')])
        self.assertEqual(code, 1)
        self.assertIn('not for version 1.0.1', errors.getvalue())

    def test_refuses_existing_destination(self):
        self.promote()
        with self.assertRaisesRegex(preview.SpecError, 'never overwritten'):
            self.promote()
        self.out = self.root/'other/1.0.0'
        self.out.mkdir(parents=True)
        with self.assertRaisesRegex(preview.SpecError, 'never overwritten'):
            self.promote()
        self.assertEqual(list(self.out.iterdir()), [])

    def test_refuses_wrong_output_name(self):
        self.out = self.root/'dist/1.0.0-final'
        self.refused('must be named 1.0.0')

    def test_refuses_candidate_whose_verify_fails(self):
        name = self.candidate/'modCMFAdapterDemo-1.0.0-preview-3.zip'
        data = bytearray(name.read_bytes())
        data[40] ^= 1
        name.write_bytes(bytes(data))
        self.refused('fails its own verify')

    def test_refuses_a_candidate_other_than_the_tested_one(self):
        self.spec['candidateManifestSha256'] = '0' * 64
        self.refused('not the 0+ the spec records')
        self.spec = release_spec(self.candidate)
        self.spec['candidate'] = '1.0.0-preview-4'
        self.refused('not 1.0.0-preview-4')

    def test_refuses_matrix_that_did_not_pass(self):
        self.spec['matrix'][1]['result'] = 'FAIL'
        self.refused('M5b is FAIL')
        self.spec['matrix'] = []
        self.refused('matrix is empty')

    def test_refuses_package_lists_that_differ(self):
        del self.spec['packages']['modCMFAdapterDemo']
        self.refused('modCMFAdapterDemo: in the candidate but not in the release spec')
        self.spec = release_spec(self.candidate)
        self.spec['packages']['modCMFOther'] = {'role': 'addon', 'needsApi': 1, 'acceptance': 'x'}
        self.refused('modCMFOther: in the release spec but not in the candidate')

    def test_refuses_bad_spec_fields(self):
        broken = copy.deepcopy(self.spec)
        broken['sourceCommit'] = 'abc123'
        broken['packages']['modCMFAdapterDemo']['needsApi'] = 7
        del broken['packages']['modCMFAdapterDemo']['adapts']
        broken['packages']['mod0000_CMFDemo']['role'] = 'library'
        broken['extra'] = 1
        problems = '\n'.join(preview.check_release_spec(broken))
        for text in ('full 40-digit', 'needsApi must be', 'adapts is required', 'role must be one of',
                     "unknown key 'extra'"):
            self.assertIn(text, problems)

    def test_refuses_notes_with_placeholders_or_missing(self):
        (self.repo/'rel/test-notes.md').write_bytes(b'Passed on <<FILL: date>>\n')
        self.refused('test-notes.md: still has template placeholders')
        (self.repo/'rel/test-notes.md').unlink()
        self.refused('test-notes.md')


class DeveloperContentTests(PromoteCase):
    def test_refuses_test_script_by_file_name(self):
        self.make_candidate(extra={'Mods/modCMFAdapterDemo/content/scripts/local/cmfTestIcons.ws': b'x\n'})
        self.assertEqual(preview.verify(self.candidate), [])
        self.refused('cmfTestIcons.ws: developer-only content')

    def test_refuses_tools_folder(self):
        self.make_candidate(extra={'Mods/modCMFAdapterDemo/tools/helper.txt': b'x\n'})
        self.refused('tools/helper.txt: developer-only content')

    def test_refuses_app_id_hint(self):
        self.make_candidate()
        entries = {'README.txt': b'adapter 1.0.0\n',
                   'Mods/modCMFAdapterDemo/content/scripts/local/adapter.ws': b'function CMFA() {}\n',
                   'Mods/modCMFAdapterDemo/steam_appid.txt': b'292030\n'}
        self.rewrite_candidate_zip('modCMFAdapterDemo', entries)
        self.refused('steam_appid.txt')

    def test_refuses_player_readme_that_still_says_preview(self):
        self.make_candidate(readme=b'%s preview build 1.0.0-preview-3\n')
        self.refused('README.txt still says "preview"')

    def test_dev_word_rules(self):
        ok = ['Mods/modX/content/scripts/local/cmfTooltip.ws', 'Mods/modX/content/latest.ws',
              'Mods/modX/content/blob0.bundle', 'Mods/modX/content/en.w3strings',
              'Mods/modX/content/scripts/local/cmfMapPidLayer.ws', 'Mods/modX/content/scripts/local/happiness.ws']
        bad = ['Mods/modX/content/scripts/local/test_icons.ws', 'Mods/modX/content/scripts/local/cmfProbe.ws',
               'Mods/modX/Tools/a.ws', 'Mods/modX/content/AppID.txt', 'Mods/modX/content/steam_appid.txt', 'Mods/modX/app_id.txt',
               'Mods/modZZCMFTestPack/content/a.ws']
        for path in ok:
            self.assertEqual(preview.dev_content_problems(path), [], path)
        for path in bad:
            self.assertTrue(preview.dev_content_problems(path), path)


class VerifyReleaseTests(PromoteCase):
    def setUp(self):
        super().setUp()
        self.make_candidate()
        self.promote()

    def problems(self):
        return '\n'.join(preview.verify(self.out))

    def test_catches_tampered_zip_and_extra_file(self):
        (self.out/'notes.txt').write_bytes(b'x')
        self.assertIn('notes.txt: not in SHA256SUMS', self.problems())
        (self.out/'notes.txt').unlink()
        (self.out/'sub').mkdir()
        self.assertIn('sub: unexpected folder', self.problems())
        (self.out/'sub').rmdir()
        name = self.out/'modCMFAdapterDemo-1.0.0.zip'
        data = bytearray(name.read_bytes())
        data[40] ^= 1
        name.write_bytes(bytes(data))
        self.assertIn('modCMFAdapterDemo-1.0.0.zip: SHA-256 differs from SHA256SUMS', self.problems())

    def test_catches_missing_file(self):
        (self.out/'rollback-notes.md').unlink()
        self.assertIn('rollback-notes.md: listed but missing', self.problems())

    def test_catches_edited_manifest(self):
        manifest = json.loads((self.out/'manifest.json').read_text(encoding='ascii'))
        manifest['matrix'][0]['result'] = 'FAIL'
        (self.out/'manifest.json').write_bytes((json.dumps(manifest, indent=1) + '\n').encode('ascii'))
        problems = self.problems()
        self.assertIn('manifest.json: SHA-256 differs from SHA256SUMS', problems)
        self.assertIn('all PASS', problems)

    def test_catches_rebuilt_zip_even_with_matching_sums(self):
        name = 'modCMFAdapterDemo-1.0.0.zip'
        entries = {'README.txt': b'adapter 1.0.0\n',
                   'Mods/modCMFAdapterDemo/content/scripts/local/adapter.ws': b'function CMFB() {}\n'}
        data = preview.make_zip(entries)
        (self.out/name).write_bytes(data)
        manifest = json.loads((self.out/'manifest.json').read_text(encoding='ascii'))
        manifest['packages'][1]['sha256'] = sha(data)
        (self.out/'manifest.json').write_bytes((json.dumps(manifest, indent=1) + '\n').encode('ascii'))
        names = sorted(p.name for p in self.out.iterdir() if p.name != 'SHA256SUMS')
        (self.out/'SHA256SUMS').write_bytes(''.join('%s  %s\n' % (sha((self.out/n).read_bytes()), n)
                                                    for n in names).encode('ascii'))
        problems = self.problems()
        self.assertIn("differs from the candidate's ZIP", problems)
        self.assertIn('adapter.ws SHA-256 differs from the manifest', problems)

    def test_catches_wrong_folder_name(self):
        moved = self.root/'dist/1.0.1'
        self.out.rename(moved)
        self.out = moved
        self.assertIn('folder name 1.0.1 does not match version 1.0.0', self.problems())

    def test_preview_verify_unchanged(self):
        self.assertEqual(preview.verify(self.candidate), [])


class TemplateTests(unittest.TestCase):
    def test_templates_are_plain_and_unfilled(self):
        for name in preview.RELEASE_NOTES:
            data = preview.read_text_file(TEMPLATES/name)
            self.assertIn(b'<<FILL', data, name)
            with self.assertRaisesRegex(preview.SpecError, 'template placeholders'):
                preview.read_notes(TEMPLATES/name)

    def test_test_notes_template_claims_no_result(self):
        text = (TEMPLATES/'test-notes.md').read_text(encoding='ascii')
        fixed = re.sub(r'<!--.*?-->|<<FILL.*?>>(?!>)', '', text, flags=re.S)
        self.assertNotRegex(fixed, r'(?i)\bpass(ed)?\b')
        self.assertNotRegex(fixed, r'20\d\d-\d\d-\d\d')
        self.assertIn('## Not tested', text)
        self.assertIn('Proton', text)

    def test_release_spec_template_is_refused_until_filled(self):
        spec = json.loads((TEMPLATES/'release.json').read_text(encoding='ascii'))
        self.assertEqual(spec['schema'], preview.RELEASE_SPEC_SCHEMA)
        self.assertIn('template placeholders', '\n'.join(preview.check_release_spec(spec)))

    @unittest.skipUnless((ROOT/'previews/1.0.0-preview-2').is_dir(), 'committed previews live in the private development repository')

    def test_committed_preview_cannot_be_promoted_as_is(self):
        """Preview 2's player README.txt files say "preview", so it is not a release candidate."""
        candidate = ROOT/'previews/1.0.0-preview-2'
        manifest = json.loads((candidate/'manifest.json').read_text(encoding='ascii'))
        spec = release_spec(candidate)
        spec['packages'] = {p['mod']: {'role': 'core', 'needsApi': 1, 'acceptance': 'x'} for p in manifest['packages']}
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(preview.SpecError, 'still says "preview"'):
                preview.promote(candidate, spec, Path(tmp)/'1.0.0')
            self.assertFalse((Path(tmp)/'1.0.0').exists())


if __name__ == '__main__':
    unittest.main()
