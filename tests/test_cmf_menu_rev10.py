"""Menu add-on 1.3.0 (CMF API revision 10): the Basic list, the Map movement and Map behaviour pages, the Screen line,
the 1.2.x names on an older CMF and string IDs that never move (rev 10 build contract section 7).

Static checks of the menu tables (tools/cmf_menu_addon.py) and cmfMenu.ws; no game files.
"""
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_menu_addon as addon

MENU_WS = ROOT/'source/menu/content/scripts/local/cmfMenu.ws'


def body(text, signature):
    match = re.search(re.escape(signature) + r'.*?\n\{\n(.*?)\n\}', text, re.S)
    assert match, signature
    return match.group(1)


def rows_of(group):
    return next(rows for g, _p, _t, rows in addon.PAGES if g == group)


class TableTests(unittest.TestCase):
    def test_basic_is_a_plain_list_in_the_agreed_order(self):
        self.assertEqual(rows_of('CMFMenuBasic'), [
            ('pick', 'Icons', 'Pin icons'),
            ('pick', 'Colours', 'Pin colours'),
            ('pick', 'Size', 'Pin size'),
            ('pick', 'Labels', 'Pin labels'),
            ('pick', 'Legend', 'Legend and filter tabs'),
            ('pick', 'Hidden', 'Hidden pins'),
            ('pick', 'Look', 'Map look'),
            ('pick', 'Painting', 'Map painting'),
            ('pick', 'Drawings', 'Drawings on the map'),
            ('pick', 'Clicks', 'Pin clicks'),
            ('pick', 'Movement', 'Map movement'),
            ('pick', 'Behaviour', 'Map behaviour')])

    def test_advanced_pages(self):
        self.assertEqual(rows_of('CMFMenuAdvSize'), [('pick', 'Size_Scale', 'Pin size'),
                                                     ('pick', 'Labels_Text', 'Level tags and label text')])
        movement = [('Movement_Area', 'Map area'), ('Movement_Pan', 'Pan and zoom feel'),
                    ('Movement_ZoomOut', 'Zoom out to the whole region'), ('Movement_Controller', 'Controller crosshair'),
                    ('Movement_Opening', 'Opening and closing'), ('Movement_View', 'Opening view'),
                    ('Movement_Wide', 'Fill wide screens')]
        behaviour = [('Size_Spread', 'Stacked pins spread out'), ('Size_Lead', 'Which pin leads a spread'),
                     ('Labels_Place', 'Label place and hiding'),
                     ('Behaviour_InfoBoxDodge', 'Info box moves out of the way'),
                     ('Behaviour_InfoBoxHeight', 'Info box height and scrolling'),
                     ('Behaviour_HoverNames', 'Names only on hover')]
        self.assertEqual(rows_of('CMFMenuAdvMovement'), [('pick',) + row for row in movement])
        self.assertEqual(rows_of('CMFMenuAdvBehaviour'), [('pick',) + row for row in behaviour])
        self.assertEqual(rows_of('CMFMenuWinMovement'), [('win',) + row for row in movement])
        self.assertEqual(rows_of('CMFMenuWinBehaviour'), [('win',) + row for row in behaviour])
        self.assertEqual(rows_of('CMFMenuWinSize'), [('win', 'Size_Scale', 'Pin size'),
                                                     ('win', 'Labels_Text', 'Level tags and label text')])
        groups = [g for g, _p, _t, _r in addon.PAGES]
        self.assertEqual(groups.index('CMFMenuAdvBehaviour'), groups.index('CMFMenuAdvMovement') + 1)
        self.assertEqual(groups.index('CMFMenuWinBehaviour'), groups.index('CMFMenuWinMovement') + 1)

    def test_screen_line_ends_the_loaded_mods_page(self):
        # Above the heading it made the game list the page's parts in the right-hand column (start B, 2026-10-24).
        self.assertEqual(rows_of('CMFMenuStatusMods'), [('head', 'Mods', 'Map mods loaded'), ('mods',), ('screen',)])
        self.assertIn('<Var id="CMFStatusScreen" value="0" displayName="Screen" displayType="OPTIONS"', addon.menu_xml())

    def test_string_ids_never_move(self):
        # Menu add-on 1.2.0 shipped these; 1.3.0 only appends.
        shipped = ['panel_cmf_order', 'panel_cmf_basic', 'panel_cmf_advanced', 'panel_cmf_adv_icons',
                   'panel_cmf_adv_colours', 'panel_cmf_adv_size', 'panel_cmf_adv_legend', 'panel_cmf_adv_look',
                   'panel_cmf_adv_movement', 'panel_cmf_adv_painting', 'panel_cmf_adv_clicks', 'panel_cmf_general',
                   'panel_cmf_status', 'panel_cmf_status_mods', 'panel_cmf_win_icons', 'panel_cmf_win_colours',
                   'panel_cmf_win_size', 'panel_cmf_win_legend', 'panel_cmf_win_look', 'panel_cmf_win_movement',
                   'panel_cmf_win_painting', 'panel_cmf_win_clicks', 'cmf_menu_rule_box', 'cmf_menu_rule_dash',
                   'panel_cmf_adv_behaviour', 'panel_cmf_win_behaviour']
        ids = {s['key']: s['id'] for s in addon.catalog()['strings']}
        self.assertEqual({key: ids[key] for key in shipped},
                         {key: addon.ID_BASE + 1 + i for i, key in enumerate(shipped)})
        self.assertEqual(set(ids) - set(shipped), {'cmf_menu_support_present'})
        self.assertEqual(ids['cmf_menu_support_present'], 2000200127)
        texts = {s['key']: s['text']['en'] for s in addon.catalog()['strings']}
        self.assertEqual(texts['panel_cmf_adv_behaviour'], 'Map behaviour')
        self.assertEqual(texts['panel_cmf_win_behaviour'], 'Who wins: map behaviour')
        # The probe-only heading page still follows the last ID.
        self.assertEqual(addon.catalog(probe=True)['strings'][-1]['key'], 'panel_' + addon.HEAD_TEST_PATH)

    def test_version(self):
        # 1.4.0 (descriptions) keeps every 1.3.0 row.
        self.assertGreaterEqual(tuple(int(n) for n in addon.VERSION.split('.')), (1, 3, 0))
        self.assertIn('1.3.0 (CMF 1.4.0, CMFGetVersion 10)', MENU_WS.read_text(encoding='ascii').split('\n\n')[0])


class ScriptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script = MENU_WS.read_text(encoding='ascii')

    def test_old_names_on_an_older_cmf(self):
        old = body(self.script, 'function CMFMenuOldLabel(key : string) : string')
        self.assertTrue(old.lstrip().startswith('if (CMFGetVersion() >= 10)\n\t{\n\t\treturn "";'))
        for key, label in (('Size', 'Pin size and spreading'), ('Size_Spread', 'Spreading'),
                           ('Movement_Pan', 'Pan and zoom')):
            self.assertIn('if (key == "%s")\n\t{\n\t\treturn "%s";' % (key, label), old)
        for fill in ('function CMFMenuFillPick(', 'function CMFMenuFillWin('):
            text = body(self.script, fill)
            self.assertIn('row.SetMemberFlashString("label", CMFMenuOldLabel(key));', text)
            # Only after the unknown-key check, so a row newer than the CMF is still left out.
            self.assertLess(text.index('if (choice < 0)'), text.index('CMFMenuOldLabel(key)'))

    def test_screen_line_calls_the_new_core_only_on_version_10(self):
        screen = body(self.script, 'function CMFMenuFillScreen(')
        self.assertLess(screen.index('if (CMFGetVersion() < 10)\n\t{\n\t\treturn false;'), screen.index('CMFScreenWidth()'))
        self.assertIn('core.ChoiceIndex("Movement_Wide")', screen)
        for text in ('"Screen: open the map once"', '"Screen: " + IntToString(RoundF(width)) + " x " + '
                     'IntToString(RoundF(height))', '"Map fills it (CMF)"', '"16:9 map (Vanilla)"',
                     'CMFMenuFit("Map fills it (", core.ProviderName(winner), ")")'):
            self.assertIn(text, screen)
        self.assertEqual(self.script.count('CMFScreenWidth()'), 1)
        self.assertEqual(self.script.count('CMFScreenHeight()'), 1)
        page = body(self.script, 'function CMFMenuFillPage(')
        self.assertIn('else if (varText == "CMFStatusScreen")\n\t\t{\n\t\t\tif (!CMFMenuFillScreen(storage, row, '
                      'remembered))\n\t\t\t{\n\t\t\t\trows.RemoveElement(i);', page)

    def test_wide_vanilla_asks_the_cores_deciding_answer(self):
        wide = body(self.script, 'function CMFMenuWideVanilla() : bool')
        self.assertIn('return core.DecidedAnswer(core.ChoiceIndex("Movement_Wide")) == "vanilla";', wide)
        self.assertNotIn('GetVarValue', wide)
        core = (ROOT/'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='ascii')
        self.assertIn('public function DecidedAnswer(choice : int) : string', core)

    def test_behaviour_feature_on_the_loaded_mods_page(self):
        mod = body(self.script, 'function CMFMenuFillMod(')
        self.assertIn('behaviour = core.ChoiceIndex("Behaviour");', mod)
        self.assertIn('if (behaviour >= 0 && core.Offers(behaviour, providers[index]))', mod)
        self.assertIn('case 62:\n\t\t\treturn "Behaviour";', self.script)

    def test_reset_stays_pending_until_the_pages_are_built_again(self):
        # Start B (2026-10-24): picks and the "has nothing" row set on the same screen came back after Reset.
        changed = body(self.script, 'function CMFMenuValueChanged(')
        self.assertIn('CMFMenuReset("row");\n\t\t\ttheGame.CMFMenuGetState().SetResetPending(true);', changed)
        guard = changed.index('if (theGame.CMFMenuGetState().ResetPending() && (varText == "CMFFallthrough"')
        self.assertLess(changed.index('if (varText == "CMFReset")'), guard)
        self.assertLess(guard, changed.index('if (varText == "CMFFallthrough" || varText == "CMFReport")'))
        self.assertLess(guard, changed.index('if (StrBeginsWith(varText, "CMFPick_"))'))
        self.assertIn('CMFMenuUndoChange(varName, varText);', changed)
        undo = body(self.script, 'function CMFMenuUndoChange(')
        self.assertIn("config.SetVarValue('CMFMenuGeneral', 'CMFFallthrough', \"0\");", undo)
        self.assertIn('config.SetVarValue(groupName, varName, "0");', undo)
        self.assertIn('config.SetVarValue(groupName, nameVar, "");', undo)
        closing = body(self.script, '@wrapMethod(CR4IngameMenu) function OnClosingMenu()')
        self.assertLess(closing.index('result = wrappedMethod();'), closing.index('CMFMenuReset("menu closed");'))
        self.assertLess(closing.index('CMFMenuReset("menu closed");'), closing.index('theGame.SaveUserSettings();'))
        self.assertTrue(closing.rstrip().endswith('return result;'))
        fill = body(self.script, 'function IngameMenu_FillSubMenuOptionsList(')
        self.assertLess(fill.index('CMFMenuReset("pages built");'), fill.index('result = wrappedMethod('))
        self.assertEqual(self.script.count('CMFMenuReset()'), 0)


if __name__ == '__main__':
    unittest.main()
