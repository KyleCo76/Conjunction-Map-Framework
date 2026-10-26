"""Map-space drawing (API version 6): the mapSpace anchor, the line, text and movie kinds, CMFDrawSetList,
CMFMapRefresh, drawing tabs, listen, above, hover and clicks with the OnDrawingClicked hook, the map file's
edits, CMF's own test movie and the modCMFTestMapSpace test pack.

Static checks only; nothing here has run in game. The design is the map-space drawing research
(2026-10-20, section 5.2) with the Witcher's Path adapter needs (plans/witchers-path-adapter/ability-needs.md).
"""
from pathlib import Path
import json
import re
import struct
import sys
import unittest

import lz4.block

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT/'source/core/content/scripts/local/cmfCore.ws'
EDITS = ROOT/'source/panel/pin-fields/edits.json'
PACK = ROOT/'source/providers/modCMFTestMapSpace'
PACK_SCRIPT = PACK/'content/scripts/local/modcmftestmapspace_cmf.ws'
MOVIE_SOURCE = ROOT/'source/panel/test-movie/CMFTestMapSpace.as'
sys.path.insert(0, str(ROOT/'tools'))
import cmf_pack
import cmf_package
import cmf_panel
import cmf_test_movie


def body(text, signature):
    # A class method (signature starting with a tab) ends at its own closing brace, a global function at column 0.
    start = text.index(signature)
    return text[start:text.index('\n\t}' if signature.startswith('\t') else '\n}', start)]


def edits(cls):
    return json.loads(EDITS.read_text(encoding='utf-8'))['classes']['red/game/witcher3/' + cls]


def replaced(cls):
    return ''.join(e['replace'] for e in edits(cls))


def words(core, expression):
    # Evaluates a WitcherScript string expression of literals and CMFTheme...() calls (no arguments).
    out = []
    for literal, call in re.findall(r'"([^"]*)"|(CMFTheme\w+)\(\)', expression):
        if literal:
            out.extend(w for w in literal.split(',') if w)
        else:
            text = body(core, 'function %s(' % call)
            text = text[text.index('return ') + 7:]
            out.extend(words(core, text[:text.index(';')]))
    return out


