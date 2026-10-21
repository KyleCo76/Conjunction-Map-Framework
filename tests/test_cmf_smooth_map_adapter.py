"""Smooth Map adapter: the keys it sends, its provider, and the WitcherScript rules it keeps.

Smooth Map 1.1 has no script; its timing lives in its own map file, which CMF's replaces. The adapter sends
Smooth Map's column of the smooth map movement record (research 2026-10-20, section 5.2) as CMF's navigation and
opening keys under Smooth Map's folder name. These are static checks; nothing here compiled or ran in game.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

ADAPTER = ROOT/'source/adapters/smooth-map/modCMFAdapterSmoothMap'
SCRIPTS = ADAPTER/'content/scripts/local'
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
# Claims use the adapted mod's folder name, so folder order is the same with CMF as without it.
PROVIDER = 'modSmoothMap'
# Record section 5.2, Smooth Map's column: every key its map file decides, and no other.
SMOOTH_MAP = {
    ('navigation', 'frameTimed'): 1, ('navigation', 'stepMs'): 17, ('navigation', 'worldStepMs'): 24,
    ('navigation', 'maxStepMs'): 100, ('navigation', 'zoomTimed'): 1, ('navigation', 'padHoldMs'): 0,
    ('navigation', 'tweenEveryFrame'): 1, ('opening', 'pinsDuringSlide'): 1, ('opening', 'pinStepMs'): 1,
    ('opening', 'pinBatch'): 0, ('opening', 'pinBudgetMs'): 8, ('opening', 'showDelayMs'): 1,
    ('opening', 'fadeSeconds'): 0.2, ('opening', 'tileFadeSeconds'): 0.2, ('opening', 'revealSeconds'): 0.2,
}
# Keys Smooth Map leaves as the game's (the menu's slide and close, frame rate, zoom limit, controller crosshair).
NOT_SENT = ['slideSeconds', 'slideOffset', 'closeSeconds', 'frameRate', 'zoomOutFit', 'edgeOvershoot',
            'crosshairRoam', 'safeLeft', 'safeTop', 'safeRight', 'safeBottom', 'snapSeconds', 'centerSeconds']
# CMFThemeMotionValueOk in cmfCore.ws (record Appendix A.3).
RANGES = {
    'frameTimed': (0, 1), 'zoomTimed': (0, 1), 'tweenEveryFrame': (0, 1), 'pinsDuringSlide': (0, 1),
    'stepMs': (1, 1000), 'worldStepMs': (1, 1000), 'maxStepMs': (1, 1000), 'pinStepMs': (1, 1000),
    'padHoldMs': (0, 1000), 'pinBudgetMs': (0, 1000), 'showDelayMs': (0, 5000), 'pinBatch': (0, 100000),
    'fadeSeconds': (0, 5), 'tileFadeSeconds': (0, 5), 'revealSeconds': (0, 5),
}


def script():
    files = sorted(SCRIPTS.glob('*.ws'))
    assert len(files) == 1, files
    return files[0]


class SmoothMapAdapterTests(unittest.TestCase):
    def test_sends_smooth_maps_column_and_nothing_else(self):
        text = script().read_text(encoding='ascii')
        sent = {(p, k): float(n) for p, k, n in
                re.findall(r"SmoothMapAdapterKey\('(\w+)', '(\w+)', ([\d.]+)\);", text)}
        self.assertEqual(sent, SMOOTH_MAP)
        self.assertEqual(len(re.findall(r'SmoothMapAdapterKey\(', text)), len(SMOOTH_MAP) + 1)
        self.assertIn('keys=%d accepted=' % len(SMOOTH_MAP), text)
        for key in NOT_SENT:
            self.assertNotIn("'%s'" % key, text)

    def test_every_key_is_one_cmf_takes_in_range(self):
        core = CORE.read_text(encoding='ascii')
        self.assertIn('function CMFGetVersion() : int { return 7; }', core)
        for (part, key), number in SMOOTH_MAP.items():
            self.assertIn(key, cmf_pack.THEME_PART_KEYS[part])
            low, high = RANGES[key]
            self.assertTrue(low <= number <= high, key)
            if high == 1 and low == 0:
                self.assertIn(number, (0, 1), key)

    def test_one_claim_under_smooth_maps_folder_name_after_version_6(self):
        text = script().read_text(encoding='ascii')
        self.assertEqual(re.findall(r'CMFStylePart\("(\w+)"', text), [PROVIDER])
        self.assertIn('CMFStylePart("modSmoothMap", part, key, "", number)', text)
        self.assertIn('if (CMFRequireVersion("modSmoothMap", 6))', text)
        self.assertNotIn('"unset"', text)
        # Earlier folders win a shared key, as their own map files would without CMF.
        for earlier in ('mod000CommunityPatch_WorldMap', 'modInkAndIronUI', 'modMapQuestInsight'):
            self.assertLess(earlier.lower(), PROVIDER.lower())

    def test_registers_once_per_game_session_and_wraps_no_other_mod(self):
        text = script().read_text(encoding='ascii')
        self.assertEqual(re.findall(r'@wrapMethod\((\w+)\)\s*function\s+(\w+)', text),
                         [('CR4Game', 'OnGameStarted')])
        self.assertNotIn('@addMethod', text)
        self.assertNotIn('@addField', text)
        self.assertIn('result = wrappedMethod(restored);', text)
        self.assertIn('return result;', text)

    def test_witcherscript_hygiene(self):
        data = script().read_bytes()
        self.assertNotIn(b'\r', data)
        self.assertTrue(all(b < 128 for b in data))
        self.assertEqual(script().name, 'modcmfadaptersmoothmap_cmf.ws')
        defined = re.findall(r'^function (\w+)', data.decode(), re.M)
        self.assertEqual(defined, ['OnGameStarted', 'SmoothMapAdapterSend', 'SmoothMapAdapterKey'])
        for line in data.decode().splitlines():
            self.assertFalse(line.startswith(' '), line)

    def test_pack_tool_finds_no_errors_or_warnings(self):
        report, _ = cmf_pack.check_pack(ADAPTER, PROVIDER)
        lines = report.lines()
        self.assertFalse([l for l in lines if l.startswith(('ERROR', 'WARNING'))], lines)

    def test_player_readme_states_requirements(self):
        readme = (ADAPTER/'README.txt').read_text(encoding='ascii')
        for phrase in ('API version 6', 'Smooth Map 1.1 (Nexus mod 13530)', 'modSmoothMap',
                       'Mods\\modCMFAdapterSmoothMap', 'ships its own CMF support, uninstall this adapter',
                       'other Smooth Map versions are not'):
            self.assertIn(phrase, readme)


if __name__ == '__main__':
    unittest.main()
