"""Map blur fix (CMF 1.6.1): held movement keys always let go, and every zoom burst is logged.

Reads cmfCore.ws and the panel edits as text; only a launch proves the game delivers these events.
"""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
HUB = 'red/game/witcher3/menus/worldmap/HubMap.as'
MENU = 'red/game/witcher3/menus/worldmap/MapMenu.as'


def net(changes, text):
    """How often text is in the CMF-written part of a class once every change has applied."""
    return sum(c['count']*(c['replace'].count(text) - c['find'].count(text)) for c in changes)


def cmf_text(changes):
    """CMF's own text of a class with every change applied in order (the game's text is not in the repo)."""
    text = ''
    for change in changes:
        if change['find'] in text:
            text = text.replace(change['find'], change['replace'])
        else:
            text += '\n' + change['replace']
    return text


def function(code, name):
    start = code.index('function ' + name + '(')
    return code[start:code.index('\n      }\n', start)]


class MapBlurFix(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        edits = json.loads(EDITS.read_text(encoding='utf-8'))
        cls.hub = edits['classes'][HUB]
        cls.menu = edits['classes'][MENU]
        cls.hubText = cmf_text(cls.hub)
        cls.menuText = cmf_text(cls.menu)
        cls.core = CORE.read_text(encoding='utf-8')

    def test_new_finds_match_in_cmf_text(self):
        # The blur fix's 11 hub and 4 menu changes come last and find only text CMF's earlier changes wrote, so their
        # counts can be checked without the game's files.
        for changes, added in ((self.hub, 11), (self.menu, 4)):
            for i in range(len(changes) - added, len(changes)):
                self.assertEqual(net(changes[:i], changes[i]['find']), changes[i]['count'], changes[i]['find'][:70])

    def test_menu_passes_every_event_to_the_hub_first(self):
        self.assertIn('         if(this.mcHubMap) { this.mcHubMap.cmfNavInput(param1); }\n'
                      '         if(this.cmfMovieInput(param1)) { return; }\n', self.menuText)

    def test_input_hook_never_handles_events(self):
        body = function(self.hubText, 'cmfNavInput')
        self.assertNotIn('handled', body)
        self.assertNotIn('stopImmediatePropagation', body)

    def test_release_clears_only_its_own_flags_and_only_when_dropped(self):
        own = function(self.hubText, 'cmfNavOwn')
        self.assertIn('this._cmfNavOwners[bit] == this._cmfNavReleased[key]', own)
        self.assertIn('if((flags & bit) != 0)', own)
        self.assertIn('this.cmfNavDrop(stuck);', own)
        self.assertIn('"nav release dropped by map, cleared flags="', own)
        self.assertIn('this._cmfNavReleased[bit] = code;', function(self.hubText, 'cmfNavInput'))

    def test_clear_resets_the_map_and_the_games_key_repeat(self):
        clear = function(self.hubText, 'cmfNavClear')
        self.assertIn('this.ResetKeyboardInput();', clear)
        self.assertIn('input["reset"]();', clear)
        self.assertIn('"nav clear reason=" + reason', clear)
        self.assertIn('addEventListener(Event.DEACTIVATE,this.cmfNavFocus,false,0,true);', self.hubText)
        self.assertIn('addEventListener(Event.ACTIVATE,this.cmfNavFocus,false,0,true);', self.hubText)
        menu = function(self.menuText, 'cmfNavClear')
        self.assertIn('this.mcHubMap.cmfNavClear(reason);', menu)
        self.assertIn('this.mcUniverseMap.cmfClearMovieNavigation();', menu)

    def test_quiet_held_keys_are_logged_not_cleared(self):
        watch = function(self.hubText, 'cmfNavWatch')
        self.assertIn('"nav held quiet flag="', watch)
        self.assertNotIn('cmfNavDrop', watch)
        self.assertNotIn('ResetKeyboardInput', watch)

    def test_watch_runs_before_each_movement_tick(self):
        self.assertIn('         this.cmfNavWatch();\n         this.cmfSpreadTick();\n         if(this.cmfTimed)\n', self.hubText)

    def test_every_zoom_writer_is_named(self):
        self.assertIn('this.cmfNavMark(this._cmfZoomSrc != "" ? this._cmfZoomSrc : "other",true);', self.hubText)
        self.assertIn('this._cmfZoomSrc = this._keyboardZoomIn || this._keyboardZoomOut ? "key" : "pad";', self.hubText)
        self.assertIn('setActualScale(this.cmfMaxZoom(),this.cmfMaxZoom());this.cmfNavMark("reset");', self.hubText)
        self.assertIn('this.cmfNavMark("view");', function(self.hubText, 'cmfSetZoom'))
        wheel = function(self.menuText, 'cmfWheelZoom')
        self.assertIn('this.mcHubMap.cmfZoomSource("wheel");', wheel)
        self.assertIn('this.mcHubMap.cmfZoomSource("");', wheel)

    def test_mouse_drag_is_only_labelled(self):
        # Kyle: mouse drag is perfect, never change it. The fix only notes the left button for the log.
        for change in self.hub[-11:]:
            if 'OnMouse' in change['find']:
                added = change['replace'].replace(change['find'], '')
                self.assertIn('this._cmfMouseHeld = ', added)
                self.assertNotIn('Drag', added)
                self.assertNotIn('return', added)

    def test_one_line_per_burst(self):
        end = function(self.hubText, 'cmfNavBurstEnd')
        self.assertIn('"nav burst src=" + list', end)
        self.assertIn('now - this._cmfBurst.last > 250', function(self.hubText, 'cmfNavWatch'))

    def test_squares_are_shown_again_after_a_focus_change(self):
        # Start F (Kyle's layer tint): the blur is the background seen through the current level, whose squares
        # stay loaded but stop drawing. Reloading (rounds 2 to 4) never helped, so CMF shows them again instead.
        clear = function(self.hubText, 'cmfNavClear')
        self.assertIn('this._cmfTileCheckAt = getTimer() + 3000;', clear)
        stack = function(self.hubText, 'cmfTileStack')
        # Round 2 looked for "TileLoader" in each child's text, but the loaders print as "[CLIK UILoader ...]".
        self.assertIn('if(loader is HubMapTileLoader)', stack)
        self.assertNotIn('String(loader)', stack)
        self.assertIn('if(heal && (!loader.visible || loader.alpha < 1))', stack)
        self.assertIn('loader.visible = true;', stack)
        self.assertNotIn('unload', stack)
        self.assertNotIn('.source =', stack)
        self.assertIn('lods.setChildIndex(current,lods.numChildren - 1);', stack)
        self.assertIn('if(lod != lods.GetCurrentLod()) { map.HideTiles(lod); }', stack)
        self.assertIn('"nav layers step=" + step', stack)
        self.assertIn('" hidden=" + hidden', stack)
        self.assertNotIn(' is Bitmap', stack)  # HubMap does not import Bitmap
        self.assertIn('if(restack && current)', stack)
        self.assertIn('if(step != "check" || healed > 0 || raised)', stack)
        self.assertIn('this._cmfTileCheckAt = 0;', stack[stack.index('catch(error:Error)\n         {\n            this.cmfNote("nav layers step=" + step + " error='):])
        heal = function(self.hubText, 'cmfTileHeal')
        # Start G: re-showing kept the map sharp; checking every tick for 3 s shortens the red flash to a frame.
        self.assertIn('if(this._cmfTileCheckAt != 0 && now < this._cmfTileCheckAt)', heal)
        self.assertIn('this.cmfTileStack("check",true,this._cmfTileFirst);', heal)
        self.assertIn('this.cmfTileStack("after",false,false);', heal)
        # Start H: other levels' loaded squares are hidden too, and a later look back at them blurred; so every level
        # is checked, every 250 ms outside the 3 s after a focus change.
        self.assertIn('else if(heal && !loader.visible)', stack)
        self.assertIn('this._cmfTileNextAt = now + 250;', heal)
        self.assertIn('this.cmfTileStack("check",true,false);', heal)
        watch = function(self.hubText, 'cmfNavWatch')
        self.assertLess(watch.index('if(!IsEnabled())'), watch.index('this.cmfTileHeal(now);'))

    def test_layer_tint_is_probe_only_and_its_finds_match(self):
        tint = json.loads((ROOT/'source/panel/pin-fields/probe-layer-tint-edits.json').read_text(encoding='utf-8'))
        self.assertIn('PROBE ONLY', tint['description'])
        self.assertEqual(list(tint['classes']), [HUB])
        for change in tint['classes'][HUB]:
            self.assertEqual(net(self.hub, change['find']), change['count'], change['find'][:70])
        self.assertNotIn('cmfProbeTint', self.hubText)
        builder = (ROOT/'tools/cmf_pin_panel.py').read_text(encoding='utf-8')
        self.assertIn("'--probe-layer-tint', action='store_true'", builder)

    def test_script_clears_the_open_map_on_a_device_change(self):
        wrap = self.core[self.core.index('@wrapMethod(CInputManager)\nfunction OnInputDeviceChanged()'):]
        wrap = wrap[:wrap.index('\n}\n')]
        self.assertIn('result = wrappedMethod();', wrap)
        self.assertIn('mapMenu.CMFNavClear("device");', wrap)
        self.assertIn('return result;', wrap)
        self.assertIn('clear = menuFlash.GetMemberFlashFunction("cmfNavClear");', self.core)
        self.assertIn('theGame.CMFSetOpenMap(mapMenu);', self.core)
        self.assertIn('theGame.CMFMapClosed(this);', self.core)

    def test_no_api_change(self):
        self.assertIn('function CMFGetVersion() : int { return 13; }', self.core)


if __name__ == '__main__':
    unittest.main()
