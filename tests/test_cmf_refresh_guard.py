"""A pin or map refresh during a build, or after the map closed, is refused (API 18; seam findings S15 and S5).

Source text checks and a small Python model of the busy count; only a start proves it in game.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ws_text import core_text, ws_function

CORE = core_text()


class RefreshGuard(unittest.TestCase):
    def test_guard_spans_the_whole_update_data_wrapper(self):
        body = ws_function(CORE, 'function UpdateData(optional ignoreSelectionChange : bool)')
        self.assertLess(body.index('BuildBusy(true)'), body.index('BeginBuild('))
        self.assertGreater(body.index('BuildBusy(false)'), body.index('CMFStamp("end")'))
        self.assertGreater(body.index('BuildBusy(false)'), body.index('SetFlashArray("worldmap.global.pins.static"'))

    def test_refresh_pins_refused_while_busy(self):
        body = ws_function(CORE, 'public function RefreshPins(')
        self.assertIn('refreshBusy > 0', body)
        self.assertLess(body.index('return false;'), body.index('CMFRefreshPins()'))

    def test_refresh_map_refused_while_busy(self):
        body = ws_function(CORE, 'public function RefreshMap(')
        self.assertIn('refreshBusy > 0', body)
        self.assertLess(body.index('return false;'), body.index('CMFMapSpaceSend(true)'))

    def test_map_refresh_refused_while_its_own_send_runs(self):
        body = ws_function(CORE, 'function CMFMapSpaceSend(refresh : bool)')
        self.assertLess(body.index('BuildBusy(true)'), body.index('MapReady('))
        self.assertGreater(body.index('BuildBusy(false)'), body.index('SendSpaceMode('))
        self.assertIn('if (refresh)', body[:body.index('BuildBusy(true)')])

    def test_busy_count_never_negative(self):
        body = ws_function(CORE, 'public function BuildBusy(')
        self.assertIn('else if (refreshBusy > 0)', body)
        count = 0
        for on in (False, True, True, False, False, False):
            count = count + 1 if on else max(0, count - 1)
            self.assertGreaterEqual(count, 0)
        self.assertEqual(count, 0)

    def test_refresh_returns_false_after_the_map_closed(self):
        self.assertIn('ForgetSpaceMenu(menu);', ws_function(CORE, 'public function CMFMapClosed('))
        forget = ws_function(CORE, 'public function ForgetSpaceMenu(')
        self.assertIn('spaceMenu == menu', forget)
        self.assertIn('spaceMenu = NULL;', forget)
        for head in ('public function RefreshMap(', 'public function RefreshPins('):
            self.assertIn('!spaceMenu', ws_function(CORE, head))

    def test_close_wrapper_forgets_the_menu_before_the_wrapped_close(self):
        # Review M3: a wrapper nested inside CMF's must already see the map as closed.
        body = ws_function(CORE, 'function OnClosingMenu()')
        self.assertLess(body.index('ForgetSpaceMenu(this);'), body.index('wrappedMethod()'))

    def test_api_comment_states_both_rules(self):
        for head in ('function CMFMapRefresh() : bool', 'function CMFMapRefreshPins() : bool'):
            at = CORE.index(head)
            comment = CORE[CORE.rindex('\n\n', 0, at):at]
            self.assertIn('during a', comment)
            self.assertIn('build', comment)
            self.assertIn('no map is open', comment)

    def test_refusal_logged_once_under_debug(self):
        body = ws_function(CORE, 'private function NoteRefused(')
        self.assertIn('CMFSettingsDebug() && !refuseLogged', body)
        self.assertIn('"refresh refused kind="', body)


if __name__ == '__main__':
    unittest.main()
