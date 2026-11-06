"""API 19: a pin zoom range (property 36) a player set in a mod's own settings is held inside the region's zoom range.

The panel's cmfApplyZoom is turned into Python from the edit text; the core flag is checked by running SetNewPinFields.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import re
import unittest

from ws_contract_runner import Array, bind
from ws_text import ROOT, core_text, ws_function
from test_cmf_movie_hide_panels import simulate_chain

CORE = core_text()
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
DESCRIBED = 'red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'
HUB = 'red/game/witcher3/menus/worldmap/HubMap.as'
DATA = 'red/game/witcher3/data/StaticMapPinData.as'


def apply_zoom_fn():
    text = EDITS[DESCRIBED][-1]['replace']
    lines, depth = [], 1
    for raw in text.split('\n')[2:-1]:
        t = raw.strip()
        if not t or t == '{':
            continue
        if t == '}':
            depth -= 1
            continue
        t = t.replace('this.cmfExtraPinLook(pin)', 'extra').replace('this.', '').replace(' as StaticMapPinData', '')
        t = t.replace('&&', ' and ').replace('||', ' or ').replace('Math.max', 'max').replace('Math.min', 'min')
        m = re.match(r'if\((.*)\)$', t)
        if m:
            lines.append('    ' * depth + 'if ' + m.group(1) + ':')
            depth += 1
            continue
        m = re.match(r'var (\w+):\w+ = (.*);$', t)
        t = (m.group(1) + ' = ' + m.group(2)) if m else t.rstrip(';')
        m = re.match(r'(\w+ = )(.*?) \? (.*) : (.*)$', t)
        if m:
            t = m.group(1) + '(' + m.group(3) + ') if (' + m.group(2) + ') else (' + m.group(4) + ')'
        lines.append('    ' * depth + t)
    src = ('def f(data, zoom, regionMin=0, regionMax=0, extra=True, _isHidden=False):\n'
           + '\n'.join(lines) + '\n    return cmfZoomHidden\n')
    ns = {}
    exec(src, ns)
    return ns['f']


class Pin:
    def __init__(self, lo, hi, clamp=False, enabled=True):
        self.cmfPinZoomMin, self.cmfPinZoomMax = lo, hi
        self.cmfPinZoomClamp, self.cmfPinZoomEnabled = clamp, enabled

    def __bool__(self): return True


class PanelClamp(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.hidden = staticmethod(apply_zoom_fn())

    def test_white_orchard_minimum_above_the_region_stays_visible_at_max_zoom(self):
        pin = Pin(4.7, 1000, clamp=True)
        self.assertFalse(self.hidden(pin, 3.5, 0.9, 3.5))
        self.assertTrue(self.hidden(pin, 3.0, 0.9, 3.5))   # still hidden zoomed out, as asked
        self.assertFalse(self.hidden(pin, 3.5, 0.9, 3.5))

    def test_velen_range_is_unchanged(self):
        pin = Pin(3.0, 1000, clamp=True)
        for zoom in (1.0, 2.9, 3.0, 4.0, 6.0):
            self.assertEqual(self.hidden(pin, zoom, 0.9, 7.0), zoom < 3.0)

    def test_other_mods_values_stay_exactly_as_today(self):
        pin = Pin(4.7, 5.0, clamp=False)
        self.assertTrue(self.hidden(pin, 3.5, 0.9, 3.5))
        self.assertTrue(self.hidden(pin, 5.5, 0.9, 7.0))
        self.assertFalse(self.hidden(pin, 4.8, 0.9, 7.0))

    def test_zero_still_means_show_at_every_zoom_for_the_minimum(self):
        pin = Pin(0, 1000, clamp=True)
        self.assertFalse(self.hidden(pin, 0.9, 0.9, 3.5))
        self.assertFalse(self.hidden(pin, 3.5, 0.9, 3.5))

    def test_a_missing_region_range_changes_nothing(self):
        pin = Pin(4.7, 1000, clamp=True)
        self.assertTrue(self.hidden(pin, 3.5))
        self.assertTrue(self.hidden(pin, 3.5, 0, 0))

    def test_not_enabled_never_hides(self):
        self.assertFalse(self.hidden(Pin(4.7, 5, clamp=True, enabled=False), 1.0, 0.9, 3.5))


class Wiring(unittest.TestCase):
    def test_every_apply_zoom_caller_passes_the_region_range(self):
        _, text = simulate_chain(EDITS[HUB])
        calls = re.findall(r'\.cmfApplyZoom\([^;]*;', text)
        self.assertEqual(len(calls), 4)
        for c in calls:
            self.assertIn('this.cmfMinZoom(),this.cmfMaxZoom())', c)

    def test_new_finds_survive_the_chain_and_the_field_is_compared(self):
        for path, count in ((DATA, 1), (DESCRIBED, 1), (HUB, 4)):
            records, _ = simulate_chain(EDITS[path])
            for r in records[len(EDITS[path]) - count:]:
                self.assertFalse(r['seeded'])
                self.assertEqual(r['matches'], 1)
        _, text = simulate_chain(EDITS[DESCRIBED])
        self.assertIn('a.cmfPinZoomClamp != b.cmfPinZoomClamp', text)
        self.assertIn('public var cmfPinZoomClamp:Boolean = false;', EDITS[DATA][-1]['replace'])


class CoreFlag(unittest.TestCase):
    class Obj:
        def __init__(self): self.f = {}
        def SetMemberFlashNumber(self, n, v): self.f[n] = v
        def SetMemberFlashBool(self, n, v): self.f[n] = v
        def SetMemberFlashString(self, n, v): self.f[n] = v
        def SetMemberFlashInt(self, n, v): self.f[n] = v

    def run_set(self, provider, marked, any_setter=True):
        env = dict(anySetter=any_setter)
        env['IsSetter'] = lambda p, i: marked and p == 'modCustomizer' and i == 36
        env['SetNewPinFields'] = bind(CORE, 'SetNewPinFields', env, ('dataObject', 'propertyId', 'text', 'number', 'x', 'y', 'provider'))
        pin = self.Obj()
        env['SetNewPinFields'](pin, 36, '', 0, 4.7, 1000.0, provider)
        return pin.f

    def test_flag_only_for_a_player_setting_winner(self):
        f = self.run_set('modCustomizer', True)
        self.assertEqual((f['cmfPinZoomMin'], f['cmfPinZoomMax'], f['cmfPinZoomEnabled']), (4.7, 1000.0, True))
        self.assertTrue(f['cmfPinZoomClamp'])
        self.assertNotIn('cmfPinZoomClamp', self.run_set('modOther', True))
        self.assertNotIn('cmfPinZoomClamp', self.run_set('modCustomizer', False))
        self.assertNotIn('cmfPinZoomClamp', self.run_set('modCustomizer', True, any_setter=False))

    def test_text(self):
        body = ws_function(CORE, 'private function SetNewPinFields(')
        self.assertIn('anySetter && IsSetter(provider, 36)', body)


if __name__ == '__main__':
    unittest.main()
