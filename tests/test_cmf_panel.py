"""Boundary and independent-reader tests; real panel tests require ignored pins."""
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import cmf_panel as panel


def movie(tail=b'opaque'):
    body = b'\x08\x00\x00\x18\x01\x00' + b'\x00\x00'
    return b'CFX\x0c' + struct.pack('<I', 8 + len(body)) + zlib.compress(body + tail)


def small_abc(*, name=b'', flags=1, count=b'\x02', first_stack=b'\x01',
              first_length=b'\x01', selected_stack=b'\x01', selected_exceptions=b'\x00',
              selected_traits=b'\x00', selected_length=b'\x01', selected_code=b'\x47'):
    """Two empty owned methods; knobs change actual integer encodings only."""
    data = struct.pack('<HH', 16, 46) + b'\x00' * 7
    data += b'\x02' + b'\x00' * 8  # two zero-parameter method signatures
    data += b'\x00\x00\x00' + count  # metadata, classes, scripts, bodies
    data += b'\x00' + first_stack + b'\x01\x00\x00' + first_length + b'\x47\x00\x00'
    data += b'\x01' + selected_stack + b'\x01\x00\x00' + selected_length + selected_code
    data += selected_exceptions + selected_traits
    return struct.pack('<I', flags) + name + b'\x00' + data


class AbcPreservationTests(unittest.TestCase):
    def test_owned_fixture_valid_and_permitted_code_change(self):
        before = panel.read_abc(small_abc())
        panel.validate_abc_edit(before, panel.read_abc(small_abc()), 1, b'\x47')
        changed = panel.read_abc(small_abc(selected_length=b'\x04', selected_code=b'\x24\x00\x29\x47'))
        panel.validate_abc_edit(before, changed, 1, b'\x24\x00\x29\x47')

    def test_envelope_flags_and_raw_name_changes_rejected(self):
        before = panel.read_abc(small_abc())
        for mutation in ({'flags': 0}, {'name': b'\xffopaque'}):
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                panel.validate_abc_edit(before, panel.read_abc(small_abc(**mutation)), 1, b'\x47')

    def test_unchanged_body_encoding_change_rejected(self):
        before = panel.read_abc(small_abc())
        for mutation in ({'first_stack': b'\x81\x00'}, {'first_length': b'\x81\x00'}):
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                panel.validate_abc_edit(before, panel.read_abc(small_abc(**mutation)), 1, b'\x47')

    def test_selected_header_suffix_and_count_encoding_changes_rejected(self):
        before = panel.read_abc(small_abc())
        mutations = ({'selected_stack': b'\x81\x00'}, {'selected_exceptions': b'\x80\x00'},
                     {'selected_traits': b'\x80\x00'}, {'count': b'\x82\x00'},
                     {'selected_length': b'\x81\x00'})
        for mutation in mutations:
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                panel.validate_abc_edit(before, panel.read_abc(small_abc(**mutation)), 1, b'\x47')


class PanelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (panel.ROOT / 'build/tests').mkdir(parents=True, exist_ok=True)

    @unittest.skipUnless(os.name == 'nt', 'Windows process ownership')
    def test_job_timeout_kills_owned_descendant(self):
        import time
        import uuid
        run = panel.ROOT / 'build/panel-runs' / ('test-job-' + uuid.uuid4().hex)
        marker = run / 'escaped-child.txt'
        child = 'import time,pathlib; time.sleep(2); pathlib.Path(' + repr(str(marker)) + ').write_text("escaped")'
        parent = 'import subprocess,sys,time; subprocess.Popen([sys.executable,"-c",' + repr(child) + ']); time.sleep(20)'
        result = panel.run_tool([sys.executable, '-B', '-c', parent], run, timeout=1)
        self.assertTrue(result['timedOut'])
        time.sleep(1.3)
        self.assertFalse(marker.exists(), 'descendant escaped job cleanup')

    def test_reject_bad_package_signature(self):
        with self.assertRaises(ValueError):
            panel.read_package(b'not a bundle', b'not metadata')

    def test_reject_empty_and_wrong_lookup(self):
        for records in ([], [(0, 1, 0)], [(0xEE5025C8ADA29263, 2, 0)],
                        [(0xEE5025C8ADA29263, 1, 1)]):
            with self.assertRaises(ValueError):
                panel.validate_lookup(records)

    def test_output_existing_and_outside_rejected(self):
        with tempfile.TemporaryDirectory(dir=panel.ROOT / 'build/tests') as tmp:
            root = Path(tmp)
            (root / 'exists').mkdir()
            for target in [root / 'exists', root.parent / 'escape', root]:
                with self.assertRaises(ValueError):
                    panel.new_output(root, target)

    def test_reparse_rejected_before_write(self):
        with tempfile.TemporaryDirectory(dir=panel.ROOT / 'build/tests') as tmp:
            from types import SimpleNamespace
            with patch.object(Path, 'lstat', return_value=SimpleNamespace(st_mode=0, st_file_attributes=0x400)):
                with self.assertRaises(ValueError):
                    panel.new_output(Path(tmp), Path(tmp) / 'new')
            self.assertFalse((Path(tmp) / 'new').exists())

    def test_wrong_hash_rejected(self):
        with tempfile.TemporaryDirectory(dir=panel.ROOT / 'build/tests') as tmp:
            p = Path(tmp) / 'input'
            p.write_bytes(b'bad')
            with self.assertRaises(ValueError):
                panel.pinned(p, '0' * 64)

    def test_package_wrong_pin_prevents_launch(self):
        with tempfile.TemporaryDirectory(dir=panel.ROOT / 'build/tests') as tmp:
            path = Path(tmp) / 'wrong.redswf'
            path.write_bytes(b'wrong')
            with patch('cmf_panel.run_tool') as launched:
                with self.assertRaises(ValueError):
                    panel.package_resource(path, '0' * 64, 'pin-guard', '0' * 64)
                launched.assert_not_called()

    def test_tail_preserved_and_tamper_rejected(self):
        before = panel.read_movie(movie())
        self.assertEqual(before['tail'], b'opaque')
        panel.compare_movies(before, panel.read_movie(movie()), abc_change=False)
        with self.assertRaises(ValueError):
            panel.compare_movies(before, panel.read_movie(movie(b'altered')), abc_change=True)

    def test_moved_abc_tag_rejected(self):
        import copy
        before = panel.read_movie(movie())
        before['tags'].insert(0, {'code': 82, 'payload': b'abc', 'size': 3, 'sha256': panel.sha(b'abc')})
        after = copy.deepcopy(before)
        after['tags'].reverse()
        with self.assertRaises(ValueError):
            panel.compare_movies(before, after, abc_change=True)

    def test_bad_movie_declared_range(self):
        bad = bytearray(movie())
        struct.pack_into('<I', bad, 4, 99999)
        with self.assertRaises(ValueError):
            panel.read_movie(bytes(bad))

    def test_boundary_wrapper_restores_only_known_tail(self):
        path = panel.ROOT / panel.PANEL_PATH
        if not path.exists():
            self.skipTest('ignored pinned input unavailable')
        original = panel.read_cr2w(panel.pinned(path, panel.PANEL_SHA))['movieBytes']
        decoded = zlib.decompress(original[8:])
        declared = struct.unpack_from('<I', original, 4)[0]
        stripped = original[:8] + zlib.compress(decoded[:declared - 8])
        restored = panel.restore_opaque_tail(original, stripped)
        panel.compare_movies(panel.read_movie(original), panel.read_movie(restored), False)
        with self.assertRaises(ValueError):
            panel.restore_opaque_tail(original, movie(b'unknown'))

    def test_no_claimed_success_without_artifacts(self):
        with self.assertRaises(ValueError):
            panel.require_artifacts({'returncode': 0, 'timedOut': False}, [])

    def test_lookup_hash_known_answer(self):
        self.assertEqual(panel.fnv64(panel.DEPOT.encode('ascii')), 0xEE5025C8ADA29263)


class PinnedPanelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = Path(__file__).resolve().parents[1] / panel.PANEL_PATH
        if not cls.path.exists():
            raise unittest.SkipTest('ignored pinned vanilla input unavailable')
        cls.data = panel.pinned(cls.path, panel.PANEL_SHA)

    def test_raw_pin_and_crcs(self):
        report = panel.read_cr2w(self.data)
        self.assertEqual(len(report['exports']), 6)
        self.assertEqual(report['movie']['tailSha256'], panel.TAIL_SHA)

    def test_abc_namespace_visibility(self):
        movie = panel.read_cr2w(self.data)['movie']
        abc = panel.read_abc(next(t['payload'] for t in movie['tags'] if t['code'] == 82))
        selected = next(c for c in abc['classes'] if c['name']['name'] == 'PinPointersManager')
        init = next(t for t in selected['traits'] if t['name']['name'] == 'init')
        self.assertEqual(init['name']['namespace']['kind'], 0x16)
        private = next(t for t in selected['traits'] if t['name']['name'] == 'createPointer')
        self.assertEqual(private['name']['namespace']['kind'], 0x05)

    def test_crc_corruption_rejected(self):
        bad = bytearray(self.data)
        bad[-1] ^= 1
        with self.assertRaises(ValueError):
            panel.read_cr2w(bytes(bad))

    def test_unsupported_topology_rejected(self):
        bad = bytearray(self.data)
        struct.pack_into('<I', bad, 40 + 2 * 12 + 4, 1)
        with self.assertRaises(ValueError):
            panel.read_cr2w(bytes(bad))

    def test_texture_change_rejected(self):
        original = panel.read_cr2w(self.data)
        import copy
        changed = copy.deepcopy(original)
        changed['exports'][1]['bufferSha256'] = '0' * 64
        with self.assertRaises(ValueError):
            panel.compare_cr2w(original, changed, original['movieBytes'])


class ActualPackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = panel.ROOT / 'build/panel-runs'
        cls.noop = root / '10-noop-package-output'
        cls.grow = root / '11-grow-package-output'
        if not (cls.noop / 'blob0.bundle').exists() or not (cls.grow / 'metadata.store').exists():
            raise unittest.SkipTest('ignored actual package specimens unavailable')

    def test_actual_noop_and_changed_size_layouts(self):
        for path in (self.noop, self.grow):
            self.assertEqual(panel.read_package((path / 'blob0.bundle').read_bytes(),
                                               (path / 'metadata.store').read_bytes())['layout'], 'PASS')

    def test_stale_pair_rejected(self):
        with self.assertRaises(ValueError):
            panel.read_package((self.noop / 'blob0.bundle').read_bytes(),
                               (self.grow / 'metadata.store').read_bytes())

    def test_physical_eof_and_padding_rejected(self):
        bundle = (self.noop / 'blob0.bundle').read_bytes()
        metadata = (self.noop / 'metadata.store').read_bytes()
        for changed in (bundle + b'\0', bundle[:400] + b'\1' + bundle[401:]):
            with self.assertRaises(ValueError):
                panel.read_package(changed, metadata)

    def test_actual_lookup_tamper_rejected(self):
        bundle = (self.noop / 'blob0.bundle').read_bytes()
        metadata = bytearray((self.noop / 'metadata.store').read_bytes())
        metadata[-16] ^= 1
        with self.assertRaises(ValueError):
            panel.read_package(bundle, bytes(metadata))


class AssemblerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = panel.ROOT / 'build/panel-runs'
        if not (cls.root / '18-pcode-changed/tail-preserved.gfx').exists():
            raise unittest.SkipTest('ignored assembler specimen unavailable')
        def read(path):
            m = panel.read_movie(path.read_bytes())
            return panel.read_abc(next(t['payload'] for t in m['tags'] if t['code'] == 82))
        cls.original = read(cls.root / '02-noop-output/movie.gfx')
        cls.changed = read(cls.root / '18-pcode-changed/tail-preserved.gfx')

    def test_real_movie_doabc_flags_and_raw_name_changes_rejected(self):
        original = panel.read_movie((self.root / '02-noop-output/movie.gfx').read_bytes())
        candidate = (self.root / '18-pcode-changed/tail-preserved.gfx').read_bytes()
        decoded = zlib.decompress(candidate[8:])
        position = len(original['framing'])
        while True:
            start = position
            header = struct.unpack_from('<H', decoded, position)[0]
            position += 2
            code, size = header >> 6, header & 63
            if size == 63:
                size = struct.unpack_from('<I', decoded, position)[0]
                position += 4
            payload = decoded[position:position + size]
            position += size
            if code == 82:
                break
        mutated = (bytes([payload[0] ^ 1]) + payload[1:], payload[:4] + b'\xff' + payload[4:])
        for replacement in mutated:
            tag = struct.pack('<HI', (82 << 6) | 63, len(replacement)) + replacement
            body = decoded[:start] + tag + decoded[position:]
            length = struct.unpack_from('<I', candidate, 4)[0] + len(body) - len(decoded)
            raw_movie = candidate[:4] + struct.pack('<I', length) + zlib.compress(body)
            parsed = panel.read_movie(raw_movie)
            with self.subTest(envelope=replacement[:6].hex()):
                with self.assertRaisesRegex(ValueError, 'DoABC flags/raw name'):
                    panel.compare_movies(original, parsed, True)
                with self.assertRaisesRegex(ValueError, 'DoABC flags/raw name'):
                    panel.validate_abc_edit(self.original, panel.read_abc(replacement), 4622,
                                            b'\x24\x00\x29' + self.original['bodyRecords'][4622]['code'])

    def test_one_method_only(self):
        panel.validate_abc_edit(self.original, self.changed, 4622,
                                b'\x24\x00\x29' + self.original['bodyRecords'][4622]['code'])

    def test_unrelated_method_or_namespace_rejected(self):
        import copy
        for field in ('other-body', 'prefix'):
            changed = copy.deepcopy(self.changed)
            if field == 'prefix': changed['prefixSha256'] = '0' * 64
            else: changed['bodyRecords'][1]['code'] = b'\x47'
            with self.assertRaises(ValueError):
                panel.validate_abc_edit(self.original, changed, 4622,
                                        b'\x24\x00\x29' + self.original['bodyRecords'][4622]['code'])


if __name__ == '__main__':
    unittest.main()
