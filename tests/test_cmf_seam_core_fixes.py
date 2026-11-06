"""Core seam fixes S4, S7 (sweep skip), S16, S19, S20 and the one-pin invariant line (API 18 release).

Source text checks; the findings are in docs/reviews/2026-11-04-seam-review/FINDINGS.md.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ws_text import core_text, ws_function

CORE = core_text()


class SeamCoreFixes(unittest.TestCase):
    def test_begin_build_drops_object_keyed_direct_offsets(self):
        self.assertIn('AnimationForgetObjects();', ws_function(CORE, 'public function BeginBuild('))
        forget = ws_function(CORE, 'private function AnimationForgetObjects(')
        self.assertIn('animationDirect', forget)
        self.assertIn('StrBeginsWith(animationDirect[i].pinKey, "object/")', forget)

    def test_withdraw_keeps_the_frame_offset_offer(self):
        # A layer's withdrawal must not drop the provider's property 47 offer, which the other layer still uses.
        self.assertNotIn('animationDirect', ws_function(CORE, 'private function AnimationWithdraw('))

    def test_added_pin_velen_alias_is_stored_as_novigrad(self):
        body = ws_function(CORE, 'public function UpsertAddedPin(')
        alias = body.index("if (pin.area == 'AN_Velen') { pin.area = 'AN_NMLandNovigrad'; }")
        self.assertGreater(alias, body.index("pin.area == 'AN_Undefined'"))
        self.assertLess(alias, body.index('addedPins.PushBack(pin)'))
        self.assertLess(alias, body.index('addedPins[i].area == pin.area'))

    def test_tint_range_checked_in_both_places(self):
        self.assertIn('if (propertyId == 3) { return number >= 0 && number <= 16777215; }',
                      ws_function(CORE, 'private function NewPinValueOk('))
        upsert = ws_function(CORE, 'public function Upsert(')
        self.assertIn('incoming.propertyId == 3 && (incoming.number < 0 || incoming.number > 16777215)', upsert)
        self.assertIn('reason=range', upsert)

    def test_sweep_skipped_without_marks_but_grid_still_runs(self):
        body = ws_function(CORE, 'private function RemoveHiddenPins(')
        skip = body.index('marksThisBuild == 0 && hideClaims.Size() == 0 && playerOwner == ""')
        self.assertLess(body.index('HideGridPins('), skip)
        self.assertLess(skip, body.index('for (i = flashArray.GetLength() - 1;'))
        self.assertIn('return;', body[skip:skip + 200])

    def test_mark_counter_reset_in_begin_build_and_catch(self):
        self.assertIn('marksThisBuild = 0;', ws_function(CORE, 'public function BeginBuild('))
        catch = ws_function(CORE, 'public function CatchLatePins(')
        self.assertLess(catch.index('marksThisBuild = 0;'), catch.index('FillMissingPinFields('))
        self.assertIn('marksThisBuild += 1;', ws_function(CORE, 'private function MarkHidden('))

    def test_late_step_flag_and_log_once(self):
        self.assertIn('lateStepRan = false;', ws_function(CORE, 'public function BeginBuild('))
        self.assertIn('NoteLateStep();', ws_function(CORE, 'function UpdateUserMapPins('))
        check = ws_function(CORE, 'public function CheckLateStep(')
        self.assertIn('!lateStepRan && !lateStepLogged', check)
        self.assertIn('late pin step skipped: another mod replaced UpdateUserMapPins; hides, added pins and drawings may be missing',
                      check)
        update = ws_function(CORE, 'function UpdateData(optional ignoreSelectionChange : bool)')
        self.assertGreater(update.index('CheckLateStep();'), update.index('EndBuild();'))

    def test_one_pin_non_user_logged_once(self):
        self.assertIn('!nonUserOneLogged', ws_function(CORE, 'public function FillMissingPinFields('))
        note = ws_function(CORE, 'private function NoteOnePinType(')
        self.assertIn('nonUserOneLogged = true;', note)
        self.assertIn('one-pin update carries a non-user pin type=', note)


if __name__ == '__main__':
    unittest.main()
