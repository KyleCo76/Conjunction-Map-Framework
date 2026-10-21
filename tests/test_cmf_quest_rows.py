"""Quest rows (API version 6): a legend row claim on a quest pin's filteredType gives those quest pins a row of
their own instead of the shared quest row, as All Quest Objectives' map file does for QuestObjectiveOther.

Static checks only; nothing here has run in game. The ask is plans/aqo-adapter/ability-needs-frames-and-legend.md
section 3.3 (project files).
"""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
GUIDE = ROOT/'docs/authors/icon-pack-guide.md'


def replaced(cls):
    data = json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/menus/worldmap/' + cls]
    return ''.join(e['replace'] for e in data)


def write_fields(core):
    start = core.index('\tprivate function WriteFields(')
    return core[start:core.index('\n\t}', start)]


class QuestRowTests(unittest.TestCase):
    def test_core_writes_the_row_claim_on_quest_pins(self):
        # WriteFields has no quest test before the row claim, so cmfLegendPriority reaches quest pins.
        fields = write_fields(CORE.read_text(encoding='ascii'))
        row = fields.index('if (Find(CMFPropertyLegendRow(), legendKey')
        self.assertNotIn('isQuest', fields[:row])
        self.assertIn('dataObject.SetMemberFlashInt("cmfLegendPriority", LegendPriority(claim.number));', fields)

    def test_legend_lists_claimed_quest_pins_in_their_own_row(self):
        panel = replaced('HubMapPinPanel.as')
        self.assertIn('return param1.cmfLegendPriority > 0 ? param1.filteredType : QUEST_PIN_TYPE;', panel)
        self.assertIn('if(param1.isQuest && param1.cmfLegendPriority > 0)\n            {\n', panel)
        self.assertIn('_loc8_ = param1.cmfLegendPriority;\n               if(!param1.cmfLegendLabel)\n'
                      '               {\n                  _loc6_ = QUEST_PIN_TRANSLATION;', panel)
        self.assertIn('else if(param1.isQuest)\n            {\n               _loc5_ = QUEST_PIN_TYPE;\n', panel)

    def test_both_quest_hide_tests_use_the_row_key(self):
        hub = replaced('HubMap.as')
        self.assertEqual(hub.count('HubMapPinPanel.cmfQuestRow(_loc10_)'), 2)
        self.assertIn('else if(_loc10_.isQuest && _loc10_.cmfLegendPriority > 0)', hub)
        self.assertIn('_loc10_.isQuest && param4 && !param5.hasOwnProperty(HubMapPinPanel.cmfQuestRow(_loc10_))', hub)

    def test_guide_states_the_rule(self):
        guide = GUIDE.read_text(encoding='utf-8')
        self.assertIn('- **Quest rows (API version 6).**', guide)
        self.assertIn("CMFRegisterLegendRow(p, 'QuestObjectiveOther', 'Quests', 200)", guide)


if __name__ == '__main__':
    unittest.main()
