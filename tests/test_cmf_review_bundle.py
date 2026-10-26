"""Source checks for the CMF 1.5.0 review fixes (reviews/2026-10-25-cmf-1.5.0, Kyle's picks 2026-10-25).

Offline checks bound to the source text; the behaviour itself is checked in game.
"""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / 'source/core/content/scripts/local/cmfCore.ws'
MENU = ROOT / 'source/menu/content/scripts/local/cmfMenu.ws'
CHECK = ROOT / 'source/adapter-check/content/scripts/local/cmfAdapterCheck.ws'
EDITS = ROOT / 'source/panel/pin-fields/edits.json'
INK = ROOT / ('source/adapters/ink-and-iron/modCMFAdapterInkAndIron/content/scripts/local/'
              'modcmfadapterinkandiron_cmf.ws')
FOG = ROOT / 'source/adapters/fog-of-war/modCMFAdapterFogOfWar/content/scripts/local/zz_modcmfadapterfogofwar_cmf.ws'
MQI = ROOT / ('source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/'
              'zz_modcmfadaptermapquestinsight_cmf.ws')


def body(text, name):
    match = re.search(r'\bfunction ' + re.escape(name) + r'\([^{}]*\)\s*(?::\s*\w+)?\s*\{', text)
    assert match, 'missing ' + name
    depth = 1
    for pos in range(match.end(), len(text)):
        if text[pos] == '{':
            depth += 1
        elif text[pos] == '}':
            depth -= 1
            if not depth:
                return text[match.end():pos]
    raise AssertionError('unclosed ' + name)


class CoreReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text()

    def test_c1_a_pick_of_a_mod_that_sends_nothing_reads_automatic(self):
        allows = body(self.core, 'AnswerAllows')
        self.assertIn('answer == provider || !AnswerSends(choice, answer);', allows)
        sends = body(self.core, 'AnswerSends')
        self.assertIn('if (choice == 71)', sends)
        self.assertIn('styledOffers.Contains("71/" + provider)', sends)
        self.assertIn('if (choice == 35)', sends)
        self.assertIn('tabsHidden[i].provider == provider', sends)

    def test_c2_a_replaced_title_or_text_keeps_the_added_lines(self):
        self.assertIn('AppendInfoAdds(dataObject, pinKey, legendKey, pinTag, "");', body(self.core, 'WriteInfo'))
        self.assertIn('infoWritten = true;', body(self.core, 'WritePinInfo'))
        self.assertIn('AppendInfoAdds(dataObject, infoKey, infoLegend, infoTag, "label");', self.core)
        self.assertIn('AppendInfoAdds(dataObject, infoKey, infoLegend, infoTag, "description");', self.core)

    def test_c3_each_info_box_height_lookup_skips_every_pin_claims(self):
        self.assertIn('((Find(CMFPropertyInfoBoxHeight(), pinKey, pinTag, maxLevel, claim) && claim.level > 0) ||\n'
                      '\t\t\t(Find(CMFPropertyInfoBoxHeight(), legendKey, \'\', 1, claim) && claim.level > 0))', self.core)

    def test_c4_the_menu_shown_event_passes_its_result_on(self):
        shown = body(self.core, 'OnMenuShown')
        self.assertIn('result = wrappedMethod();', shown)
        self.assertTrue(shown.rstrip().endswith('return result;'))

    def test_c7_an_untagged_pin_without_an_id_is_told_apart_by_its_place(self):
        self.assertIn('pinKeyName += "@" + FloatToString(dataObject.GetMemberFlashNumber("posX"))', self.core)

    def test_q5_the_same_claim_again_leaves_the_winners_alone(self):
        self.assertRegex(self.core, r'if \(claims\[i\]\.text == incoming\.text && claims\[i\]\.number == incoming\.number\)'
                                    r'\s*\{\s*return true;\s*\}\s*incoming\.order = claims\[i\]\.order;')

    def test_o4_tag_claims_are_decided_by_the_pins_piece(self):
        self.assertRegex(self.core, r"if \(claims\[i\]\.level == 2 && claims\[i\]\.propertyId != CMFPropertyDisabled\(\) &&"
                                    r"\s*!CMFIsClickProperty\(claims\[i\]\.propertyId\)\)\s*\{\s*winners\.PushBack\(claims\[i\]\);")
        self.assertIn('(rank == bestRank && TagBeats(choice, winners[i], winners[best]))', self.core)
        beats = body(self.core, 'TagBeats')
        self.assertIn('return PieceBeats(choice, a.provider, b.provider);', beats)
        self.assertIn('return ProviderBeats(a.provider, b.provider);', beats)

    def test_legend_row_guard_keeps_a_game_row_with_an_undeclared_tab(self):
        self.assertIn('gamePinNow = true;\n\t\t\t\tWriteFields(dataObject, pinKey, pinKey, pinTag, CMFLevelPlace(), mapContext);'
                      '\n\t\t\t\tgamePinNow = false;', self.core)
        self.assertIn("gamePinNow && !CMFIsVanillaCategory(claim.text, false) &&\n\t\t\tCategoryIndex(claim.text) < 0", self.core)
        self.assertIn('CMFLog("legend row kept type=" + legendKey + " category=" + claim.text + " provider=" + claim.provider +\n'
                      '\t\t\t\t\t" reason=category");', self.core)
        self.assertIn('rowsKept.Clear();', body(self.core, 'Prepare'))


