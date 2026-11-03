"""API 15: the map and the frames are separate choices, and panel visibility is behaviour (Panel visibility)."""
import json
import re
import unittest
from pathlib import Path
from types import SimpleNamespace as Obj
from ws_contract_runner import Array, bind
from test_cmf_review_bundle import body

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")
EDITS = json.loads((ROOT / "source/panel/pin-fields/edits.json").read_text(encoding="utf-8"))["classes"]
MENU = EDITS["red/game/witcher3/menus/worldmap/MapMenu.as"]
KEYS = "".join(re.findall(r'"([^"]*)"', body(CORE, "CMFChoiceKeys"))).split(",")


def entry(kind, target, provider, key="", anchor=""):
    return Obj(kind=kind, target=target, provider=provider, key=key, anchor=anchor)


PIECES = {("tooltip", "clearMinHeight"): 63, ("tooltip", "x"): 63, ("tooltip", "foldOpen"): 74, ("tracker", "show"): 75}


def left_out(entries, drawing, root, owners):
    """owners: {(part, key): winner}. Returns (left out, winner). Look piece of a panel: 41 for the tooltip, 39 else."""
    env = dict(themeEntries=Array(entries), DrawingRoot=lambda id: root,
               ThemeStyleOwner=lambda part, key: owners.get((part, key), ""),
               PartKeyChoice=lambda part, key: PIECES.get((part, key), 41 if part == "tooltip" else 39),
               ThemeLookChoice=lambda part: 41 if part == "tooltip" else 39)
    env["PanelPart"] = bind(CORE, "PanelPart", env, ("part",))
    run = bind(CORE, "PanelDrawingLeftOut", env, ("entryValue", "owner"), out_indices=(1,))
    return run(drawing, "")


class MapFeatureTests(unittest.TestCase):
    def test_map_feature_is_appended_and_area_answers_it(self):
        self.assertEqual(KEYS[80:], ["Map"])
        self.assertEqual(KEYS[44], "Movement_Area")
        self.assertRegex(body(CORE, "CMFChoiceParent"), r"choice == 44\)\s*\{\s*return 80;")
        self.assertIn("return 62;", body(CORE, "CMFChoiceParent"))  # Behaviour keeps its three
        self.assertIn("function CMFGetVersion() : int { return 17; }", CORE)

    def test_the_map_part_incl_backdrop_belongs_to_movement_area(self):
        look = body(CORE, "ThemeLookChoice")
        self.assertIn("if (part == 'map') { return 44; }", look)
        self.assertIn("part == 'crosshair' || part == 'edgePointer'", look)
        keychoice = body(CORE, "PartKeyChoice")
        self.assertNotIn("backdrop", keychoice)
        self.assertRegex(body(CORE, "PartChoice"), r"case 'map':\s*return 44; // Movement_Area")

    def test_frames_keep_the_rest(self):
        part = body(CORE, "PartChoice")
        self.assertRegex(part, r"case 'tracker':[^;]*?return 39; // Look_Frames")


class PanelDrawingTests(unittest.TestCase):
    def test_drawing_on_a_styled_panel_goes_when_another_look_wins(self):
        entries = [entry(1, "tracker", "modInk", "x"), entry(2, "inkBox", "modInk", "rect", "tracker")]
        gone, owner = left_out(entries, entries[1], "tracker", {("tracker", "x"): "modMqi"})
        self.assertTrue(gone)
        self.assertEqual(owner, "modMqi")

    def test_vanilla_winning_leaves_it_out_too(self):
        entries = [entry(1, "tracker", "modInk", "x"), entry(2, "inkBox", "modInk", "rect", "tracker")]
        self.assertEqual(left_out(entries, entries[1], "tracker", {}), (True, "vanilla"))

    def test_own_look_keeps_the_drawing(self):
        entries = [entry(1, "tracker", "modInk", "x"), entry(2, "inkBox", "modInk", "rect", "tracker")]
        self.assertEqual(left_out(entries, entries[1], "tracker", {("tracker", "x"): "modInk"})[0], False)

    def test_a_panel_it_does_not_style_keeps_the_drawing(self):
        entries = [entry(1, "title", "modInk", "x"), entry(2, "inkBox", "modInk", "rect", "tracker")]
        self.assertEqual(left_out(entries, entries[1], "tracker", {("tracker", "x"): "modMqi"})[0], False)

    def test_only_look_keys_tie_a_drawing_to_the_look(self):
        # Ink and Iron styles the info box's look and draws its frame; Map Quest Insight wins only its placement.
        entries = [entry(1, "tooltip", "modInk", "clearMinHeight"), entry(2, "inkBox", "modInk", "rect", "tooltip")]
        owners = {("tooltip", "clearMinHeight"): "modMqi"}
        self.assertEqual(left_out(entries, entries[1], "tooltip", owners)[0], False)
        # The first entry is a non-look key, a later one is the look key that Ink and Iron lost: the drawing goes.
        entries = [entry(1, "tooltip", "modInk", "x"), entry(1, "tooltip", "modInk", "titleColor"),
                   entry(3, "inkBox", "modInk", "rect", "tooltip")]
        self.assertEqual(left_out(entries, entries[2], "tooltip", {("tooltip", "titleColor"): "modMqi"}),
                         (True, "modMqi"))
        # A tracker show key (Panel visibility) alone does not tie the drawing either.
        entries = [entry(1, "tracker", "modMqi", "show"), entry(2, "box", "modMqi", "rect", "tracker")]
        self.assertEqual(left_out(entries, entries[1], "tracker", {("tracker", "show"): "modOther"})[0], False)

    def test_map_space_and_pin_drawings_are_not_panel_drawings(self):
        entries = [entry(1, "map", "modInk", "top"), entry(2, "line", "modInk", "line", "mapSpace")]
        self.assertEqual(left_out(entries, entries[1], "mapSpace", {})[0], False)
        self.assertEqual(left_out(entries, entries[1], "pin", {})[0], False)

    def test_log_line_and_wiring(self):
        theme = body(CORE, "SendTheme")
        self.assertIn("PanelDrawingLeftOut(themeEntries[i], owner)", theme)
        self.assertIn('" reason=panel by=" + owner', theme)
        panel = body(CORE, "PanelPart")
        for part in ("tracker", "title", "preview", "worldButton", "worldHint", "markerPanel", "screen", "mapEdge",
                     "legend", "legendRow", "legendTab", "tooltip", "hints"):
            self.assertIn("part == '%s'" % part, panel)