def shape_keys(core, kind):
    # Mirrors CMFThemeShapeKeys(kind).
    text = body(core, 'function CMFThemeShapeKeys(')
    keys = words(core, text[text.index('keys = '):text.index(';', text.index('keys = '))])
    space = words(core, text[text.index('space = '):text.index(';', text.index('space = '))])
    case = text[text.index("case '%s':" % kind):]
    case = case[case.index('return ') + 7:case.index(';')]
    head = keys if case.startswith('keys') else space if case.startswith('space') else []
    return head + words(core, case)


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.core = CORE.read_text(encoding='ascii')

    def test_version_stays_6(self):
        self.assertIn('function CMFGetVersion() : int { return 13; }', self.core)

    def test_text_drawings_take_wrap_and_fit(self):
        self.assertIn('return text == "keep" || text == "none" || (part == \'\' && (text == "wrap" || text == "fit"));',
                      self.core)

    def test_calls_and_hook(self):
        core = self.core
        self.assertIn('function CMFDrawSetList(provider : string, id : name, key : name, values : array<float>) : bool',
                      core)
        self.assertIn('function CMFMapRefresh() : bool', core)
        self.assertIn('\tpublic function OnDrawingClicked(menu : CR4MapMenu, provider : string, id : name, '
                      'input : string, value : int) : bool', core)
        self.assertIn('event OnCMFDrawingClicked(id : string, value : int)', core)
        self.assertIn('event OnCMFMapSpaceReady()', core)
        clicked = body(core, '\tpublic function DrawingClicked(')
        self.assertIn('OnDrawingClicked(menu, owner, themeEntries[i].target, "click", value);', clicked)
        self.assertIn('ThemeDrawingOwner(', clicked)

    def test_listen_ready_hook(self):
        core = self.core
        self.assertIn('\tpublic function OnMapListening(menu : CR4MapMenu, keys : string)', core)
        self.assertIn('event OnCMFListenReady(keys : string)', core)
        ready = body(core, '\tpublic function ListenReady(')
        self.assertIn('CMFLog("listen ready keys=" + keys);', ready)
        self.assertIn('OnMapListening(menu, keys);', ready)

    def test_space_is_sent_per_build_not_in_the_theme(self):
        core = self.core
        send = body(core, '\tpublic function SendSpace(')
        self.assertIn('storage.SetFlashArray("cmf.map.space", flashArray);', send)
        self.assertIn('SpaceAreaMatches(', send)
        self.assertIn('item.SetMemberFlashNumber("v" + k, themeEntries[i].values[k]);', send)
        theme = body(core, '\tpublic function SendTheme(')
        self.assertIn('themeEntries[i].kind != 1 && IsSpaceDrawing(', theme)
        self.assertIn('item.SetMemberFlashNumber("v" + k, themeEntries[i].values[k]);', theme)
        pins = body(core, 'function UpdateUserMapPins(')
        self.assertIn('SendSpace(GetMenuFlashValueStorage(), m_shownArea, this);', pins)
        refresh = body(core, 'function CMFMapSpaceSend(')
        self.assertLess(refresh.index('MapReady('), refresh.index('SendTheme('))

    def test_pins_added_outside_the_late_pass_are_caught(self):
        # Build 1 (2026-10-20): Shared Utils' UpdateUserMapPins wrapper ran outside CMF's, so Botanist's pins
        # reached the map unfilled (black crosses, no tab). CMF's UpdateData wrapper fills them and sends again.
        core = self.core
        pins = body(core, 'function UpdateUserMapPins(')
        self.assertLess(pins.index('KeepFullList(flashArray);'), pins.index('MapReady('))
        data = body(core, 'function UpdateData(optional ignoreSelectionChange : bool)')
        self.assertLess(data.index('wrappedMethod(ignoreSelectionChange);'), data.index('CatchLatePins('))
        self.assertIn('SetFlashArray("worldmap.global.pins.static.update", flashArray);', data)
        self.assertIn('SetFlashArray("worldmap.global.pins.static", flashArray);', data)
        catch = body(core, '\tpublic function CatchLatePins(')
        self.assertIn('catchArray = NULL;', catch)
        self.assertIn('CMFLog("late pins caught n=" + missed + " of " + flashArray.GetLength());', catch)
        self.assertLess(catch.index('OpenPinList();'), catch.index('FillMissingPinFields(flashArray, mapContext, -1, area);'))
        fill = body(core, '\tpublic function FillMissingPinFields(')
        self.assertIn('if (fullList && !isPlayer && !isUser && (fresh || !catching))\n\t\t\t{\n\t\t\t\tif (ProcessPinAsks(', fill)
        self.assertLess(fill.index('ProcessPinAsks(dataObject)'), fill.index('OnPinReady(dataObject, mapContext)'))

    def test_pin_list_opens_for_the_whole_build(self):
        # The Stable 2.2.1's precompiled UpdateEntityPins skips every loose wrapper on that method (Show Chests and
        # All Quest Objectives starts, 2026-10-25), so CMF's UpdateData wrapper opens the per-pin list itself.
        core = self.core
        data = body(core, 'function UpdateData(optional ignoreSelectionChange : bool)')
        self.assertLess(data.index('BeginBuild(m_shownArea);'), data.index('wrappedMethod(ignoreSelectionChange);'))
        self.assertLess(data.index('wrappedMethod(ignoreSelectionChange);'), data.index('EndBuild();'))
        self.assertLess(data.index('EndBuild();'), data.index('CatchLatePins('))
        begin = body(core, '\tpublic function BeginBuild(')
        self.assertIn('entityStepRan = false;', begin)
        self.assertLess(begin.index('OpenPinList();'), begin.index('NoteListArea(area);'))
        self.assertIn('listOpen = false;', body(core, '\tpublic function EndBuild('))
        entity = body(core, 'function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void')
        self.assertLess(entity.index('NoteEntityStep();'), entity.index('wrappedMethod(flashArray);'))
        self.assertIn('OpenPinList();', entity)
        pins = body(core, 'function UpdateUserMapPins(')
        self.assertLess(pins.index('CheckEntityStep();'), pins.index('FillMissingPinFields('))
        check = body(core, '\tpublic function CheckEntityStep(')
        self.assertIn('if (inBuild && !entityStepRan && !entitySkipLogged)', check)
        self.assertIn('CMFLog("entity step skipped: another mod replaced CR4MapMenu.UpdateEntityPins; pin list opened by '
                      'UpdateData");', check)

    def test_anchor_and_kind_rules(self):
        draw = body(self.core, 'function CMFDraw(')
        self.assertIn("(anchor == 'mapSpace' && IsNameValid(kind) && kind != 'line' && kind != 'text' && kind != 'movie' && kind != 'image')",
                      draw)
        self.assertIn("(anchor != 'mapSpace' && kind == 'line')", draw)
        self.assertIn('mapSpace', words(self.core, 'CMFThemeParts()'))
        self.assertEqual(words(self.core, 'CMFThemeKinds()')[-4:], ['line', 'text', 'movie', 'image'])

    def test_kind_keys_match_the_pack_tool(self):
        for kind, keys in cmf_pack.THEME_KIND_KEYS.items():
            self.assertEqual(sorted(set(shape_keys(self.core, kind))), sorted(set(keys)), kind)
        self.assertEqual(words(self.core, 'CMFThemeHoverKeys()'), list(cmf_pack.THEME_HOVER))
        lists = body(self.core, 'function CMFThemeListKeys(')
        self.assertIn('"%s"' % ','.join(cmf_pack.THEME_LIST_KEYS['line']), lists)

    def test_values(self):
        ok = body(self.core, 'function CMFThemeValueOk(')
        for prefix in ('cmf.', 'map.', 'worldmap.global.', 'worldmap.title.'):
            self.assertIn('!StrBeginsWith(text, "%s")' % prefix, ok)
        self.assertIn('StrBeginsWith(text, "swf/") && StrEndsWith(text, ".swf")', ok)
        self.assertIn('number >= 0 && number <= 1000 && number == (int)number', ok)
        text_keys = body(self.core, 'function CMFThemeTextKey(')
        for key in ('area', 'src', 'tab', 'tabLabel', 'text', 'listen', 'listenFields'):
            self.assertIn(key, text_keys)

    def test_movie_takes_its_own_keys_after_cmfdraw(self):
        draw_set = body(self.core, 'function CMFDrawSet(')
        self.assertIn("own = kind == 'movie' && !CMFListHas(CMFThemeShapeKeys('movie'), NameToString(key));", draw_set)
        self.assertIn('if ((!own && !CMFThemeValueOk(', draw_set)
        lists = body(self.core, 'function CMFDrawSetList(')
        self.assertIn('values.Size() > 100000', lists)
        self.assertIn("DrawingKind(provider, id) != 'movie'", lists)

    def test_core_names_no_other_mod(self):
        lowered = self.core.lower()
        for name in ('witcherspath', 'fogofwar', 'witchers_path'):
            self.assertNotIn(name, lowered)


