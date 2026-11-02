"""The cover shown before the first grid: the core flags a kept grid, the panel covers the tiles from its first frame."""
import json
import unittest
from pathlib import Path
from test_cmf_review_bundle import body
ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT / "source/core/content/scripts/local/cmfCore.ws").read_text(encoding="utf-8")
CLASSES = json.loads((ROOT / "source/panel/pin-fields/edits.json").read_text(encoding="utf-8"))["classes"]
MENU = CLASSES["red/game/witcher3/menus/worldmap/MapMenu.as"]
SPACE = MENU[40]["replace"]
GRID = next(e for e in MENU if "private function cmfDrawGrids(" in e["replace"])["replace"]


class CoverCoreTests(unittest.TestCase):
    def test_flag_is_set_at_the_picture_name_and_again_at_the_build(self):
        names = body(CORE, "GetShownMapName")
        self.assertIn('SendCover(GetMenuFlash(), m_shownArea, "picture")', names)
        self.assertLess(names.index("SendCover("), names.index("return theGame.CMFGetCore().MapImageRoot"))
        data = body(CORE, "UpdateData")
        self.assertLess(data.index('SendCover(GetMenuFlash(), m_shownArea, "data")'), data.index("SendSpaceEarly("))

    def test_flag_needs_a_kept_grid_for_this_area_and_no_change_since(self):
        send = body(CORE, "SendCover")
        for line in ("!coverKnown || coverArea != area", "!spaceEarlyOk || dirty", "cmfCoverFill", "cmfCoverAlpha",
                     "cover skipped reason=no menu flash", "cover skipped reason=no kept grid", "cover skipped reason=changed",
                     "cover set area="):
            self.assertIn(line, send)

    def test_first_opening_takes_a_declared_grid_before_any_build(self):
        # 1.8.0 release check: the first opening after a load had no kept grid, so no cover, and the bare map showed.
        send = body(CORE, "SendCover")
        self.assertIn("if (!spaceBuiltOnce)", send)
        self.assertLess(send.index("RememberCover(area)"), send.index("!coverKnown || coverArea != area"))
        self.assertIn('" declared at="', send)
        space = body(CORE, "SendSpaceMode")
        self.assertLess(space.index("spaceBuiltOnce = true;"), space.index("RememberCover(area);"))

    def test_cover_colour_comes_from_the_grid_keys(self):
        remember = body(CORE, "RememberCover")
        for line in ("== 'grid'", "'fill'", "'alpha'", "coverFill = 0", "coverAlpha = 1", "kind == 3"):
            self.assertIn(line, remember)
        self.assertIn("RememberCover(area)", body(CORE, "SendSpaceMode"))
        self.assertLess(body(CORE, "SendSpaceMode").index("spaceEarlyOk = true"), body(CORE, "SendSpaceMode").index("RememberCover(area)"))


