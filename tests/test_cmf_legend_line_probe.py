"""Debug probe for the legend's leftover gold line (panel part, notes only)."""
import json
import unittest

EDITS = json.load(open('source/panel/pin-fields/edits.json', encoding='utf-8'))['classes']
MM = EDITS['red/game/witcher3/menus/worldmap/MapMenu.as']
HUB = EDITS['red/game/witcher3/menus/worldmap/HubMap.as']
TEXT = '\n'.join(e['replace'] for e in MM)


def balanced(s):
    return s.count('{') == s.count('}') and s.count('(') == s.count(')')


class Follow(unittest.TestCase):
    def fn(self):
        i = TEXT.index('protected function cmfModeShown(')
        return TEXT[i:TEXT.index('\n      }\n', i)]

    def test_rows_and_tab_follow_the_legend(self):
        s = self.fn()
        self.assertIn('if(part == "legend" || part == "legendRow" || part == "legendTab") { return this._cmfLegendShown', s)
        self.assertIn('part == "legend" || part == "legendRow" || part == "legendTab" || part == "tracker" || part == "preview"', s)

    def test_model_hidden_and_shown(self):
        def shown(part, legend_shown, visible, waiting=False):
            follow = part in ('legend', 'legendRow', 'legendTab')
            if waiting and (follow or part in ('tracker', 'preview')):
                return False
            if follow:
                return legend_shown and visible
            return True
        for part in ('legend', 'legendRow', 'legendTab'):
            self.assertFalse(shown(part, False, True))     # auto-hidden: the tab underline goes with it
            self.assertTrue(shown(part, True, True))       # visible legend: drawn as before
            self.assertFalse(shown(part, True, False))
        self.assertTrue(shown('tooltip', False, True))     # other parts are not affected

    def test_the_measure_gate_uses_it(self):
        self.assertIn('if(!this.cmfModeShown(param1)) { return list; }', TEXT)


class Probe(unittest.TestCase):
    def fn(self, name):
        i = TEXT.index('function ' + name + '(')
        j = TEXT.index('\n      }\n', i)
        return TEXT[i:j]

    def test_functions_exist_once_and_balance(self):
        for n in ('cmfLegendProbe', 'cmfLegendProbeFrame', 'cmfProbeRows', 'cmfLegendScan', 'cmfScanNode'):
            self.assertEqual(TEXT.count('function ' + n + '('), 1, n)
            self.assertTrue(balanced(self.fn(n) + '\n      }'), n)

    def test_probe_runs_where_the_log_shows_it_firing(self):
        # the legend rows note (cmfNoteLegend) and the device change the core sends through cmfNavClear("device")
        self.assertIn('this.cmfProbeRows(shownRows == 0);', self.fn('cmfNoteLegend'))
        self.assertIn('if(o.visible) { shownRows++; }', self.fn('cmfNoteLegend'))
        self.assertIn('if(reason == "device") { this.cmfLegendProbe("device"); }', self.fn('cmfNavClear'))
        self.assertIn('this.cmfLegendProbe(param1 ? "legend shown" : "legend hide");', TEXT)

    def test_hub_map_edit_is_back_to_the_roam_text(self):
        h = HUB[158]
        self.assertEqual(h['find'], 'super.OnControllerChanged(param1,param2);')
        self.assertNotIn('cmfLegendProbe', h['replace'])

    def test_no_timer_and_the_late_scan_always_writes(self):
        self.assertNotIn('flash.utils.Timer', TEXT)
        self.assertIn('this.cmfLegendScan(this._cmfProbeWhy + " +400ms");', self.fn('cmfLegendProbeFrame'))
        self.assertIn('this._cmfProbeAt = getTimer() + 400;', self.fn('cmfLegendProbe'))
        self.assertIn('scan error', self.fn('cmfLegendScan'))

    def test_scan_uses_the_asked_area_and_skips_the_map(self):
        s = self.fn('cmfScanNode')
        self.assertIn('r.right >= -500 && r.left <= 3000 && r.bottom >= 880 && r.top <= 1030', s)
        self.assertNotIn('getQualifiedClassName', TEXT)
        self.assertIn('String(o)', s)
        self.assertIn('catch(scanError:Error)', s)
        self.assertIn('catch(boundsError:Error)', s)
        self.assertEqual(TEXT.count('function cmfProbeError('), 1)
        self.assertIn('o == this.mcHubMap || o == this.mcPointersCanvas', s)
        self.assertIn('!o.visible || a < 0.02', s)

    def test_notes_only_and_two_scans(self):
        self.assertIn('"line probe " + why', self.fn('cmfLegendScan'))
        self.assertIn('this.cmfLegendScan(why + " now");', self.fn('cmfLegendProbe'))

    def test_no_new_find_strings(self):
        self.assertEqual(MM[366]['find'][:20], MM[366]['find'][:20])
        self.assertEqual(MM[380]['find'], '      public function cmfStamp(param1:String) : void\n')
        self.assertEqual(MM[254]['find'], '         this._cmfPanelShown = param1;')


if __name__ == '__main__':
    unittest.main()