class PanelEditTests(unittest.TestCase):
    def test_menu_listens_and_reports(self):
        menu = replaced('menus/worldmap/MapMenu.as')
        self.assertIn('this.cmfCreateSpace();\n         dispatchEvent(new GameEvent(GameEvent.CALL,"OnConfigUI"));', menu)
        self.assertIn('GameEvent.REGISTER,"cmf.map.space",[this.cmfSetSpace]', menu)
        self.assertIn('"OnCMFMapSpaceReady"', menu)
        self.assertIn('"OnCMFDrawingClicked",[String(clip.cmfDrawing.id),int(clip.cmfDrawing.keys.click)]', menu)
        self.assertIn('var clicks:Boolean = param2.keys.click >= 1 && param4.clicks == true;', menu)
        self.assertIn('param1.indexOf("cmf.") != 0 && param1.indexOf("map.") != 0', menu)
        self.assertIn('sig += "|" + MapMenu.cmfTab;', menu)
        self.assertIn('String(param1.keys.tab) != MapMenu.cmfTab', menu)
        self.assertIn('y2 = param2.top - Number(param1.above);', menu)
        self.assertIn('area,src,tab,tabLabel,text,listen,listenFields,clearView,clearSide,wideAnchor,";', menu)
        self.assertIn('"clicks":true,', menu)

    def test_map_space_layers(self):
        container = replaced('menus/worldmap/HubMapContainer.as')
        self.assertIn('addChildAt(this._cmfSpaceUnder,getChildIndex(this.mcLodContainer) + 1);', container)
        self.assertIn('param1.lineStyle(width,color,alpha,false,scaleMode,"round","round");', container)
        self.assertIn('var scaleMode:String = param2.keys.strokeZoom == 1 ? "normal" : "none";', container)
        self.assertIn('Loader(entry.loader).load(new URLRequest(src));', container)
        self.assertIn('param1.loader.content["cmfMapSpace"] as Function', container)
        self.assertIn('this._cmfSpaceUnder.alpha = this.mcLodContainer.alpha;', container)
        self.assertIn('this._cmfSpacePreview.scaleX = 0.5;', container)
        hub = replaced('menus/worldmap/HubMap.as')
        self.assertIn('mcHubMapContainer.cmfSetWorld(param1,param3,', hub)

    def test_drawn_tabs(self):
        panel = replaced('menus/worldmap/HubMapPinPanel.as')
        self.assertIn('new CategoryData(id,100000 + k,false,false,false)', panel)
        self.assertIn('MapMenu.cmfTab = param1._name;', panel)
        self.assertIn('this.cmfAddDrawnTabs();', panel)
        self.assertIn('this._categories[j]._pins.length = 0;', panel)

    def test_after_launch_d1(self):
        # Launch D1 (2026-10-20): values written before the map listens never arrived, a tab named only by a
        # later drawing lost its label, and the test movie's square vanished after CMFMapRefresh.
        menu = replaced('menus/worldmap/MapMenu.as')
        self.assertIn('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFListenReady",[added.join("|")]));', menu)
        self.assertIn('else if(all[n].label == "")\n               {\n                  all[n].label = tab.label;', menu)
        container = replaced('menus/worldmap/HubMapContainer.as')
        self.assertIn('holder = d.kind == "movie" ? this.cmfMovieHolder(d) : new Sprite();', container)
        self.assertIn('if(layer.getChildAt(j).name != "cmfMovie")', container)
        self.assertIn('if(entry.loader.parent != param1)', container)
        self.assertIn('this.cmfSpaceNote("space check layer=over on="', container)
        self.assertIn('import flash.geom.ColorTransform;', container)

    def test_after_launch_d2(self):
        # Launch D2 (2026-10-20): a key registered with an anonymous closure from inside a storage callback
        # never received a value, and the over layer sat in the clip range of the game's edge-gradient mask,
        # which never leaves the container's origin, so the ring and the words near Geralt were clipped away.
        menu = replaced('menus/worldmap/MapMenu.as')
        self.assertNotIn('cmfListener(', menu)
        self.assertIn('addEventListener(Event.ENTER_FRAME,this.cmfListenFrame,false,0,true);', menu)
        self.assertIn('dispatchEvent(new GameEvent(GameEvent.REGISTER,key,[slots[slot]]));', menu)
        for k in range(16):
            self.assertIn('public function cmfListenSlot%d(param1:Object) : void' % k, menu)
            self.assertIn('this.cmfListenArrived(String(this._cmfListenSlots[%d]),param1);' % k, menu)
        self.assertIn('"listen refused key=" + key + " reason=slots max="', menu)
        container = replaced('menus/worldmap/HubMapContainer.as')
        self.assertNotIn('addChildAt(this._cmfSpaceOver', container)
        self.assertIn('getChildIndex(this._cmfSpaceOver) != numChildren - 1', container)
        self.assertIn('addChildAt(this._cmfSpaceUnder,getChildIndex(this.mcLodContainer) + 1);', container)

    def test_after_launch_d4(self):
        # Launch D4 (2026-10-20): Witcher's Path's box words were cut at the box's right edge, Ink & Iron's tab
        # plate covered the lowest box stacked above the legend's tab, and words kept the hover colour.
        menu = replaced('menus/worldmap/MapMenu.as')
        self.assertIn('param1.wrap != "none" && param1.wrap != "fit";', menu)
        self.assertIn('out.minWidth = Math.max(MapMenu.cmfOr(param1.minWidth,0),param2.textWidth + 6 + 2 * pad);', menu)
        self.assertIn('keys.wrap == "wrap" && !(param2.keys.height is Number)', menu)
        self.assertIn('if(!param5.wordWrap && param5.textWidth + 6 > param5.width)', menu)
        self.assertIn('param5.x = param3.x + (param3.width - param5.width) / 2;', menu)
        self.assertIn('fmt.color = param6 && keys.colorHover is Number ? uint(keys.colorHover) : param5.defaultTextFormat.color;',
                      menu)
        self.assertIn('stack = MapMenu.cmfStackBox(param1,param2,param3,param4);', menu)
        self.assertIn('public static function cmfStackBox(param1:Sprite, param2:Array, param3:Rectangle, param4:Object) : Rectangle',
                      menu)
        self.assertIn('return new Rectangle(param3.x,top,param3.width,param3.height);', menu)
        # Launch D5: the plate is Ink & Iron's frame on the whole legend, so legendTab also clears the legend's boxes.
        self.assertIn('"legendTab":"legend",', menu)
        self.assertIn('tops.push(this.cmfOuterTop(param1,boxes[n].box,view));', menu)
        self.assertIn('ctx.stackTop = tops[n];', menu)
        self.assertIn('var top:Number = param4.stackTop is Number ? Math.min(param3.top,Number(param4.stackTop)) : param3.top;',
                      menu)

    def test_edits_name_no_other_mod(self):
        text = EDITS.read_text(encoding='utf-8').lower()
        for name in ('witcherspath', 'fogofwar'):
            self.assertNotIn(name, text)


