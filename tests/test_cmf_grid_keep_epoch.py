"""Grid keep per provider with an epoch (API 18): records on the pin, revoke by Unkeep or a new epoch.

The WitcherScript is checked as text; the record rules are also run in a small Python model of the same steps. Only a start proves the behaviour in game.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ws_text import core_text, ws_function

CORE = core_text()


class Model:
    """Python copy of GridKeepAdd, GridKeepRemove, GridKeepValid and GridPinKept."""

    def __init__(self):
        self.epochs = {}

    def epoch(self, provider):
        return self.epochs.get(provider, 0)

    def without(self, records, provider):
        kept = [p for p in records.split(';') if '=' in p and p.index('=') > 0 and p[:p.index('=')] != provider]
        return ';' + ';'.join(kept) + ';' if kept else ''

    def valid(self, records):
        for part in records.split(';'):
            if '=' in part and part.index('=') > 0 and int(part[part.index('=') + 1:]) == self.epoch(part[:part.index('=')]):
                return True
        return False

    def keep(self, pin, provider):
        if provider == '' or pin is None or ';' in provider or '=' in provider:
            return False
        records = self.without(pin['by'], provider) or ';'
        pin['by'] = records + '%s=%d;' % (provider, self.epoch(provider))
        pin['keep'] = True
        return True

    def unkeep(self, pin, provider):
        if provider == '' or pin is None:
            return False
        pin['by'] = self.without(pin['by'], provider)
        pin['keep'] = pin['by'] != '' and self.valid(pin['by'])
        return True

    def late(self, pin):
        if not pin['keep']:
            return False
        if pin['by'] == '' or self.valid(pin['by']):
            return True
        pin['keep'] = False
        return False


def pin():
    return {'keep': False, 'by': ''}


class TextTests(unittest.TestCase):
    def test_property_49_is_known_and_makes_no_claim(self):
        self.assertIn('function CMFPropertyGridKeepEpoch() : int { return 49; }', CORE)
        self.assertIn('propertyId <= 49', ws_function(CORE, 'function CMFHasProperty('))
        body = ws_function(CORE, 'function CMFRegister(')
        branch = body.index('propertyId == CMFPropertyGridKeepEpoch()')
        self.assertLess(branch, body.index('if (!CMFHasProperty(propertyId))'))
        self.assertGreater(body.index('NoteProviderPresent(provider)'), -1)
        self.assertLess(body.index('NoteProviderPresent(provider)'), branch)
        piece = body[branch:body.index('if (!CMFHasProperty(propertyId))')]
        self.assertIn('SetGridKeepEpoch(provider, number)', piece)
        self.assertNotIn('Upsert', piece)

    def test_any_valid_keep_exempts_from_every_grid(self):
        body = ws_function(CORE, 'private function HideGridPins(')
        self.assertIn('GridPinKept(dataObject)', body)
        kept = ws_function(CORE, 'private function GridPinKept(')
        self.assertNotIn('owner', kept)
        self.assertNotIn('provider', kept.replace('GridKeepValid', ''))

    def test_bool_is_rewritten_from_the_keepers_in_the_late_pass(self):
        kept = ws_function(CORE, 'private function GridPinKept(')
        first = kept.index('GetMemberFlashBool("cmfGridKeep")')
        self.assertLess(first, kept.index('GetMemberFlashString("cmfGridKeepBy")'))
        self.assertIn('keepBy == "" || GridKeepValid(keepBy)', kept)
        self.assertIn('SetMemberFlashBool("cmfGridKeep", false)', kept[kept.index('GridKeepValid(keepBy)'):])

    def test_bad_provider_rejected_in_text(self):
        add = ws_function(CORE, 'public function GridKeepAdd(')
        self.assertIn('provider == "" || !dataObject || StrFindFirst(provider, ";") >= 0 || StrFindFirst(provider, "=") >= 0', add)
        self.assertIn('provider == "" || !dataObject', ws_function(CORE, 'public function GridKeepRemove('))

    def test_globals_call_the_core(self):
        self.assertIn('return theGame.CMFGetCore().GridKeepAdd(provider, dataObject);', ws_function(CORE, 'function CMFGridKeepPin('))
        self.assertIn('return theGame.CMFGetCore().GridKeepRemove(provider, dataObject);', ws_function(CORE, 'function CMFGridUnkeepPin('))

    def test_ability_keep_revoke(self):
        self.assertIn("if (part == 'grid' && key == 'keepRevoke') { return true; }", ws_function(CORE, 'function CMFHasAbility('))

    def test_keep_stays_full_list_only(self):
        self.assertEqual(CORE.count('HideGridPins(flashArray, area);'), 1)
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        at = fill.index('RemoveHiddenPins(flashArray, area, mapContext);')
        self.assertIn('if (fullList)', fill[:at][-80:])

    def test_debug_lines(self):
        self.assertIn('"grid keep epoch provider="', ws_function(CORE, 'public function SetGridKeepEpoch('))
        self.assertIn('"grid keep revoked n="', CORE)

    def test_records_are_parsed_without_str_split(self):
        # StrSplit is unproven on 5.01; the menu and the hide design use StrBeforeFirst / StrAfterFirst / StrSplitFirst.
        self.assertNotRegex(CORE, r'\bStrSplit\(')
        for head in ('public function GridKeepValid(', 'private function GridKeepWithout('):
            body = ws_function(CORE, head)
            self.assertIn('StrBeforeFirst(rest, ";")', body)
            self.assertIn('StrAfterFirst(rest, ";")', body)

    def test_epoch_default_is_zero(self):
        self.assertIn('return 0;', ws_function(CORE, 'public function GridKeepEpoch('))


class ModelTests(unittest.TestCase):
    def test_keep_records_provider_with_current_epoch(self):
        m, p = Model(), pin()
        m.epochs['A'] = 3
        self.assertTrue(m.keep(p, 'A'))
        self.assertTrue(p['keep'])
        self.assertEqual(p['by'], ';A=3;')
        m.epochs['A'] = 4
        m.keep(p, 'A')
        self.assertEqual(p['by'], ';A=4;')

    def test_keep_without_epoch_row_is_epoch_zero(self):
        m, p = Model(), pin()
        m.keep(p, 'B')
        self.assertEqual(p['by'], ';B=0;')
        self.assertTrue(m.valid(p['by']))
        m.epochs['B'] = 1
        self.assertFalse(m.valid(p['by']))

    def test_epoch_change_revokes_only_that_provider(self):
        m, p = Model(), pin()
        m.epochs['A'] = 3
        m.keep(p, 'A')
        m.keep(p, 'B')
        self.assertEqual(p['by'], ';A=3;B=0;')
        m.epochs['A'] = 4
        self.assertTrue(m.valid(p['by']))
        m.epochs['B'] = 1
        self.assertFalse(m.valid(p['by']))

    def test_unkeep_removes_only_own_record(self):
        m, p = Model(), pin()
        m.epochs['A'] = 3
        m.keep(p, 'A')
        m.keep(p, 'B')
        m.unkeep(p, 'A')
        self.assertEqual(p['by'], ';B=0;')
        self.assertTrue(p['keep'])
        m.unkeep(p, 'B')
        self.assertEqual(p['by'], '')
        self.assertFalse(p['keep'])

    def test_unkeep_with_nothing_to_remove_is_true(self):
        m, p = Model(), pin()
        self.assertTrue(m.unkeep(p, 'A'))
        self.assertFalse(p['keep'])

    def test_bad_provider_rejected(self):
        m, p = Model(), pin()
        for bad in ('', 'a;b', 'a=b'):
            self.assertFalse(m.keep(p, bad))
        self.assertFalse(m.unkeep(p, ''))
        self.assertFalse(m.keep(None, 'A'))

    def test_late_pass_rewrites_the_bool(self):
        m, p = Model(), pin()
        m.keep(p, 'A')
        self.assertTrue(m.late(p))
        m.epochs['A'] = 9
        self.assertFalse(m.late(p))
        self.assertFalse(p['keep'])

    def test_old_writer_bool_without_records_is_kept(self):
        m = Model()
        self.assertTrue(m.late({'keep': True, 'by': ''}))
        self.assertFalse(m.late({'keep': False, 'by': ';A=0;'}))

    def test_gear_keep_survives_a_fog_epoch_change(self):
        m, p = Model(), pin()
        m.keep(p, 'modWitcherGearMap')
        m.keep(p, 'modFogOfWar')
        m.epochs['modFogOfWar'] = 5
        self.assertTrue(m.late(p))


if __name__ == '__main__':
    unittest.main()
