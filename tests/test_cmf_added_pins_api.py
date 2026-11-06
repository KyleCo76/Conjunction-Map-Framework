"""Added pins list (API 18): the session table of pin types mods add, its readers and the author guide.

Reads the sources as text; only a start proves the lists in game.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ws_text import ROOT, core_text, ws_function

CORE = core_text()
GUIDE = (ROOT / 'docs/authors/icon-pack-guide.md').read_text(encoding='utf-8')


class TableTests(unittest.TestCase):
    def test_struct_holds_no_flash_objects(self):
        body = ws_function(CORE, 'struct SCMFAddedPinType')
        fields = [l.strip() for l in body.splitlines() if l.strip().startswith('var ')]
        self.assertEqual(fields, ['var provider : string;', 'var pinType : string;', 'var filteredType : string;',
                                  'var count : int;', 'var declared : bool;'])
        self.assertNotIn('CScriptedFlash', body)

    def test_tally_only_on_full_list_and_only_group_7(self):
        body = ws_function(CORE, 'public function FillMissingPinFields(')
        at = body.index('NoteAddedPinType(')
        guard = body[body.rindex('if (', 0, at):at]
        self.assertIn('fullList', guard)
        self.assertIn('PinGroupOf(pinType) == 7', guard)
        self.assertIn('IsDeclaredAddedType(pinType)', guard)
        self.assertLess(at, body.index('RemoveHiddenPins('))
        # the pin loop only reaches player and user pins through the not-player-not-user branch
        self.assertLess(body.index('if (!isPlayer && !isUser && !dataObject.GetMemberFlashBool("cmfDone"))'), at)

    def test_counts_reset_at_build_start(self):
        self.assertIn('ResetAddedPinCounts();', ws_function(CORE, 'public function BeginBuild('))
        self.assertNotIn('addedTypes.Clear()', CORE)

    def test_owner_order(self):
        body = ws_function(CORE, 'private function AddedTypeOwner(')
        order = [body.index('addedTypes[at].declared'), body.index('NameToString(addedPins[i].pinType) == pinType'),
                 body.index('claims[i].propertyId == CMFPropertyLegendRow()'),
                 body.rindex('NameToString(claims[i].pinType) == pinType'), body.rindex('NameToString(claims[i].pinType) == filtered'),
                 body.index('return "";', body.rindex('claims[i].provider;'))]
        self.assertEqual(order, sorted(order))

    def test_a_legend_row_definer_beats_an_icon_claimer(self):
        body = ws_function(CORE, 'private function AddedTypeOwner(')
        tier = body[body.index('claims[i].propertyId == CMFPropertyLegendRow()'):body.rindex('NameToString(claims[i].pinType) == pinType')]
        self.assertIn('claims[i].level == 1', body[:body.index('claims[i].propertyId == CMFPropertyLegendRow()')][-80:])
        self.assertIn('== filtered', tier)
        self.assertIn('== pinType', tier)

    def test_owner_refreshed_each_full_build(self):
        body = ws_function(CORE, 'private function NoteAddedPinType(')
        self.assertIn('first = addedTypes[at].count == 0;', body)
        self.assertIn('if (first && addedTypes[at].provider == "")', body)
        self.assertIn('AddedTypeOwner(', body[body.index('if (first && addedTypes[at].provider == "")'):])

    def test_no_list_scan_per_pin(self):
        # Review M4: a count of declared types and a memo of the last type keep the per-pin path to string tests.
        declared = ws_function(CORE, 'private function IsDeclaredAddedType(')
        self.assertLess(declared.index('declaredAddedTypes == 0'), declared.index('AddedTypeIndex('))
        index = ws_function(CORE, 'private function AddedTypeIndex(')
        self.assertLess(index.index('pinType == addedLastType'), index.index('for ('))
        self.assertIn('declaredAddedTypes += 1;', ws_function(CORE, 'public function DeclareAddedPinType('))


class PublicTests(unittest.TestCase):
    def test_public_signatures(self):
        for line in ('function CMFAddedPinMods(out mods : array<string>) : int',
                     'function CMFAddedPinTypes(mod : string, out types : array<string>, out rows : array<string>, out counts : array<int>) : int',
                     'function CMFDeclareAddedPinType(provider : string, pinType : name, filteredType : name) : bool'):
            self.assertIn(line, CORE)

    def test_ability_and_version(self):
        self.assertIn("if (part == 'pins' && key == 'addedList') { return true; }", ws_function(CORE, 'function CMFHasAbility('))
        self.assertIn('function CMFGetVersion() : int { return 19; }', CORE)

    def test_outputs_cleared_first(self):
        mods = ws_function(CORE, 'public function AddedPinMods(')
        self.assertLess(mods.index('mods.Clear();'), mods.index('PushBack'))
        types = ws_function(CORE, 'public function AddedPinTypesOf(')
        for name in ('types', 'rows', 'counts'):
            self.assertLess(types.index(name + '.Clear();'), types.index('PushBack'))

    def test_unowned_listed_last(self):
        body = ws_function(CORE, 'public function AddedPinMods(')
        self.assertGreater(body.rindex('mods.PushBack("");'), body.index('for ('))
        self.assertGreater(body.index('if (unowned)'), body.index('mods.PushBack(addedTypes[i].provider);'))

    def test_declare_rejects_bad_input_and_notes_presence(self):
        body = ws_function(CORE, 'public function DeclareAddedPinType(')
        self.assertIn('provider == "" || !IsNameValid(pinType)', body)
        self.assertIn('NoteProviderPresent(provider);', body)
        self.assertIn('return false;', body[:body.index('NoteProviderPresent')])

    def test_debug_lines_capped(self):
        body = ws_function(CORE, 'private function LogAddedPins(')
        self.assertIn('"added pins mods="', body)
        self.assertIn('"added pins mod="', body)
        self.assertIn('i < 10', body)
        self.assertIn('j < 8', body)
        fill = ws_function(CORE, 'public function FillMissingPinFields(')
        self.assertLess(fill.index('debugTiming && addedTypes.Size() > 0'), fill.index('LogAddedPins();'))


class GuideTests(unittest.TestCase):
    def test_guide_documents_calls(self):
        at = GUIDE.index('### Pins other mods add (API version 18)')
        text = GUIDE[at:GUIDE.index('\n### ', at + 5)]
        for needle in ('CMFAddedPinMods', 'CMFAddedPinTypes', 'CMFDeclareAddedPinType', "CMFHasAbility('pins', 'addedList')",
                       'version 18', "game's own type names", 'session', 'region'):
            self.assertIn(needle, text)


if __name__ == '__main__':
    unittest.main()