class CoverPanelTests(unittest.TestCase):
    def test_watch_starts_with_the_movie(self):
        early = SPACE[SPACE.index("private function cmfCoverEarly"):SPACE.index("public function get cmfCoverFill")]
        self.assertIn("Event.ENTER_FRAME,this.cmfCoverFrame", early)
        self.assertIn("private var _cmfCoverEarly:int = this.cmfCoverEarly();", SPACE)
        create = SPACE[SPACE.index("protected function cmfCreateSpace"):SPACE.index("// The painting (mcLodContainer) is held")]
        self.assertNotIn("cmfCoverFrame", create)

    def test_core_says_none_so_the_held_painting_returns(self):
        send = body(CORE, "SendCover")
        self.assertGreaterEqual(send.count('SetMemberFlashNumber("cmfCoverFill", -1)'), 2)
        self.assertLess(send.index('SetMemberFlashNumber("cmfCoverAlpha", coverAlpha)'), send.index('SetMemberFlashNumber("cmfCoverFill", coverFill)'))
        setter = SPACE[SPACE.index("public function set cmfCoverFill"):SPACE.index("public function get cmfCoverAlpha")]
        self.assertIn('this.cmfCoverRemove("none")', setter)


    def test_cover_sits_over_the_tiles_and_is_bounded(self):
        frame = SPACE[SPACE.index("private function cmfCoverStart"):SPACE.index("private function cmfCoverRemove")]
        self.assertIn("this.mcHubMap.addChildAt(this._cmfCover,this.mcHubMap.getChildIndex(zoom) + 1)", frame)
        self.assertIn("now >= this.cmfHoldMs()", frame)
        self.assertIn('cmfCoverRemove("timeout")', frame)
        self.assertIn("this._cmfCoverFillValue >= 0", frame)

    def test_painting_is_held_from_the_moment_the_core_writes_the_flag(self):
        setter = SPACE[SPACE.index("public function set cmfCoverFill"):SPACE.index("public function get cmfCoverAlpha")]
        self.assertIn("this.cmfCoverStart()", setter)
        start = SPACE[SPACE.index("private function cmfCoverStart"):SPACE.index("private function cmfPaintHold")]
        self.assertLess(start.index("addChildAt(this._cmfCover"), start.index("this.cmfPaintHold()"))
        hold = SPACE[SPACE.index("private function cmfPaintHold"):SPACE.index("private function cmfCoverFrame")]
        self.assertIn("mcLodContainer", hold)
        self.assertIn("lod.visible = false", hold)
        self.assertNotIn("alpha", hold, "the game's fade-in tweens alpha, so the hold uses visible")
        frame = SPACE[SPACE.index("private function cmfCoverFrame"):SPACE.index("private function cmfCoverRemove")]
        self.assertIn("this.cmfPaintHold()", frame)

    def test_painting_returns_in_the_frame_the_cover_goes(self):
        remove = SPACE[SPACE.index("private function cmfCoverRemove"):SPACE.index("protected function cmfSpaceReady")]
        self.assertLess(remove.index("lod.visible = true"), remove.index("removeChild(this._cmfCover)"))
        self.assertIn('"paint held ms="', remove)

    def test_removed_by_the_first_grid_or_when_none_comes(self):
        draws = GRID[GRID.index("private function cmfDrawGrids("):]
        self.assertIn('this.cmfCoverRemove("nogrid")', draws)
        self.assertIn("this._cmfCoverWantGrid = true;", draws)
        self.assertNotIn('this.cmfCoverRemove("grid")', draws[:draws.index("private function cmfGridFrame")] if "private function cmfGridFrame" in draws else draws)
        remove = SPACE[SPACE.index("private function cmfCoverRemove"):SPACE.index("protected function cmfSpaceReady")]
        self.assertIn('"cover shown ms="', remove)
        for field in ('" removed ms="', '" reason="'):
            self.assertIn(field, remove)


    def test_hold_waits_longer_once_the_core_asks_for_a_cover(self):
        # 1.8.0 release check: with Ink and Iron the map took 1.5 to 1.65 s to open, so a 1.5 s bound dropped the cover
        # just before the fog arrived and the bare painting showed.
        bound = SPACE[SPACE.index("private function cmfHoldMs"):SPACE.index("private function cmfCoverFrame")]
        self.assertIn("return this._cmfCoverFillValue >= 0 ? 4000 : 1500;", bound)


