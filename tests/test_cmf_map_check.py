"""Offline map-opening model paired with source-hook contracts; not engine timing proof."""
import json
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / 'source/core/content/scripts/local/cmfCore.ws'
SETTINGS = ROOT / 'source/core/content/scripts/local/cmfSettings.ws'
MENU = ROOT / 'source/settings/menus/mod0000_ConjunctionMapFramework.xml'
STRINGS = ROOT / 'source/strings.json'
WARNING = ("Another mod's map file is loading instead of CMF's, so CMF's map features are off. "
           "Put mod0000_ConjunctionMapFramework first in your load order, or see the CMF page on Nexus Mods.")


def body(source, method):
    """Read one function/event including nested blocks, without depending on line endings."""
    match = re.search(r'\b(?:function|event)\s+' + re.escape(method) + r'\([^)]*\)[^{]*\{', source)
    if not match:
        raise AssertionError('missing source method: ' + method)
    start = match.end()
    depth = 1
    for index in range(start, len(source)):
        if source[index] == '{':
            depth += 1
        elif source[index] == '}':
            depth -= 1
            if depth == 0:
                return source[start:index]
    raise AssertionError('unclosed source method: ' + method)


class OpeningModel:
    """Test-only events: config/hub/region are deliberately not opening boundaries."""
    def __init__(self, enabled=True):
        self.ready = False
        self.shown = False
        self.warned = False
        self.enabled = enabled
        self.notices = 0

    def event(self, event):
        if event in ('ready', 'theme', 'space', 'listen'):
            self.ready = True
        elif event == 'shown':
            self.shown = True
        elif event == 'close':
            warn = self.shown and not self.ready and self.enabled
            self.ready = False
            self.shown = False
            if warn and not self.warned:
                self.warned = True
                self.notices += 1


def warnings(events, enabled=True):
    model = OpeningModel(enabled)
    for event in events:
        model.event(event)
    return model.notices


class LifecycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding='ascii')

    def assert_hooks(self):
        # These source bindings prevent the model alone from qualifying a missing implementation.
        self.assertIn('cmfMapCheckReady = true;', body(self.core, 'CMFMapCheckReady'))
        self.assertIn('cmfMapCheckShown = true;', body(self.core, 'CMFMapCheckShown'))
        close = body(self.core, 'CMFMapCheckClose')
        self.assertIn('warn = cmfMapCheckShown && !cmfMapCheckReady;', close)
        self.assertIn('cmfMapCheckReady = false;', close)
        self.assertIn('cmfMapCheckShown = false;', close)
        self.assertIn('warn && CMFSettingsMapCheck()', close)
        self.assertIn('theGame.CMFGetCore().MapCheckWarnOnce();', close)
        once = body(self.core, 'MapCheckWarnOnce')
        self.assertIn('if (mapCheckWarned)', once)
        self.assertIn('mapCheckWarned = true;', once)

    def test_ready_before_configuration_survives(self):
        self.assert_hooks()
        self.assertEqual(warnings(['ready', 'config', 'shown', 'close']), 0)

    def test_early_close_does_not_consume_session_allowance(self):
        self.assert_hooks()
        self.assertEqual(warnings(['config', 'close', 'config', 'shown', 'close']), 1)

    def test_hub_and_region_round_trip_keep_readiness(self):
        self.assert_hooks()
        self.assertNotIn('CMFMapCheck', body(self.core, 'SwitchToHubMap'))
        self.assertEqual(warnings(['shown', 'ready', 'hub', 'region', 'close']), 0)

    def test_only_one_warning_in_the_session(self):
        self.assert_hooks()
        self.assertEqual(warnings(['shown', 'close', 'shown', 'close']), 1)

    def test_disabled_never_warns(self):
        self.assert_hooks()
        self.assertEqual(warnings(['shown', 'close'], enabled=False), 0)

    def test_each_callback_independently_marks_ready(self):
        callbacks = {'theme': 'OnCMFMapThemeReady', 'space': 'OnCMFMapSpaceReady', 'listen': 'OnCMFListenReady'}
        for event, callback in callbacks.items():
            with self.subTest(callback=callback):
                self.assert_hooks()
                self.assertTrue(body(self.core, callback).lstrip().startswith('CMFMapCheckReady();'))
                self.assertEqual(warnings(['shown', event, 'close']), 0)

    def test_next_opening_does_not_inherit_readiness(self):
        self.assert_hooks()
        self.assertEqual(warnings(['shown', 'ready', 'close', 'shown', 'close']), 1)
        self.assertEqual(warnings(['ready', 'close', 'shown', 'close']), 1)

    def test_independent_menu_objects_share_only_warning_allowance(self):
        self.assert_hooks()
        self.assertIn('@addField(CR4MapMenu)\nvar cmfMapCheckReady : bool;', self.core)
        self.assertIn('@addField(CR4MapMenu)\nvar cmfMapCheckShown : bool;', self.core)
        self.assertIn('private var mapCheckWarned : bool;', self.core)
        self.assertEqual(self.core.count('mapCheckWarned ='), 1, 'save reload must not reset session state')
        model = OpeningModel()
        model.event('shown')
        model.event('close')
        next_menu = OpeningModel()
        next_menu.warned = model.warned
        next_menu.event('shown')
        next_menu.event('close')
        self.assertEqual(model.notices + next_menu.notices, 1)

    def test_shown_wraps_the_actual_base_hook_and_forwards_once(self):
        hook = body(self.core, 'OnMenuShown')
        self.assertIn('@wrapMethod(CR4MenuBase)\nfunction OnMenuShown()', self.core)
        self.assertEqual(hook.count('wrappedMethod('), 1)
        self.assertIn('mapMenu = (CR4MapMenu)this;', hook)
        self.assertRegex(hook, r'if \(mapMenu\)\s*\{\s*mapMenu.CMFMapCheckShown\(\);')
        self.assertLess(hook.index('wrappedMethod();'), hook.index('mapMenu.CMFMapCheckShown();'))

    def test_close_preserves_view_and_vanilla_before_warning(self):
        hook = body(self.core, 'OnClosingMenu')
        self.assertEqual(hook.count('wrappedMethod('), 1)
        self.assertLess(hook.index("CMFReportView('close');"), hook.index('wrappedMethod();'))
        self.assertIn('CMFMapCheckClose();', hook)
        self.assertLess(hook.index('wrappedMethod();'), hook.index('CMFMapCheckClose();'))
        close = body(self.core, 'CMFMapCheckClose')
        for reset in ('cmfMapCheckReady = false;', 'cmfMapCheckShown = false;'):
            self.assertLess(close.index(reset), close.index('MapCheckWarnOnce();'))

    def test_opening_paths_only_assign_flags(self):
        for method, flag in [('CMFMapCheckReady', 'cmfMapCheckReady'), ('CMFMapCheckShown', 'cmfMapCheckShown')]:
            self.assertEqual(body(self.core, method).strip(), flag + ' = true;')
        self.assertNotRegex(self.core, r'function OnConfigUI\(\)[^{]*\{[^}]*cmfMapCheck')

    def test_callback_forwarding_stays_intact(self):
        for callback, calls in {
            'OnCMFMapThemeReady': ['SendScreen(GetMenuFlashValueStorage());', 'SendTheme(GetMenuFlashValueStorage());'],
            'OnCMFMapSpaceReady': ['SpaceListenerReady(this);'],
            'OnCMFListenReady': ['ListenReady(this, keys);'],
        }.items():
            for call in calls:
                self.assertIn(call, body(self.core, callback))

    def test_dialog_and_warning_log_are_guarded_once(self):
        once = body(self.core, 'MapCheckWarnOnce')
        self.assertRegex(once, r'if \(mapCheckWarned\)\s*\{\s*return false;\s*\}')
        self.assertLess(once.index('mapCheckWarned = true;'), once.index('CMFMapCheckSchedule();'))
        warning = "map check: CMF's map did not load; another mod's map file is loading first"
        self.assertEqual(self.core.count('CMFLog("' + warning + '");'), 1)
        self.assertIn('CMFLog("' + warning + '");', once)
        self.assertIn('return true;', once)
        self.assertNotIn('ShowUserDialogAdv', once)

    def test_box_waits_until_the_menus_have_closed(self):
        # A box asked for while the map's menus close can be cleared with them, so it waits on a timer until no
        # menu, message box, black screen or scene is up, as the adapter check's own box does.
        later = body(self.core, 'CMFMapCheckLater')
        self.assertRegex(later, r'if \(CMFMapCheckBusy\(\)\)\s*\{\s*CMFMapCheckSchedule\(\);\s*return;')
        self.assertIn('ShowUserDialogAdv(0, GetLocStringByKeyExt("cmf_popup_title"),', later)
        self.assertIn('GetLocStringByKeyExt("cmf_map_check_warning"), false, UDB_Ok);', later)
        busy = body(self.core, 'CMFMapCheckBusy')
        for check in ("GetPopup('MessagePopup')", 'IsAnyMenu()', 'IsBlackscreen()', 'IsDialogOrCutscenePlaying()'):
            self.assertIn(check, busy)
        self.assertIn("thePlayer.AddTimer('CMFMapCheckLater', 0.2, false, , , false, true);",
                      body(self.core, 'CMFMapCheckSchedule'))
        self.assertEqual(self.core.count('ShowUserDialogAdv('), 1)

    def test_close_keeps_the_games_result_and_always_logs(self):
        hook = body(self.core, 'OnClosingMenu')
        self.assertIn('result = wrappedMethod();', hook)
        self.assertTrue(hook.rstrip().endswith('return result;'))
        close = body(self.core, 'CMFMapCheckClose')
        self.assertNotIn('CMFSettingsDebug', close)
        self.assertLess(close.index('CMFLog("map check close shown="'), close.index('warn = '))


class ResourceTests(unittest.TestCase):
    def test_hidden_setting_defaults_on_and_parses_off_values(self):
        settings = SETTINGS.read_text(encoding='ascii')
        reader = body(settings, 'CMFSettingsMapCheck')
        self.assertIn("StrLower(theGame.GetInGameConfigWrapper().GetVarValue('CMFSettings', 'CMFMapCheck'))", reader)
        self.assertIn('return value != "false" && value != "0";', reader)
        for value, expected in [('', True), ('-1', True), ('true', True), ('1', True), ('false', False), ('FALSE', False), ('0', False)]:
            with self.subTest(value=value):
                self.assertEqual(value.lower() not in ('false', '0'), expected)
        rows = ET.parse(MENU).getroot().findall("./Group[@id='CMFSettings']/VisibleVars/Var[@id='CMFMapCheck']")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].get('value'), 'true')
        self.assertEqual(rows[0].get('visibilityCondition'), 'hideAlways')

    def test_warning_is_localized_with_reserved_id(self):
        rows = json.loads(STRINGS.read_text(encoding='utf-8'))['strings']
        row = [row for row in rows if row['key'] == 'cmf_map_check_warning']
        self.assertEqual(len(row), 1)
        self.assertEqual(row[0]['id'], 2000200009)
        self.assertEqual(row[0]['text']['en'], WARNING)
        self.assertEqual([row['id'] for row in rows if row['key'] == 'cmf_popup_title'], [2000200001])


if __name__ == '__main__':
    unittest.main()
