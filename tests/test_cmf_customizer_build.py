"""Customizer add-on build tool: layout, hashes and the source check (a stub stands in for w3strings.py)."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_customizer_addon as addon

STUB = '''import json, sys
from pathlib import Path
catalog = Path(sys.argv[2])
out = Path(sys.argv[sys.argv.index("--out") + 1])
out.mkdir(parents=True, exist_ok=True)
data = json.loads(catalog.read_text(encoding="utf-8"))
for lang in "ar br cn cz de en es esmx fr hu it jp kr pl ru tr ua zh".split():
    (out / (lang + ".w3strings")).write_bytes(("stub " + data["mod"] + lang).encode())
'''


class BuildTests(unittest.TestCase):
    def build(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        stub = Path(tmp.name)/'stub_w3strings.py'
        stub.write_text(STUB, encoding='utf-8')
        out = Path(tmp.name)/'out'
        files = addon.build(out, str(stub))
        return out, files

    def test_sources_are_current(self):
        self.assertTrue(addon.up_to_date())

    def test_layout_and_hashes(self):
        out, files = self.build()
        mod = 'Mods/modCMFCustomizer'
        self.assertIn(mod + '/content/scripts/local/modcmfcustomizer.ws', files)
        self.assertIn(mod + '/README.txt', files)
        self.assertIn('bin/config/r4game/user_config_matrix/pc/modCMFCustomizer.xml', files)
        for lang in addon.LANGUAGES:
            self.assertIn('%s/content/%s.w3strings' % (mod, lang), files)
        record = json.loads((out/'build.json').read_text(encoding='utf-8'))
        self.assertEqual((record['mod'], record['version'], record['minCmfApi']), ('modCMFCustomizer', '1.0.0', 19))
        self.assertEqual(record['files'], files)
        for name, digest in files.items():
            self.assertEqual(addon.sha((out/name).read_bytes()), digest)

    def test_refuses_a_used_folder(self):
        out, _files = self.build()
        with self.assertRaises(SystemExit):
            addon.build(out, None)

    def test_readme_credit_and_api(self):
        text = addon.README.read_text(encoding='utf-8')
        self.assertIn('Made by Kyle with the help of AI tools (Claude and ChatGPT)', text)
        self.assertIn('API 19', text)
        self.assertIn('Off', text)

    def test_no_model_names(self):
        for path in (addon.README, addon.SCRIPT, addon.MENU, addon.CATALOG):
            text = path.read_text(encoding='utf-8').lower()
            for word in ('opus', 'sonnet', 'haiku', 'gpt-'):
                self.assertNotIn(word, text, path.name)


if __name__ == '__main__':
    unittest.main()
