"""Source wiring checks complement the executed emitted helper tests."""
import json
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
NATIVE=ROOT/"build/api-rev13-map/planning-native/export/scripts"
EDITS=json.loads((ROOT/"source/panel/pin-fields/edits.json").read_text(encoding="utf-8"))["classes"]

def applied(relative):
    source=(NATIVE/relative).read_text(encoding="utf-8")
    for edit in EDITS.get(relative,[]):
        assert source.count(edit["find"])==edit["count"],relative
        source=source.replace(edit["find"],edit["replace"])
    return source

@unittest.skipUnless(NATIVE.is_dir(),"pinned native source export absent")
class ItemConsumerWiringTests(unittest.TestCase):
    def contains(self, needle, source):
        self.assertTrue(needle in source, needle)

    def test_consumers_use_explicit_context(self):
        root="red/game/witcher3/"
        tooltip=applied(root+"tooltips/TooltipMap.as")
        pin=applied(root+"menus/worldmap/StaticMapPinDescribed.as")
        row=applied(root+"menus/worldmap/HubMapPinCategoryItemRenderer.as")
        panel=applied(root+"menus/worldmap/HubMapPinPanel.as")
        menu=applied(root+"menus/worldmap/MapMenu.as")
        self.contains("cmfPinContext",tooltip)
        self.contains('cmfTextStyleFor(this.tfLabel,part,"",d',pin)
        self.contains("cmfTextStyleValue(this.tfPinType",row)
        self.contains("cmfStyleCategoryButton()",panel)
        self.contains('MapMenu.cmfNum("tooltip","x",0,this.m_selectedPinData)',menu)
        self.assertLess(menu.index("this.tooltipInstance.cmfPinContext = event.mapppinData"),
                        menu.index("this.tooltipInstance.ShowTooltip(event.tooltipData"))
        self.contains('MapMenu.cmfPartFor("pinButton",context)',menu)
        self.contains("StaticMapPinDescribed(child).update()",menu)

    def test_internal_theme_redraw_does_not_overwrite_legacy_channel(self):
        menu=applied("red/game/witcher3/menus/worldmap/MapMenu.as")
        self.assertFalse("this.cmfSetHintCopy(this._cmfHintData)" in menu)
        self.contains("this.cmfRenderHintCopy(this._cmfHintData)",menu)
        self.contains('"cmf.map.hints",[this.cmfSetHintCopy]',menu)

    def test_replacement_text_uses_native_area_and_button_paths(self):
        menu=applied("red/game/witcher3/menus/worldmap/MapMenu.as")
        panel=applied("red/game/witcher3/menus/worldmap/HubMapPinPanel.as")
        self.contains("this._cmfAreaKey = param6",menu)
        self.contains('this.cmfReplaceText(this.mapName["textField"] as TextField',menu)
        self.contains('MapMenu.cmfStyle("worldButton","text")',menu)
        self.contains('MapMenu.cmfStyle("legend","allText")',panel)

    def test_task4_sound_zoom_filter_and_image_wiring(self):
        base="red/game/witcher3/menus/worldmap/"
        menu=applied(base+"MapMenu.as")
        hub=applied(base+"HubMap.as")
        pin=applied(base+"StaticMapPinDescribed.as")
        container=applied(base+"HubMapContainer.as")
        for path in EDITS:
            self.assertNotIn("W3ScrollingList",path)
            applied(path)
        self.contains('this.cmfWheelZoom(_loc2_,_loc3_);',menu)
        # The native held-input entry point keeps its original factor and dispatch.
        old=(NATIVE/(base+"HubMap.as")).read_text(encoding="utf-8")
        start="      override public function Zoom(param1:Boolean)"
        stop="      override public function ZoomByFactor("
        self.assertEqual(hub[hub.index(start):hub.index(stop)],old[old.index(start):old.index(stop)])
        self.assertLess(hub.index("if(this._selectedMapPinIndex == param1)"),hub.index('MapMenu.cmfSound("select","")'))
        self.contains('MapMenu.cmfDrawingRevision + "," + param2 + "," + param1.type',pin)
        self.contains('"pin":param1',pin)
        self.contains('MapMenu.cmfCompilePinFilters(d);',menu)
        self.contains('MapMenu.cmfDrawingMatchesPin(param1,param2 ? param2.pin : null)',menu)
        self.contains('MapMenu.cmfDrawImage(node,drawing,box,ctx);',container)
        self.contains('this._cmfSpaceTexts.push(node);',container)