class TestMovieTests(unittest.TestCase):
    def test_stub_movie_has_one_class(self):
        self.assertEqual(cmf_test_movie.movie_classes(cmf_test_movie.stub_movie('CMFTestMapSpace')),
                         ['CMFTestMapSpace'])

    def test_resource_and_bundle_round_trip(self):
        movie = cmf_test_movie.stub_movie('CMFTestMapSpace')
        resource = cmf_test_movie.make_resource(movie, cmf_test_movie.LINKAGE)
        self.assertEqual(cmf_panel.read_cr2w(resource, 'mod-movie')['movieBytes'], movie)
        depot = cmf_test_movie.MOVIE_DEPOT
        bundle = cmf_package.make_bundle(resource, depot=depot)
        metadata = cmf_package.make_metadata(bundle, depot=depot)
        self.assertEqual(cmf_panel.read_package(bundle, metadata, depot=depot)['layout'], 'PASS')
        offset, size, packed, _, _ = struct.unpack_from('<QIIII', bundle, 32 + 272)
        self.assertEqual(lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size), resource)
        self.assertEqual(bundle[32:32 + len(depot)], depot.encode('ascii'))

    def test_url_and_depot_agree(self):
        url, depot = cmf_test_movie.MOVIE_URL, cmf_test_movie.MOVIE_DEPOT
        self.assertEqual(depot, 'gameplay\\gui_new\\' + url[:-len('.swf')].replace('/', '\\') + '.redswf')
        self.assertIn('"%s"' % url, PACK_SCRIPT.read_text(encoding='ascii'))

    def test_movie_source(self):
        source = MOVIE_SOURCE.read_text(encoding='ascii')
        self.assertIn('public class CMFTestMapSpace extends MovieClip', source)
        self.assertIn('public function cmfMapSpace(data:Object, map:Object) : Boolean', source)
        self.assertNotIn('img://', source)

    def test_default_packaging_unchanged(self):
        resource = b'CR2W' + bytes(200)
        self.assertEqual(cmf_package.make_bundle(resource), cmf_package.make_bundle(resource, depot=cmf_package.DEPOT))


