"""Annoying Map adapter: the hooks it wraps, the Annoying Map names it calls, and the WitcherScript rules it keeps.

Annoying Map 3.1 remembers the map's place and zoom per region from reports its own map file sends; CMF's map
file sends none. The adapter feeds CMF 9's map view report into Annoying Map's own storage and, at each region
shown, puts Annoying Map's real zoom limits back and opens at its saved zoom. These are static checks; nothing
here compiled or ran in game.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack

ADAPTER = ROOT/'source/adapters/annoying-map/modCMFAdapterAnnoyingMap'
SCRIPTS = ADAPTER/'content/scripts/local'
PROVIDER = 'modAnnoyingMap'
# Annoying Map 3.1's own names (amap.ws, amap_anno.ws, its mapMenu.ws line 2020): the only ones the adapter uses.
ANNOYING_MAP = {'AMap', 'AMapZoom', 'AM_FilterArea', 'OnZoomMap', 'am_maxZoom', 'SetXY', 'GetXY', 'GetX'}


def script():
    files = sorted(SCRIPTS.glob('*.ws'))
    assert len(files) == 1, files
    return files[0]


def code():
    return cmf_pack.strip_comments(script().read_text(encoding='ascii'))


class AnnoyingMapAdapterTests(unittest.TestCase):
    def test_wraps_only_cmfs_view_hooks_and_game_start(self):
        wraps = re.findall(r'@wrapMethod\((\w+)\)\s*function\s+(\w+)', code())
        self.assertEqual(wraps, [('CR4Game', 'OnGameStarted'), ('CMFCore', 'OnMapView'),
                                 ('CMFCore', 'OnMapOpening')])
        # No wrapper on Annoying Map's (or the game's) map menu: its own script stays exactly as shipped.
        self.assertNotIn('@wrapMethod(CR4MapMenu)', code())
        self.assertNotIn('@addMethod', code())
        self.assertEqual(re.findall(r'@addField\((\w+)\)', code()), ['CMFCore'])

    def test_hook_signatures_match_revision_9(self):
        text = code()
        self.assertIn('function OnMapView(menu : CR4MapMenu, area : name, x : float, y : float, worldX : float, '
                      'worldY : float,\n\tzoom : float, reason : name)', text)
        self.assertIn('wrappedMethod(menu, area, x, y, worldX, worldY, zoom, reason);', text)
        self.assertIn('function OnMapOpening(menu : CR4MapMenu, area : name, mapContext : name)', text)
        self.assertIn('wrappedMethod(menu, area, mapContext);', text)
        # Wrappers run the earlier wrappers first, so other packs on the same hook keep working.
        for hook in ('OnMapView', 'OnMapOpening'):
            body = text.split('function ' + hook, 1)[1]
            self.assertLess(body.index('wrappedMethod('), body.index('AM'))

    def test_stores_what_annoying_maps_own_reports_store(self):
        text = code()
        self.assertIn('AMap().SetXY(x, y, AM_FilterArea(area));', text)
        self.assertIn('AMapZoom().SetXY(zoom, zoom, AM_FilterArea(area));', text)
        self.assertNotIn('m_shownArea', text)

    def test_restores_real_limits_before_opening_view(self):
        text = code().split('function OnMapOpening', 1)[1]
        self.assertIn('if (menu.am_maxZoom > 0)', text)
        self.assertLess(text.index('menu.OnZoomMap();'), text.index('CMFSetOpeningView('))
        self.assertIn('CMFSetOpeningView("modAnnoyingMap", area, 0, 0, zoom, true);', text)

    def test_one_provider_annoying_maps_folder(self):
        text = code()
        providers = set(re.findall(r'\b(?:CMF\w+)\("(\w+)"', text))
        self.assertEqual(providers, {PROVIDER})
        self.assertIn('CMFSetProviderName("modAnnoyingMap", "Annoying Map");', text)

    def test_adds_no_feature_of_its_own(self):
        text = code()
        # Hides, pins, art, drawings and theme keys stay out: Annoying Map's hides are its own script.
        for call in ('CMFRegister', 'CMFStylePin', 'CMFHidePin', 'CMFDraw', 'CMFStylePart', 'img://'):
            self.assertNotIn(call, text)
        calls = set(re.findall(r'\b([A-Za-z_]\w*)\s*\(', text))
        foreign = {c for c in calls if c.startswith('AM') or c in ANNOYING_MAP}
        self.assertTrue(foreign <= ANNOYING_MAP | {'AmAdapterSavedZoom'}, foreign)
        self.assertFalse((ADAPTER/'art').exists())

    def test_witcherscript_hygiene(self):
        data = script().read_bytes()
        self.assertNotIn(b'\r', data)
        self.assertTrue(all(b < 128 for b in data))
        self.assertEqual(script().name, 'modcmfadapterannoyingmap_cmf.ws')
        defined = re.findall(r'^function (\w+)', data.decode(), re.M)
        self.assertEqual(defined, ['OnGameStarted', 'AmAdapterSavedZoom', 'OnMapView', 'OnMapOpening'])
        for line in data.decode().splitlines():
            self.assertFalse(line.startswith(' '), line)
            self.assertLessEqual(len(line.expandtabs(4)), 120, line)

    def test_pack_tool_finds_no_errors_or_warnings(self):
        if 'CMFSetOpeningView' not in cmf_pack.API:
            self.skipTest('the pack tool does not list revision 9 calls yet')
        report, _ = cmf_pack.check_pack(ADAPTER, PROVIDER)
        lines = report.lines()
        self.assertFalse([l for l in lines if l.startswith(('ERROR', 'WARNING'))], lines)

    def test_player_readme_states_requirements(self):
        readme = (ADAPTER/'README.txt').read_text(encoding='ascii')
        for phrase in ('API revision 9', 'Annoying Map 3.1 for Remastered 5.01', 'Nexus mod 6140', 'modAnnoyingMap',
                       'Mods\\modCMFAdapterAnnoyingMap', 'Remove this adapter BEFORE', 'Other Annoying Map versions',
                       'Annoying Map is by crthdr'):
            self.assertIn(phrase, readme)
        for line in readme.splitlines():
            self.assertLessEqual(len(line), 90, line)


if __name__ == '__main__':
    unittest.main()