class FogReleaseAndCloseTests(unittest.TestCase):
    def frame(self):
        return GRID[GRID.index("private function cmfGridFrame"):GRID.index("// Marching squares over the cell centres")]

    def test_painting_returns_only_when_the_fog_is_on_stage_with_alpha(self):
        frame = self.frame()
        self.assertIn("settled && this._cmfGridLayer.stage && this._cmfGridLayer.alpha > 0 && this._cmfGridLayer.alpha >= container.mcLodContainer.alpha", frame)
        self.assertLess(frame.index("settled = false"), frame.index('this.cmfCoverRemove("grid")'))
        self.assertLess(frame.index("this._cmfGridLayer.alpha = "), frame.index('this.cmfCoverRemove("grid")'))
        remove = SPACE[SPACE.index("private function cmfCoverRemove"):SPACE.index("protected function cmfSpaceReady")]
        self.assertLess(remove.index("this.cmfGridFrame(null)"), remove.index("lod.visible = true"))
        self.assertIn(">= this.cmfHoldMs()", SPACE, "one bound for the whole hold")
        self.assertEqual(SPACE.count("< this.cmfHoldMs()"), 2)
        self.assertNotIn("1500)", SPACE)
        self.assertNotIn("_cmfRootHoldAt < ", SPACE)
        self.assertNotIn(">= 1000", SPACE)

    def test_a_grid_in_the_map_opening_appears_at_full_strength(self):
        draws = GRID[GRID.index("private function cmfDrawGrids("):]
        self.assertEqual(draws.count("this._cmfSpaceRefresh && this._cmfGridShownOnce ?"), 2)
        self.assertNotIn("this._cmfSpaceRefresh ? MapMenu.cmfOr", draws)
        self.assertLess(draws.index("this._cmfGridShownOnce = true;"), draws.index("this.cmfGridFrame(null)") + 400)

    def test_painting_waits_for_the_menu_fade_to_finish(self):
        root = SPACE[SPACE.index("private function cmfAncestorAlpha"):SPACE.index("// The game's own fade-in only changes")]
        self.assertIn("alpha *= node.alpha", root)
        self.assertIn("if(alpha < 0.999)", root)
        self.assertIn("lod.visible = false", root)
        self.assertIn('"paint root ms="', root)
        self.assertIn('"paint close hidden ms="', root)
        # every opening: the hold starts when a fog layer has shapes, with or without a kept grid
        self.assertIn("this._cmfGridLayer.numChildren == 0", root)
        frame = self.frame()
        self.assertLess(frame.index("this.cmfPaintRoot()"), frame.index("this._cmfGridLayer.alpha = "))
        self.assertIn("this.cmfAncestorAlpha() >= 0.999)", frame)
        self.assertIn("this._cmfCoverWantGrid && this._cmfWarm >= 8", frame)
        remove = SPACE[SPACE.index("private function cmfCoverRemove"):SPACE.index("protected function cmfSpaceReady")]
        self.assertIn("this.cmfAncestorAlpha() < 0.999", remove)

    def test_painting_waits_eight_rendered_frames_after_everything_is_ready(self):
        frame = self.frame()
        self.assertIn("else { this._cmfWarm = 0; }", frame)
        self.assertLess(frame.index("this._cmfWarm++"), frame.index('this.cmfCoverRemove("grid")'))
        root = SPACE[SPACE.index("private function cmfPaintRoot"):SPACE.index("// The game's own fade-in only changes")]
        self.assertIn("this._cmfRootHold && alpha >= 0.999 && this._cmfWarm < 8", root)
        self.assertIn('"paint warm frames="', root)
        remove = SPACE[SPACE.index("private function cmfCoverRemove"):SPACE.index("protected function cmfSpaceReady")]
        self.assertIn('"paint warm frames="', remove)
        self.assertNotIn("cacheAsBitmap", GRID + SPACE, "the grid's look and scaling stay as they are")

    def test_only_the_event_lines_remain(self):
        text = GRID + SPACE
        for gone in ("cover probe", "cover flag", "fog chain", "cmfFogChain", "_cmfProbed"):
            self.assertNotIn(gone, text)
        for kept in ('"cover shown ms="', '"paint held ms="', '"paint warm frames="', '"paint root ms="',
                     '"paint close hidden ms="', '"fog close kept ms="'):
            self.assertIn(kept, text)

    def test_close_hides_the_painting_at_once_and_keeps_it_hidden(self):
        close = GRID[GRID.index("protected function cmfFogClosing"):GRID.index("// The kept grids")]
        self.assertIn("this.cmfPaintRoot()", close)
        root = SPACE[SPACE.index("private function cmfPaintRoot"):SPACE.index("// The game's own fade-in only changes")]
        self.assertLess(root.index("if(this._cmfFogClosing)"), root.index("if(!this._cmfRootHold)"))

    def test_fog_stays_drawn_and_full_while_the_movie_closes(self):
        frame = self.frame()
        self.assertIn("this._cmfFogClosing ? 1 : container.mcLodContainer.alpha", frame)
        self.assertIn("container.addChildAt(this._cmfGridLayer", frame[:frame.index("origin =")])
        draws = GRID[GRID.index("private function cmfDrawGrids("):]
        self.assertLess(draws.index("if(this._cmfFogClosing) { return; }"), draws.index("removeChildAt(0)"))
        close = GRID[GRID.index("protected function cmfFogClosing"):]
        self.assertIn('"fog close kept ms="', close[:close.index("      }\n")])
        hides = [e["replace"] for e in MENU if "override public function hideAnimation" in e["replace"]]
        self.assertTrue(any("this.cmfFogClosing();" in text for text in hides))


if __name__ == "__main__":
    unittest.main()