class TestPackTests(unittest.TestCase):
    def test_pack_script_is_clean(self):
        text = PACK_SCRIPT.read_text(encoding='ascii')
        report = cmf_pack.Report()
        cmf_pack.check_script('modcmftestmapspace_cmf.ws', text, 'modCMFTestMapSpace', report, [], set())
        self.assertEqual((report.errors, report.warnings), ([], []))
        self.assertTrue(any('CMFCore.OnDrawingClicked' in n and 'CMF 6' in n for n in report.notes), report.notes)
        self.assertIn('TEST ONLY', (PACK/'README.txt').read_text(encoding='ascii'))
        self.assertTrue(text.startswith('// TEST ONLY'))

    def test_pack_tool_rules(self):
        def check(code):
            report = cmf_pack.Report()
            cmf_pack.check_script('x.ws', '@wrapMethod(CR4Game)\nfunction OnGameStarted(restored : bool)\n{\n'
                                  '\tvar result : bool;\n\tvar v : array<float>;\n\tresult = wrappedMethod(restored);\n'
                                  + code + '\treturn result;\n}\n', 'modAcme', report, [], set())
            return report.errors
        self.assertEqual(check('\tCMFDraw("modAcme", \'mapSpace\', \'acmeFog\', \'movie\');\n'
                               '\tCMFDrawSet("modAcme", \'acmeFog\', \'cellSize\', "", 6.7);\n'
                               '\tCMFDrawSetList("modAcme", \'acmeFog\', \'grid\', v);\n'), [])
        self.assertEqual(check('\tCMFDraw("modAcme", \'mapSpace\', \'acmeRoute\', \'line\');\n'
                               '\tCMFDrawSetList("modAcme", \'acmeRoute\', \'xs\', v);\n'
                               '\tCMFDrawSet("modAcme", \'acmeRoute\', \'listen\', "acme.route", 0);\n'), [])
        cases = {
            '\tCMFDraw("modAcme", \'mapSpace\', \'acmeBox\', \'rect\');\n': 'mapSpace takes only',
            '\tCMFDraw("modAcme", \'legend\', \'acmeRoute\', \'line\');\n': 'takes only the mapSpace anchor',
            '\tCMFDrawSetList("modAcme", \'acmeRoute\', \'grid\', v);\n': 'not a list key',
            '\tCMFDrawSet("modAcme", \'acmeRoute\', \'cellSize\', "", 1);\n': 'not a drawing key in CMF 7',
        }
        for code, expected in cases.items():
            self.assertTrue(any(expected in e for e in check(code)), (code, check(code)))
        self.assertIn('OnDrawingClicked', cmf_pack.HOOKS)
        self.assertIn('OnMapListening', cmf_pack.HOOKS6)
        self.assertTrue({'CMFDrawSetList', 'CMFMapRefresh'} <= cmf_pack.VERSION6 <= cmf_pack.API)


if __name__ == '__main__':
    unittest.main()