class PanelReviewTests(unittest.TestCase):
    def test_p1_and_p4_tooltip_keys(self):
        text = json.dumps(json.loads(EDITS.read_text()))
        self.assertIn('MapMenu.cmfStyle(\\"tooltip\\",\\"clearSide\\") == \\"left\\"', text)
        self.assertIn('_loc4_ - _loc1_ + MapMenu.cmfNum(\\"tooltip\\",\\"y\\",0)', text)


class AddOnReviewTests(unittest.TestCase):
    def test_m4_open_the_map_hint_before_the_first_opening(self):
        self.assertIn('if (text == "" && !core.MapSeen())', body(MENU.read_text(), 'CMFMenuFillMod'))

    def test_status_list_follows_the_deciding_order(self):
        menu = MENU.read_text()
        self.assertIn('CMFMenuInsertInOrder(core, combined, providers[i]);', body(menu, 'CMFMenuStatusProviders'))
        self.assertIn('if (core.ProviderBeats(provider, list[i]))', body(menu, 'CMFMenuInsertInOrder'))
        self.assertIn('if (index == 15 && providers.Size() > 16)', body(menu, 'CMFMenuFillMod'))

    def test_a2_a_warned_set_survives_a_later_empty_set(self):
        check = CHECK.read_text()
        run = body(check, 'CMFAdapterCheckRun')
        self.assertLess(run.index('if (signature == "" && theGame.cmfAdapterCheckWarned) { return; }'),
                        run.index("SetVarValue('CMFAdapterCheck', 'CMFAdapterCheckKnown', signature);"))
        self.assertIn('theGame.CMFAdapterCheckSetWarned();', run)
        self.assertIn('CMFLog("adapter check missing mod=" + missing[i].modName + " adapter=" + missing[i].adapterFolder);', run)


class AdapterReviewTests(unittest.TestCase):
    def test_i2_clear_cursor_waits_for_the_larger_clear_area(self):
        ink = INK.read_text()
        self.assertRegex(ink, r"if \(CMFHasAbility\('tooltip', 'clearCursorAbove'\)\)\s*\{\s*"
                              r"CMFStylePart\(\"modInkAndIronUI\", 'tooltip', 'clearCursor', \"\", 70\);\s*\}")

    def test_q3_and_f1_no_per_pin_log_lines(self):
        self.assertNotIn('mqiAdapterLogged', MQI.read_text())
        self.assertNotIn('CMFLog(', FOG.read_text())


if __name__ == '__main__':
    unittest.main()