class PanelVisibilityTests(unittest.TestCase):
    def test_show_keys_sit_on_panel_visibility(self):
        keychoice = body(CORE, "PartKeyChoice")
        for part in ("tracker", "title", "worldButton", "worldHint", "crosshair", "edgePointer"):
            self.assertIn("case '%s':" % part, keychoice)
        self.assertRegex(keychoice, r"if \(key == 'show'\) \{ return 75; \}\s*break;\s*case 'pinLabel'")

    def test_each_part_lists_and_validates_show(self):
        keys = body(CORE, "CMFThemePartKeys")
        self.assertIn('hide,x,y,scale,show";', keys)  # tracker
        self.assertEqual(len(re.findall(r",show[,\"]", keys)), 7)
        ok = body(CORE, "CMFThemeValueOk")
        self.assertIn('part == \'tracker\' && key == \'show\') { return text == "always" || text == "nokeys" || text == "never"; }', ok)
        self.assertIn('return text == "always" || text == "never";', ok)

    def test_keys_word_left_the_look_hide_key(self):
        words = body(CORE, "CMFThemeHideWords")
        self.assertNotIn("keys", words)
        self.assertNotIn("hideKeys", CORE)
        self.assertRegex(words, r"case 'worldButton':\s*case 'worldHint':\s*return \"plate\";")

    def test_panel_hides_and_restores_by_show(self):
        text = "".join(e["replace"] for e in MENU)
        apply = text[text.index("protected function cmfPanelShowApply()"):]
        apply = apply[:apply.index("\n      }\n")]
        self.assertIn('tracker != "nokeys"', apply)
        self.assertIn("this.cmfModeClip(this.mcQTButtons,", apply)
        for clip in ("mcHubMapQuestTracker", "mapName", "mcWorldMapButton", "mcGotoWorldMap"):
            self.assertIn("this.%s" % clip, apply)
        self.assertIn("this._cmfPreviewState);\n         this.cmfPanelShowApply();\n      }", text)
        self.assertIn('MapMenu.cmfStyle(part,"show") == "never"', text)
        self.assertNotIn("_cmfKeysHidden", text)

    def test_mqi_sends_the_behaviour_key(self):
        adapter = (ROOT / "source/adapters/map-quest-insight/modCMFAdapterMapQuestInsight/content/scripts/local/"
                   "zz_modcmfadaptermapquestinsight_cmf.ws").read_text(encoding="utf-8")
        hud = body(adapter, "MqiAdapterSendCornerHud")
        self.assertIn("MqiAdapterMotion('tracker', 'hide', \"plate\", 0);", hud)
        # Round 2: Clean sends the key row hiding ungated (as MQI 2.2.0 alone shows it).
        self.assertIn("MqiAdapterMotion('tracker', 'show', \"nokeys\", 0);", hud)
        self.assertNotIn("MqiAdapterNextUpdate()", hud)
        self.assertNotIn("keys\"", hud.replace('"nokeys"', ""))


if __name__ == "__main__":
    unittest.main()
