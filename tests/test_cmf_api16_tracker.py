"""API 16: a third glow, the tracker's questPlate hide word, and the tracker's glows on its row clips."""
import json
import re
import unittest
from pathlib import Path
from test_cmf_review_bundle import body

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")
EDITS = json.loads((ROOT / "source/panel/pin-fields/edits.json").read_text(encoding="utf-8"))["classes"]
LIST = EDITS["red/game/witcher3/menus/worldmap/MapMenu.as"]
FIRST = next((i for i, e in enumerate(LIST) if "while(n <= 3)" in e["replace"]), len(LIST))
# The earlier edits' replace text still holds what the API 16 edits rewrite, so read it as they leave it.
MENU = "".join(e["replace"] for e in LIST[:FIRST] + LIST[FIRST + 3:])
for _e in LIST[FIRST:FIRST + 3]:
    MENU = MENU.replace(_e["find"], _e["replace"])


def func(name):
    start = MENU.index("function %s(" % name)
    return MENU[start:MENU.index("\n      }\n", start)]


class Api16Tracker(unittest.TestCase):
    def test_api_is_17(self):
        self.assertIn("function CMFGetVersion() : int { return 18; }", CORE)

    def test_third_glow_keys(self):
        self.assertTrue(body(CORE, "CMFThemeGlowKeys").rstrip().endswith('glow3Color,glow3Alpha,glow3Blur,glow3Strength";'))

    def test_tracker_quest_plate_word(self):
        words = body(CORE, "CMFThemeHideWords")
        self.assertRegex(words, r"case 'tracker':\s*return \"plate,questPlate\";")
        self.assertRegex(words, r"case 'worldButton':\s*case 'worldHint':\s*return \"plate\";")

    def test_tracker_takes_glow3(self):
        self.assertIn('return CMFThemeGlowKeys() + ",nameFont,nameSize,nameColor,hide,x,y,scale,show";', body(CORE, "CMFThemePartKeys"))


class TrackerGlowTests(unittest.TestCase):
    def test_glows_read_three(self):
        self.assertIn("while(n <= 3)", func("cmfGlows"))
        self.assertNotIn("while(n <= 2)", func("cmfGlows"))

    def test_tracker_glows_go_on_row_clips(self):
        self.assertIn("this.cmfGlowClip(o as DisplayObject,\"tracker\",glows)", MENU)
        self.assertIn("this.cmfGlowClip(this.mcQTButtons,\"tracker\",glows)", MENU)
        self.assertNotIn("cmfGlowText(this.mcHubMapQuestTracker", MENU)
        self.assertNotIn("cmfGlowText(this.mcQTButtons", MENU)

    def test_tracker_clip_glows_are_undone_only_where_cmf_set_them(self):
        body = func("cmfUnglowClip")
        self.assertRegex(body, r"if\(this\._cmfGlowed\[param1\] === param2\)\s*\{\s*param1\.filters = \[\];")
        self.assertIn("delete this._cmfGlowed[param1];", body)
        self.assertIn("(!param1.filters || param1.filters.length == 0)", func("cmfGlowClip"))
        self.assertIn("this._cmfGlowed[param1] = param2;", func("cmfGlowClip"))

    def test_tracker_glow_runs_in_the_theme_apply_loop(self):
        body = func("cmfStyleParts")
        loop = body[body.index("while(k < this.mcHubMapQuestTracker.numChildren)"):]
        loop = loop[:loop.index("MapMenu.cmfHideChild(this.mcQTButtons")]
        self.assertIn("MapMenu.cmfHideChild(o,\"mcBackground\")", loop)
        self.assertIn("this.cmfGlowClip(o as DisplayObject,\"tracker\",glows)", loop)

    def test_other_parts_keep_text_glows(self):
        self.assertIn("this.cmfGlowText(o as DisplayObject,\"legendRow\",glows,0)", MENU)
        self.assertIn('this.cmfGlowText(this.mcGotoWorldMap,"worldHint",glows,0)', MENU)
        self.assertIn("this.cmfHintCopy.filters = glows;", MENU)  # hints glow on their copy's filters, never through cmfGlowText

    def test_quest_plate_is_the_narrower_word(self):
        # "plate" keeps its API 15 meaning (quest boxes and the key row plate); "questPlate" hides the quest boxes only.
        self.assertIn('if(MapMenu.cmfHides("tracker","plate") || MapMenu.cmfHides("tracker","questPlate"))', MENU)
        self.assertRegex(MENU, r'if\(MapMenu\.cmfHides\("tracker","plate"\)\)\s*\{\s*MapMenu\.cmfHideChild\(this\.mcQTButtons,"mcBackground"\);')
        self.assertNotIn('cmfHides("tracker","questPlate")) {', MENU)
        self.assertNotRegex(MENU, r'cmfHides\("tracker","questPlate"\)\)\s*\{\s*MapMenu\.cmfHideChild\(this\.mcQTButtons')


if __name__ == "__main__":
    unittest.main()
