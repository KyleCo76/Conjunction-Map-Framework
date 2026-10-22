"""UI Remastered Edition adapter: the "#UHL#" title split, and the pack build.

UI Remastered 1.00's uire_worldmap.ws (SHA-256 2e2a3ea0...46be1, pin-size-and-labels design section 6) writes a
quest pin's label as the game's label + "#UHL#" + a coloured level line (204-205); only its own TooltipMap
splits at the marker. These are static checks, with a small model of the split; nothing here compiled or ran
in game.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

ADAPTER = ROOT/'source/adapters/ui-remastered/modCMFAdapterUIRemasteredEdition'
SCRIPTS = ADAPTER/'content/scripts/local'
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
PROVIDER = 'mod0000_UIRemasteredEdition'


def script():
    files = sorted(SCRIPTS.glob('*.ws'))
    assert len(files) == 1, files
    return files[0]


def code():
    return cmf_pack.strip_comments(script().read_text())


def split(label, description):
    """The adapter's OnPinReady body, restated: StrSplitFirst at the marker, level line under the description."""
    if '#UHL#' not in label:
        return label, description
    title, level = label.split('#UHL#', 1)
    if description != '' and level != '':
        description += '<br>'
    return title, description + level


class UIRemasteredAdapterTests(unittest.TestCase):
    def test_pack_checks_clean(self):
        report, plan = cmf_pack.check_pack(ADAPTER, adapts=PROVIDER)
        self.assertEqual((report.errors, report.warnings), ([], []))
        # It registers nothing: no claims, no art.
        self.assertEqual(plan['claims'], [])
        self.assertEqual(plan['images'], {})

    def test_plain_ascii_lf_tabs(self):
        text = script().read_bytes().decode('ascii')
        self.assertNotIn('\r', text)
        for line in text.splitlines():
            self.assertFalse(line.startswith(' '), 'indent with tabs: %r' % line)

    def test_wraps_on_pin_ready_with_cores_signature(self):
        core = CORE.read_text()
        self.assertIn('public function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)', core)
        self.assertIn('public function OnMapReady(menuFlash : CScriptedFlashSprite)', core)
        text = code()
        self.assertIn('@wrapMethod(CMFCore)\nfunction OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)',
                      text)
        self.assertIn('@wrapMethod(CMFCore)\nfunction OnMapReady(menuFlash : CScriptedFlashSprite)', text)
        self.assertEqual(text.count('wrappedMethod('), 2)

    def test_splits_at_the_marker_with_the_native_call(self):
        text = code()
        self.assertIn('StrSplitFirst(label, "#UHL#", title, level)', text)
        self.assertIn('SetMemberFlashString("label", title)', text)
        self.assertIn('SetMemberFlashString("description", description + level)', text)

    def test_calls_nothing_of_ui_remastered_and_no_claims(self):
        text = code()
        self.assertNotRegex(text, r'\bUire\w*\(')
        self.assertNotRegex(text, r'\bCMF(Register|Style)\w*\(')

    def test_avoids_reserved_words(self):
        for word in ('entry', 'single', 'state', 'quest', 'reward', 'timer', 'hint', 'saved', 'exec', 'latent'):
            self.assertNotRegex(code(), r'\bvar %s\b' % word)

    def test_split_model(self):
        level = '<font color="#ff0000">Required level 32</font>'
        self.assertEqual(split('Wild at Heart#UHL#' + level, 'Find the bear'),
                         ('Wild at Heart', 'Find the bear<br>' + level))
        self.assertEqual(split('Wild at Heart#UHL#' + level, ''), ('Wild at Heart', level))
        self.assertEqual(split('Wild at Heart', 'Find the bear'), ('Wild at Heart', 'Find the bear'))
        self.assertEqual(split('A#UHL#', 'B'), ('A', 'B'))

    def test_log_line_names_the_provider(self):
        self.assertRegex(code(), r'"CMF adapter provider=%s levelTitlesSplit=" \+ uireAdapterSplit' % PROVIDER)

    def test_readme_says_install_only_with_ui_remastered(self):
        readme = (ADAPTER/'README.txt').read_text()
        self.assertIn('ONLY together with UI Remastered Edition', readme)
        # CMF 1.0.0 is API 6, above the API 4 that OnPinReady and OnMapReady need.
        self.assertIn('Conjunction Map Framework 1.0.0 or later', readme)
        self.assertIn('Version 1.0.0', readme)


if __name__ == '__main__':
    unittest.main()
