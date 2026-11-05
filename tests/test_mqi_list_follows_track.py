"""MQI quest list follows the tracked quest from any route (plain unittest, text checks)."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QL = ROOT / 'source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/zz_modcmfadaptermapquestinsight_questlist.ws'
TEXT = QL.read_text()


def body(header):
    start = TEXT.index(header)
    i = TEXT.index('{', start)
    depth = 0
    for j in range(i, len(TEXT)):
        if TEXT[j] == '{':
            depth += 1
        elif TEXT[j] == '}':
            depth -= 1
            if depth == 0:
                return TEXT[i + 1:j]
    raise AssertionError(header)


class ListFollowsTrack(unittest.TestCase):
    def test_key_reads_tracked_quest_and_objective_null_safe(self):
        b = body('function MqiAdapterQlTrackKey()')
        self.assertIn('theGame.GetJournalManager()', b)
        self.assertIn('GetTrackedQuest()', b)
        self.assertIn('GetHighlightedObjective()', b)
        self.assertEqual(len(re.findall(r'if \((trackedQuest|objective)\)', b)), 2)
        self.assertIn('GetUniqueScriptTag()', b)

    def test_send_records_the_key_it_sent(self):
        self.assertRegex(body('function MqiAdapterQlSend()').rstrip(), r'MqiAdapterQlNoteTracked\(\);$')
        self.assertIn('mqiAdapterQlTrackKey = MqiAdapterQlTrackKey();', body('function MqiAdapterQlNoteTracked()'))

    def test_update_data_wrapper_resends_once_when_the_key_changed(self):
        self.assertIn('@wrapMethod(CR4MapMenu)\nfunction UpdateData(optional ignoreSelectionChange : bool)', TEXT)
        b = body('function UpdateData(')
        self.assertLess(b.index('wrappedMethod(ignoreSelectionChange);'), b.index('MqiAdapterQlTrackChanged()'))
        self.assertIn('mqiAdapterQlOn && !mqiAdapterQlOwnTrack && MqiAdapterQlTrackChanged()', b)
        self.assertEqual(TEXT.count('function UpdateData('), 1)
        c = body('function MqiAdapterQlTrackChanged()')
        self.assertIn('mqiAdapterQlSeq > 0', c)
        self.assertIn('mqiAdapterQlTrackKey != MqiAdapterQlTrackKey()', c)

    def test_area_ready_has_no_track_branch_and_own_track_is_flagged(self):
        self.assertNotIn('else if (menu.MqiAdapterQlTrackChanged())', TEXT)
        self.assertRegex(TEXT, r'mqiAdapterQlOwnTrack = true;\n\s*OnTrackQuest\([^\n]*\n\s*mqiAdapterQlOwnTrack = false;')
        self.assertRegex(TEXT, r'mqiAdapterQlOwnTrack = true;\n\s*OnHighlightObjectiveWithQuestChange\([^\n]*\n\s*mqiAdapterQlOwnTrack = false;')

    def test_reset_per_opening_and_existing_early_sends_kept(self):
        self.assertIn('mqiAdapterQlTrackKey = "";', body('function OnConfigUI()'))
        self.assertEqual(len(re.findall(r'MqiAdapterQlSend\(\);', TEXT)), 9)  # eight early/other sends + the UpdateData wrapper's

    def test_no_clock_reads(self):
        self.assertNotIn('GetEngineTime', TEXT)

    def test_clean_text(self):
        TEXT.encode('ascii')
        self.assertNotIn('\r', TEXT)


if __name__ == '__main__':
    unittest.main()
