"""Pin-field rebuild tooling: packager, texture cache writer, panel edits and scripts.

Fixture cases read ignored build/panel-runs evidence and skip when it is absent;
a skipped case is not qualification.
"""
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
import cmf_cooked_codec
import cmf_pack
import cmf_package
import cmf_panel
import cmf_pin_stage
import cmf_test_icons
import cmf_texture_cache as cache

RUNS = ROOT/'build/panel-runs'
NOOP = RUNS/'10-noop-package-output'
S03B = RUNS/'s03b-cooked-2026-10-18-r4/providers/Mods/modCMFProbeIcons/content/texture.cache'
SCRIPTS = [ROOT/'source/core/content/scripts/local/cmfCore.ws',
           ROOT/'source/providers/modCMFTestIconPack/content/scripts/local/cmfTestIconPack.ws',
           ROOT/'source/providers/modCMFTestIconPackB/content/scripts/local/cmfTestIconPackB.ws',
           ROOT/'source/providers/modCMFTestTintPack/content/scripts/local/cmfTestTintPack.ws',
           ROOT/'source/providers/modCMFTestBackgroundPack/content/scripts/local/cmfTestBackgroundPack.ws',
           ROOT/'source/providers/modCMFTestSignpostPack/content/scripts/local/cmfTestSignpostPack.ws']


class PackagerTests(unittest.TestCase):
    @unittest.skipUnless((NOOP/'blob0.bundle').exists(), 'ignored engine-loaded noop package absent')
    def test_reproduces_engine_loaded_noop_package(self):
        bundle = (NOOP/'blob0.bundle').read_bytes()
        metadata = (NOOP/'metadata.store').read_bytes()
        offset, size, packed = struct.unpack_from('<QII', bundle, 32 + 272)
        resource = cmf_panel.read_package(bundle, metadata)
        self.assertEqual(resource['layout'], 'PASS')
        import lz4.block
        plain = lz4.block.decompress(bundle[offset:offset + packed], uncompressed_size=size)
        self.assertEqual(cmf_package.make_bundle(plain, bundle[offset:offset + packed]), bundle)
        self.assertEqual(cmf_package.make_metadata(bundle), metadata)
        self.assertEqual(cmf_package.swap_movie(plain, cmf_panel.read_cr2w(plain)['movieBytes']), plain)


class TextureCacheTests(unittest.TestCase):
    def test_multi_entry_round_trip(self):
        art = cmf_cooked_codec.encode_bc3(cmf_test_icons.signpost_icon(), 64, 64)
        small = cmf_cooked_codec.encode_bc3(bytes([200, 30, 30, 255]) * 64, 8, 8)
        data = cache.build_cache([('gameplay\\gui_new\\icons\\a\\one.png', 64, 64, cache.frame_bc3(art)),
                                  ('gameplay\\gui_new\\icons\\b\\two.png', 8, 8, cache.frame_bc3(small))])
        self.assertEqual(cache.read_entries(data), [('gameplay\\gui_new\\icons\\a\\one.png', 64, 64, art),
                                                    ('gameplay\\gui_new\\icons\\b\\two.png', 8, 8, small)])

    def test_rejects_bad_keys_and_frames(self):
        frame = cache.frame_bc3(bytes(16))
        for key in ('Gameplay\\x.png', '', 'a\\x.png\0'):
            with self.assertRaises(ValueError):
                cache.build_cache([(key, 4, 4, frame)])
        with self.assertRaises(ValueError):
            cache.build_cache([('a\\x.png', 4, 4, frame), ('a\\x.png', 4, 4, frame)])
        with self.assertRaises(ValueError):
            cache.build_cache([('a\\x.png', 8, 8, frame)])

    @unittest.skipUnless(S03B.exists(), 'ignored engine-loaded S03b cache absent')
    def test_reproduces_engine_loaded_s03b_cache(self):
        data = S03B.read_bytes()
        frame = cmf_pin_stage.s03b_frame(data)
        self.assertEqual(cache.build_cache([(cmf_pin_stage.NOTICE_KEY, 64, 64, frame)]), data)
        pack = cmf_pin_stage.test_pack_cache(data)
        self.assertEqual([e[0] for e in cache.read_entries(pack)],
                         [cmf_pin_stage.NOTICE_KEY, cmf_pin_stage.SIGNPOST_KEY])


class BackgroundPackTests(unittest.TestCase):
    def test_tiles_cover_levels_zero_to_four(self):
        tiles = cmf_pin_stage.background_tiles()
        self.assertEqual(len(tiles), sum(4 ** level for level in range(5)))
        self.assertEqual(tiles[0][0], 'gameplay\\gui_new\\maps\\cmf_testbg\\level0\\tile0x0.jpg')
        self.assertIn(('gameplay\\gui_new\\maps\\cmf_testbg\\level4\\tile15x3.jpg', 4, 15, 3), tiles)
        pack = (ROOT/'source/providers/modCMFTestBackgroundPack/content/scripts/local/'
                'cmfTestBackgroundPack.ws').read_text(encoding='ascii')
        self.assertIn('"%s"' % cmf_pin_stage.BACKGROUND_ROOT, pack)

    def test_tile_is_full_size_opaque_bc3(self):
        stream = cmf_test_icons.background_tile_bc3(3, 5, 2)
        self.assertEqual(len(stream), 1024 * 1024)
        self.assertTrue(all(stream[i:i + 2] == b'\xff\xff' for i in range(0, len(stream), 16 * 997)))
        self.assertNotEqual(stream, cmf_test_icons.background_tile_bc3(3, 6, 2))

    def test_cache_round_trips(self):
        data = cmf_pin_stage.test_background_cache()
        entries = cache.read_entries(data)
        self.assertEqual([e[0] for e in entries], [t[0] for t in cmf_pin_stage.background_tiles()])
        self.assertTrue(all(e[1:3] == (1024, 1024) for e in entries))
        self.assertEqual(entries[7][3], cmf_test_icons.background_tile_bc3(2, 2, 0))


class SettingsOverlayTests(unittest.TestCase):
    def write(self, root, files):
        for name, data in files.items():
            (root/name).parent.mkdir(parents=True, exist_ok=True)
            (root/name).write_bytes(data)
        report = {'schema': 'cmf-settings-stage-1',
                  'files': {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}}
        (root/'settings-stage.json').write_text(json.dumps(report), encoding='utf-8')

    def test_overlay_checks_hashes_and_shared_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            files = {'Mods/a/content/en.w3strings': b'x', 'Mods/a/content/scripts/local/p.ws': b'same',
                     'bin/config/r4game/user_config_matrix/pc/a.xml': b'<x/>'}
            self.write(root, files)
            self.assertEqual(cmf_pin_stage.settings_overlay(root, {'a/content/scripts/local/p.ws': b'same'}), files)
            with self.assertRaises(ValueError):
                cmf_pin_stage.settings_overlay(root, {'a/content/scripts/local/p.ws': b'different'})
            (root/'Mods/a/content/en.w3strings').write_bytes(b'changed')
            with self.assertRaises(ValueError):
                cmf_pin_stage.settings_overlay(root, {})


def layered(edits, header):
    """One CMF function as the build writes it: its text from the edit that adds it, with every later edit whose
    find lies inside it applied in order (edits apply one after another to the export)."""
    first = [i for i, e in enumerate(edits) if header in e['replace'] and header not in e['find']]
    assert len(first) == 1, header
    body = edits[first[0]]['replace']
    body = body[body.index(header):]
    body = body[:body.index('\n      }\n') + 9]
    for e in edits[first[0] + 1:]:
        if body.count(e['find']) == 1:
            body = body.replace(e['find'], e['replace'])
    return body


class SourceTests(unittest.TestCase):
    def test_edits_cover_exactly_fourteen_classes(self):
        # The retained name identifies the old contract; API13 explicitly adds four native classes and one helper.
        from test_cmf_rev13_map_consumers import applied
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))
        self.assertEqual(edits['schema'], 'cmf-panel-edits-1')
        native = {
            'com/gskinner/motion/GTween.as',
            *('red/game/witcher3/' + name for name in (
                'data/StaticMapPinData.as', 'menus/worldmap/StaticMapPinDescribed.as',
                'menus/worldmap/data/CategoryPinData.as', 'menus/worldmap/HubMapPinPanel.as',
                'menus/worldmap/HubMapPinCategoryItemRenderer.as', 'menus/worldmap/HubMap.as',
                'menus/worldmap/MapMenu.as', 'menus/worldmap/HubMapContainer.as', 'tooltips/TooltipMap.as',
                'controls/InputFeedbackButton.as', 'controls/KeyboardButtonIcon.as',
                'menus/worldmap/UniverseMap.as', 'menus/worldmap/UniverseMapContainer.as',
                'menus/worldmap/MapCrosshair.as', 'menus/worldmap/PinPointersManager.as',
                'menus/worldmap/HubMapPreview.as', 'menus/common_menu/ModuleInputFeedback.as')),
        }
        self.assertEqual(set(edits['classes']), native)
        helper = 'red/game/witcher3/menus/worldmap/CMFMovieMap.as'
        self.assertEqual(edits['addedClasses'], [helper])
        self.assertEqual(edits['addedScripts'], {'script_476.as':
            'include "red/game/witcher3/menus/worldmap/MapMenu.as";\n'
            'include "red/game/witcher3/menus/worldmap/CMFMovieMap.as";\n\n'
            'Extensions.enabled = true;\nExtensions.noInvisibleAdvance = true;\n'})
        for path, changes in edits['classes'].items():
            for change in changes:
                self.assertGreaterEqual(change['count'], 1)
                self.assertNotEqual(change['find'], change['replace'])
            # Exact application counts replace the obsolete assumption that every later edit only inserts lines.
            self.assertTrue(applied(path), path)

    def test_hubmap_and_mapmenu_carry_the_recompile_lines_and_n4(self):
        from test_cmf_rev13_map_consumers import applied
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        hub_edits = classes['red/game/witcher3/menus/worldmap/HubMap.as']
        menu_edits = classes['red/game/witcher3/menus/worldmap/MapMenu.as']
        self.assertEqual(hub_edits[0]['find'].replace('param2:Number = NaN, param3:Number = NaN',
                          'param2:* = undefined, param3:* = undefined'), hub_edits[0]['replace'])
        self.assertEqual(menu_edits[0]['find'].replace('.getInstance().init(', '.getInstance()["init"]('),
                         menu_edits[0]['replace'])
        hub = applied('red/game/witcher3/menus/worldmap/HubMap.as')
        menu = applied('red/game/witcher3/menus/worldmap/MapMenu.as')
        for expected, source in (
                ('param2:* = undefined, param3:* = undefined', hub),
                ('PinPointersManager.getInstance()["init"](this.mcPointersCanvas);', menu),
                ('if((_loc3_.cmfLabelHide & 2) == 0)', hub),
                ('-38 - Math.max(this._selectedPinAvatar.tfLabel.textHeight,19)', hub),
                ('this.tooltipInstance.y = this.TOOLTIP_POS - this.tooltipInstance.actualHeight;', menu)):
            self.assertTrue(expected in source, expected)
        # Later approved map changes are not N4-only edits. Retain the actual N4 no-claim gate instead.
        from test_cmf_rev10 import body
        placement = body(menu, 'private function cmfPlaceTooltip(')
        gate = 'if(this.cmfDescMaxH <= 0 && MapMenu.cmfNum("tooltip","tallMinHeight",0,this.m_selectedPinData) <= 0)'
        self.assertTrue(gate in placement, 'no height/tall-box claim keeps the native bottom anchor')
        branch = body(placement, gate)
        self.assertTrue('this.TOOLTIP_POS - this.tooltipInstance.actualHeight' in branch)
        self.assertTrue(branch.rstrip().endswith('return;\n         }'))

    def test_version10_panel_names(self):
        # Revision 10 build contract (plans/2026-10-24-cmf-rev10-build-contract.md) sections 4 and 5: wide and tall
        # screens, names on hover and the two opening keys, under CMF's own names only.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        code = {name: ''.join(e['replace'] for e in edits) for name, edits in classes.items()}
        data = code['red/game/witcher3/data/StaticMapPinData.as']
        for line in ('public var cmfHoverName:int = 0;', 'public var cmfHoverNameBy:String = "";'):
            self.assertIn(line, data)
        menu = code['red/game/witcher3/menus/worldmap/MapMenu.as']
        for line in ('protected function cmfWideLayout() : void',
                     'public static function cmfWideX(param1:Number, param2:Boolean) : Number',
                     'public static function cmfWideY(param1:Number, param2:Boolean) : Number',
                     'public function cmfSetScreen(param1:Object) : void',
                     'var rect:Rectangle = CommonUtils.getScreenRect();',
                     'dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFScreen",[Math.round(param2),Math.round(param3)]));',
                     '"wide off (fill 0)" : "wide off (16:9)"',
                     '"wide screen=" + Math.round(rect.width) + "x" + Math.round(rect.height) + " window=" + ',
                     '" unstretch=" + (stretched ? 1 : 0) + " panels=" + panels + " maxRatio=" + cap + " world=" + world',
                     'PinPointersManager.getInstance()["init"](this.mcPointersCanvas);',
                     'this.mcHubMap.cmfVisibleAreaChanged(this.mcVisibleArea);',
                     'this.mcUniverseMap.cmfWideWorld(', 'MapMenu.cmfNum("opening","revealEase",0) != 0',
                     'this.mcHubMapPinPanel.x += MapMenu.cmfSideL;',
                     'this.cmfWideTween(this.mcHubMapPinPanel,"x",MapMenu.cmfSideL);',
                     'public static var cmfWideL:Number = 0;', 'public static var cmfWideR:Number = 1920;',
                     'public static var cmfWideB:Number = 1080;', 'public static var cmfSideL:Number = 0;',
                     'public static var cmfSideR:Number = 0;', 'public static var cmfSideD:Number = 0;'):
            self.assertIn(line, menu)
        self.assertTrue(re.search(r'CMF_TEXT_KEYS:String = "[^"]*,wideAnchor,";', menu))
        hub = code['red/game/witcher3/menus/worldmap/HubMap.as']
        self.assertIn('if(MapMenu.cmfNum("opening","readyAtFadeStart",0) != 0)\n         {\n'
                      '            this._fadingInCompleted = true;', hub)
        self.assertIn('_loc2_.cmfTagShown(true);\n            _loc2_.cmfHoverHide();', hub)
        pin = code['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as']
        self.assertIn('this.cmfHoverLabel(_loc1_);\n         this.cmfThemeLabel();', pin)
        self.assertIn('if(Boolean(d) && !this.isAvatar && (d.cmfHoverName & 1) != 0)', pin)
        container = code['red/game/witcher3/menus/worldmap/HubMapContainer.as']
        self.assertIn('new Point(MapMenu.cmfWideR,MapMenu.cmfWideBottom(MapMenu.cmfNum("map","bottom",1080)))', container)
        self.assertIn('public function cmfWideWorld(param1:Number) : void',
                      code['red/game/witcher3/menus/worldmap/UniverseMap.as'])

    def test_version10_configui_keeps_the_opening_time_first(self):
        # Ultrawide Menus' patcher leaves a map alone whose configUI does not start with super.configUI(); that is
        # what keeps a frozen copy of CMF's map out of its folder (ultrawide spec 5.8).
        menu = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes'][
            'red/game/witcher3/menus/worldmap/MapMenu.as']
        head = '      override protected function configUI() : void\n      {\n'
        owners = [e for e in menu if head in e['find'] or head in e['replace']]
        self.assertEqual(len(owners), 1)
        self.assertEqual(owners[0]['find'], head + '         super.configUI();\n')
        self.assertTrue(owners[0]['replace'].startswith(head + '         this._cmfOpenedAt = getTimer();\n'))
        self.assertLess(owners[0]['replace'].index('this._cmfOpenedAt = getTimer();'),
                        owners[0]['replace'].index('super.configUI();'))

    def test_version10_screen_listener_comes_before_the_theme_call(self):
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes'][
            'red/game/witcher3/menus/worldmap/MapMenu.as']
        menu = ''.join(e['replace'] for e in edits)
        create = layered(edits, 'protected function cmfCreateTheme() : void')
        register = 'dispatchEvent(new GameEvent(GameEvent.REGISTER,"cmf.map.screen",[this.cmfSetScreen]));'
        self.assertEqual(menu.count(register), 1)
        self.assertLess(create.index(register),
                        create.index('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMapThemeReady"));'))
        # The opening's shifts start from 16:9 before anything can read them.
        self.assertLess(create.index('MapMenu.cmfWideScale = 1;'), create.index(register))

    def test_version10_wide_gate_returns_before_any_member_write(self):
        # Rule 1 of the ultrawide spec: on a 16:9 rect, or with fill 0, the layout writes no member, so the map is
        # 1.3.0's pixel for pixel. Every member write lives in cmfWideApply, reached only past the gate (or to undo
        # an earlier layout of the same opening).
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes'][
            'red/game/witcher3/menus/worldmap/MapMenu.as']
        menu = ''.join(e['replace'] for e in edits)
        body = layered(edits, 'protected function cmfWideLayout() : void')
        gate = body.index('if(fill == 0 || rect.width <= 1922 && rect.height <= 1082 && !stretched)')
        block = body[gate:body.index('\n            }\n', gate)]
        self.assertFalse(re.search(r'\bthis\.\w+(\.\w+)*\s*[-+*/]?=[^=]', body[:gate]), body[:gate])
        self.assertNotIn('cmfWideApply(', body[:gate])
        self.assertTrue(block.rstrip().endswith('return;'))
        self.assertIn('if(this._cmfWideOn)\n               {\n                  this.cmfWideApply(1,0,1920,1080,0,0,0,0);',
                      block)
        self.assertFalse(re.search(r'\bthis\.\w+(\.\w+)*\s*[-+*/]?=[^=]', body), 'cmfWideLayout writes a member')
        self.assertFalse(re.search(r'(?<![\w.])(x|y|scaleX|scaleY)\s*=[^=]', body))
        # The theme hand-off runs it after the styles are stored and before the first placement.
        self.assertIn('this.cmfWideArrived();\n            if(this._cmfThemeGot)', menu)
        self.assertIn('if(this._cmfWideGot)\n         {\n            this.cmfWideLayout();\n         }\n'
                      '         if(MapMenu.cmfStyles)', menu)

    def test_core_ships_no_art(self):
        # Kyle 2026-10-20 18:05Z: placeholder art lives in the adapter that needs it, never in CMF.
        self.assertFalse((ROOT/'source/core/art').exists())
        self.assertNotIn("CORE + '/content/texture.cache'", (ROOT/'tools/cmf_pin_stage.py').read_text(encoding='utf-8'))

    def test_tag_claims_reach_pins_other_mods_push_by_the_tags_game_id(self):
        # Kyle 2026-10-20 05:19Z: one mod adds a signpost, another targets it by its id.
        core = (ROOT/'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='ascii')
        late = core[core.index('public function FillMissingPinFields'):core.index('private function LateTag')]
        self.assertIn('pinTag = LateTag(dataObject);', late)
        for call in ('HideOwner(dataObject, pinType, filtered, pinTag, maxLevel, mapContext)',
                     'WriteTabHide(dataObject, pinType, filtered, pinTag, maxLevel)',
                     'WriteFields(dataObject, pinType, filtered, pinTag, maxLevel, mapContext)'):
            self.assertIn(call, late)
        self.assertLess(late.index('LateTag(dataObject)'), late.index('OnPinReady(dataObject, mapContext)'))
        tag = core[core.index('private function LateTag'):core.index('public function OnPinReady')]
        # Version 11 (opening speed): the tag claims' game ids are worked out once per preparation, from the winners,
        # hides, tab hides and added info lines, in that order.
        self.assertIn('tagIds[i] == id', tag)
        lookups = core[core.index('private function NoteLookups'):core.index('private function PropertyWon')]
        order = [lookups.index(f'{name}.Size()') for name in ('winners', 'hideClaims', 'tabHideClaims', 'infoAdds')]
        self.assertEqual(order, sorted(order))
        note = core[core.index('private function NoteLookupClaim'):core.index('// Version 11: keeps the info box add')]
        self.assertIn('tagIds.PushBack(NameToFlashUInt(claim.pinTag));', note)
        self.assertIn('id = dataObject.GetMemberFlashUInt("id");', tag)

    def test_panel_names_no_other_mod_except_marked_compatibility_fields(self):
        # Kyle 2026-10-20 05:02Z-05:19Z: CMF exposes general abilities and names no mod. The one exception the
        # engine forces: StaticMapPinData must declare the pin fields other mods write, or the game drops them
        # before their adapters can read them. Those sit after one marking comment and are read nowhere in the panel.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        data = classes['red/game/witcher3/data/StaticMapPinData.as'][0]['replace']
        head, marker, compat = data.partition('      // Compatibility names, not read by CMF:')
        self.assertTrue(marker)
        self.assertEqual(re.findall(r'public var (\w+):', compat),
                         ['qmiLevelText', 'iaiLv', 'iaiDiff', 'qmiIconScale', 'qmiIconTop', 'qmiIconKind',
                          'qmiNoCrosshairLabel', 'qmiIconTint'])
        self.assertFalse([n for n in re.findall(r'public var (\w+):', head) if not n.startswith(('cmf', 'objScriptName'))])
        rest = ''.join(e['replace'] for name, edits in classes.items() for e in edits
                       if name != 'red/game/witcher3/data/StaticMapPinData.as')
        pattern = r"\b(?:qmi\w*|iai\w*|\w*Gwm\w*|\w*Ink[A-Z]\w*|(?:[A-Za-z0-9_]*[a-z0-9_])?ink[A-Z]\w*|inkiron\w*)"
        self.assertIsNone(re.search(pattern, rest))
        for foreign in ('qmiApi', 'iaiLv', 'OtherGwmField', 'OnInkHints', 'CMFInkHints', 'XInkHints', 'inkHints', 'myinkHints', 'inkironState'):
            with self.subTest(foreign=foreign):
                self.assertIsNotNone(re.search(pattern, foreign), foreign)
        self.assertIsNone(re.search(pattern, 'cmfLinkDrawings'))

    def test_n4_panel_reads_only_cmfs_own_fields(self):
        # N4 spec (a design note kept in the private development repository) section 8.1.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        pin = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'])
        hub = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/HubMap.as'])
        menu = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/MapMenu.as'])
        for alias in ('qmiIconScale', 'qmiIconTop', 'qmiLevelText', 'iaiLv'):
            self.assertNotIn(alias, pin + hub)
        self.assertIn('this.cmfApplyPinScale(_loc1_);\n         this.cmfApplyIconTint(_loc1_);\n'
                      '         this.cmfApplyIconArt(_loc1_);', pin)
        self.assertIn('_loc2_.indexOf("frame:") == 0', pin)
        self.assertIn('if((_loc3_.cmfLabelHide & 2) == 0)', hub)
        self.assertIn('-38 - Math.max(this._selectedPinAvatar.tfLabel.textHeight,19)', hub)
        # Map Quest Insight's handshake is answered by its adapter in script, not by the panel.
        self.assertNotIn('qmiApi', menu)
        self.assertNotIn('qmiDescMaxH', menu)
        for line in ('public var cmfDescMaxH:Number = 0;', 'public var cmfDescMaxBy:String = "";',
                     '"gui_global_scroll_description_failed" : "gui_global_scroll_description"',
                     '"input_feedback_scroll_text"', '_loc5_ - this._cmfStickTime < 450', 'beginFill(12102296,1)'):
            self.assertIn(line, menu)
        self.assertNotIn('qmiFastMap', menu)
        # The box stays the game's while no claim sets a height and no theme sets a tall-box place (version 12).
        self.assertIn('this.tooltipInstance.y = this.TOOLTIP_POS - this.tooltipInstance.actualHeight;\n'
                      '            this.cmfPlaceTooltip();', menu)
        self.assertIn('if(this.cmfDescMaxH <= 0 && MapMenu.cmfNum("tooltip","tallMinHeight",0) <= 0)\n         {\n'
                      '            return;', menu)

    def test_mapmenu_hint_row_listens_on_cmfs_own_names(self):
        # Ink and Iron adapter design (PR #22) P4, under CMF's own names (Kyle 2026-10-20 05:02Z): the map
        # registers "cmf.map.hints" and calls OnCMFMapHintsReady; any mod may send a hint list there (the Ink and
        # Iron adapter sends Ink and Iron's). The legacy copy keeps ignoring keys and the mouse; API13 owns a separate route.
        from test_cmf_rev13_map_consumers import applied
        code = applied('red/game/witcher3/menus/worldmap/MapMenu.as')
        self.assertEqual(code.count('dispatchEvent(new GameEvent(GameEvent.REGISTER,"cmf.map.hints",'
                                    '[this.cmfSetHintCopy]));'), 1)
        self.assertEqual(code.count('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMapHintsReady"));'), 1)
        self.assertEqual(code.count('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMapHints"));'), 1)
        self.assertNotIn('inkiron', code.lower())
        self.assertNotIn('OnInk', code)
        for line in ('this.cmfHintCopy.filterKeyCodeFunction = this.cmfHintCopyIgnoresInput;',
                     'this.cmfHintCopy.filterNavCodeFunction = this.cmfHintCopyIgnoresInput;',
                     'this.cmfHintCopy.clickable = false;', 'this.cmfHintCopy.mouseEnabled = false;',
                     'this.cmfHintCopy.mouseChildren = false;', 'this.cmfCreateHintCopy();'):
            self.assertIn(line, code)
        self.assertRegex(code, r'cmfHintCopyIgnoresInput\(param1:\*\) : Boolean\n      \{\n         return false;')
        from test_cmf_rev10 import body
        hints = body(code, 'protected function cmfCreateHintCopy(')
        self.assertNotIn('appendButton', hints)
        self.assertEqual(code.count('this.cmfCreateHintCopy();'), 1)
        self.assertTrue('this.cmfHintCopy.clickable = this._cmfHintOwner != "";' in code)
        self.assertTrue('this.cmfHintCopy.mouseChildren = this._cmfHintOwner != "";' in code)
        # CMF 1.6.3 (player's overlap report, 2026-10-28): the managed list joins the game's own row through
        # InputFeedbackManager; CMF's copy always shows the legacy list, so the two never sit on top of each other.
        owned = body(code, 'public function cmfSetOwnedHints(')
        self.assertIn('this.cmfRowOwnedHints();', owned)
        self.assertIn('if(this._cmfLegacyHints) { this.cmfRenderHintCopy(this._cmfLegacyHints); }', owned)
        self.assertNotIn('this._cmfOwnedHints : this._cmfLegacyHints', owned)
        row = body(code, 'protected function cmfRowOwnedHints(')
        self.assertIn('InputFeedbackManager.removeButton(this,id);', row)
        self.assertIn('"cmf:" + String(item.label)', row)
        self.assertIn('InputFeedbackManager.updateButtons(this);', row)
        legacy = body(code, 'public function cmfSetHintCopy(')
        self.assertNotIn('_cmfHintOwner', legacy)
        self.assertIn('action = this.cmfRowHintAction(action);', body(code, 'protected function cmfHintAction('))

    def test_theme_panel_listens_on_cmfs_name_and_matches_the_core_lists(self):
        from test_cmf_rev13_map_consumers import applied
        from rev13_legacy_source import theme_environment
        from rev13_panel_vm import load_case
        from types import SimpleNamespace as Obj
        import os
        menu = applied('red/game/witcher3/menus/worldmap/MapMenu.as')
        for event in ('dispatchEvent(new GameEvent(GameEvent.REGISTER,"cmf.map.theme",[this.cmfSetTheme]));',
                      'dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMapThemeReady"));'):
            self.assertEqual(menu.count(event), 1, event)
        core = SCRIPTS[0].read_text(encoding='ascii')
        env = theme_environment(core)
        text_keys = re.search(r'CMF_TEXT_KEYS:String = ",([^"]*),";', menu).group(1).split(',')
        self.assertEqual(len(text_keys), len(set(text_keys)))
        # Every actual core text key must occur in the applied panel list; ordering is immaterial to membership.
        from test_cmf_rev10 import body
        literals = ''.join(re.findall(r'"([^"]*)"', body(core, 'function CMFThemeTextKey(')))
        self.assertEqual(set(text_keys), set(literals.split(',')))
        for key in text_keys:
            self.assertTrue(env['CMFThemeTextKey'](key), key)
        self.assertFalse(env['CMFThemeTextKey']('notAThemeTextKey'))
        self.assertIn('allText', text_keys)
        specimen = Path(os.environ['CMF_REV13_PANEL'])
        case = load_case(specimen, 'MapMenu', {})
        self.assertEqual(case.call_static('cmfValue', Obj(y='allText', s='Heading', n=17)), 'Heading')
        self.assertEqual(re.search(r'CMF_LAYERS:Array = \[([^\]]*)\]', menu).group(1).replace('"', '').split(','),
                         env['CMFThemeLayers']().split(','))
        drawn = re.search(r'CMF_DRAWN_PARTS:Array = \[([^\]]*)\]', menu).group(1).replace('"', '').split(',')
        excluded = {'keyCap', 'navigation', 'markerPanel', 'pinButton', 'mapSpace', 'opening', 'spread', 'wide',
                    'sounds', 'world'}
        self.assertEqual(drawn, [part for part in env['CMFThemeParts']().split(',') if part not in excluded])
        # Approved later edits replace methods, not just add lines. Require their exact applications and retained hooks.
        for path, hook in (
                ('menus/worldmap/HubMapContainer.as', 'cmfCaptureVisibleArea'),
                ('tooltips/TooltipMap.as', 'cmfTextStyle'),
                ('controls/InputFeedbackButton.as', 'cmfTextStyleFor'),
                ('controls/KeyboardButtonIcon.as', 'cmfTextStyleValue')):
            self.assertTrue(hook in applied('red/game/witcher3/' + path), hook)

    def test_theme_fixes_from_launch_t1(self):
        # Launch T1 (2026-10-20): names below fast-travel pins are their own part (pinName), so level-tag styles and
        # drawings on pinLabel leave them as the game draws them; a hidden legend row drops its glow; the map's
        # top/bottom keys also size the area the map draws its tiles and pins in (MapMenu.mcVisibleArea).
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        pin = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'])
        self.assertIn('part = !d.isFastTravel && this.cmfShowsLevelText(d) ? "pinLabel" : "pinName";', pin)
        self.assertIn('param2 == "pinLabel" ? MapMenu.cmfPinLabelDrawings : MapMenu.cmfPinNameDrawings', pin)
        menu = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/MapMenu.as'])
        self.assertIn('MapMenu.cmfPinNameDrawings = parts["pinName"] as Array;', menu)
        self.assertIn('this.cmfUnglowText(o as DisplayObject,"legendRow",0);', menu)
        self.assertIn('this.cmfDrawBackdrop();\n            this.cmfMapArea();', menu)
        self.assertIn('this.mcHubMap.cmfVisibleAreaChanged(this.mcVisibleArea);', menu)
        hub = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/HubMap.as'])
        self.assertIn('if(this.mcHubMapZoomContainer.mcHubMapContainer.cmfCaptureVisibleArea(param1))', hub)
        # Relaunch T1: the movie's unnamed 1920x880 timeline mask (y 96-976) still clipped the map; it moves too.
        self.assertIn('this.cmfMapMask(top,bottom);', menu)
        self.assertIn('Math.abs(o.width - 1920) < 4 && Math.abs(o.height - 880) < 4', menu)
        self.assertIn('this._cmfMapMask.height = param2 - param1;', menu)
        core = SCRIPTS[0].read_text(encoding='ascii')
        from rev13_legacy_source import theme_environment
        env = theme_environment(core)
        self.assertEqual(env['CMFThemePartKeys']('pinName').split(','),
                         ['font', 'size', 'color'] + env['CMFThemeShadowKeys']().split(','))

    def test_legend_collapses_and_reports_its_box(self):
        # Launch set C (2026-10-20): the legend's long list stayed up over its frame; with a theme the list returns
        # to the short list wherever the game clears _expandedList, and the panel logs the measured legend box.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        panel = classes['red/game/witcher3/menus/worldmap/HubMapPinPanel.as']
        collapse = [e for e in panel if e['find'] == '         this._expandedList = false;\n']
        self.assertEqual(len(collapse), 1)
        self.assertEqual(collapse[0]['count'], 2)
        self.assertIn('this.cmfCollapseList();', collapse[0]['replace'])
        self.assertIn('this.mcHubMapPinCategoryList.itemRendererList = this._renderersListShort;',
                      ''.join(e['replace'] for e in panel))
        menu = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/MapMenu.as'])
        self.assertIn('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFPanelNote",[note]));', menu)
        core = SCRIPTS[0].read_text(encoding='ascii')
        self.assertIn('event OnCMFPanelNote(note : string)\n{\n\tCMFLog("panel " + note);\n}', core)

    def test_ink_and_iron_level_takes_the_localized_prefix(self):
        # Ink and Iron adapter design (PR #22) P1, now the general CMFLevelLabel (N4; Kyle 2026-10-20 05:05Z:
        # CMF exposes general calls and adapters translate): "Lv" comes from CMF's string block in the journal
        # colours; the bare number shows when the string is missing.
        catalog = json.loads((ROOT/'source/strings.json').read_text(encoding='utf-8'))
        self.assertIn({'id': 2000200008, 'key': 'cmf_map_level_prefix', 'text': {'en': 'Lv'}}, catalog['strings'])
        core = SCRIPTS[0].read_text(encoding='ascii')
        self.assertIn('GetLocStringByKeyExt("cmf_map_level_prefix")', core)
        self.assertIn('return "<font color=\'" + color + "\'>" + prefix + " " + level + "</font>";', core)
        self.assertIn('return "<font color=\'" + color + "\'>" + level + "</font>";', core)
        edits = (ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8')
        self.assertNotIn('cmfLevelPrefix', edits)

    def test_version2_api_matches_the_approved_spec(self):
        # Adapters and packs compile against these exact names (a design note kept in the private development repository).
        core = SCRIPTS[0].read_text(encoding='ascii')
        for line in ('function CMFPropertyLegendRow() : int { return 6; }',
                     'function CMFPropertyLegendLabel() : int { return 7; }',
                     'function CMFPropertyLegendCategory() : int { return 8; }',
                     'function CMFStylePin(provider : string, dataObject : CScriptedFlashObject, propertyId : int, '
                     'text : string,\n\tnumber : int) : bool',
                     'function CMFStylePinIcon(provider : string, dataObject : CScriptedFlashObject, url : string) : bool',
                     'function CMFStylePinTint(provider : string, dataObject : CScriptedFlashObject, rgb : int) : bool',
                     'function CMFRegisterLegendRow(provider : string, filteredType : name, category : name, priority : int)',
                     'function CMFRegisterLegendLabel(provider : string, filteredType : name, label : string)',
                     'function CMFRegisterLegendCategory(provider : string, category : name, label : string, priority : int)'):
            self.assertIn(line, core)
        # Version 1 calls are never removed.
        for name in ('CMFRegisterIcon', 'CMFRegisterLegendIcon', 'CMFRegisterTint', 'CMFRegisterIconForTag',
                     'CMFRegisterBackground', 'CMFRegisterDisabled', 'CMFRegisterDisabledForTag', 'CMFReleaseProvider',
                     'CMFRequireVersion', 'CMFRegister', 'CMFRegisterForTag', 'CMFHasProperty'):
            self.assertIn('function %s(' % name, core)

    def test_version3_api_matches_the_approved_spec(self):
        # a design note kept in the private development repository, section 7.1.
        core = SCRIPTS[0].read_text(encoding='ascii')
        for line in ('function CMFPropertyHidden() : int { return 9; }',
                     'function CMFRegisterHidden(provider : string, pinType : name, mapContext : name, '
                     'exemptions : string, hide : bool)',
                     'function CMFRegisterHiddenForTag(provider : string, pinTag : name, mapContext : name, '
                     'exemptions : string, hide : bool)',
                     'function CMFHidePin(provider : string, dataObject : CScriptedFlashObject) : bool',
                     'function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void',
                     # Exemption flags are 2, 4 and 8 already; launch S1-1 lost "quest" when they were doubled.
                     'incoming.text = CMFExemptionText(flags);',
                     'incoming.number = 1 + flags;'):
            self.assertIn(line, core)
        # Version 2 calls are never removed.
        for name in ('CMFPropertyLegendRow', 'CMFPropertyLegendLabel', 'CMFPropertyLegendCategory', 'CMFStylePin',
                     'CMFStylePinIcon', 'CMFStylePinTint', 'CMFRegisterLegendRow', 'CMFRegisterLegendLabel',
                     'CMFRegisterLegendCategory'):
            self.assertIn('function %s(' % name, core)

    def test_version4_api_matches_the_approved_spec(self):
        # a design note kept in the private development repository, sections 7.1 and 8.2.
        core = SCRIPTS[0].read_text(encoding='ascii')
        for line in ('function CMFPropertyPinScale() : int { return 10; }',
                     'function CMFPropertyLabelPlace() : int { return 11; }',
                     'function CMFPropertyLabelText() : int { return 12; }',
                     'function CMFPropertyLabelHide() : int { return 13; }',
                     'function CMFPropertyInfoBoxHeight() : int { return 14; }',
                     'function CMFPropertyTabHide() : int { return 15; }',
                     'return (propertyId >= CMFPropertyIcon() && propertyId <= CMFPropertyTabHide()) || '
                     'propertyId == CMFPropertyLabelColor() ||',
                     'function CMFStylePinScale(provider : string, dataObject : CScriptedFlashObject, percent : int) : bool',
                     'function CMFStylePinLabel(provider : string, dataObject : CScriptedFlashObject, html : string) : bool'):
            self.assertIn(line, core)
        # Version 3 calls are never removed.
        for name in ('CMFPropertyHidden', 'CMFRegisterHidden', 'CMFRegisterHiddenForTag', 'CMFHidePin'):
            self.assertIn('function %s(' % name, core)

    def test_version5_api_matches_the_approved_spec(self):
        # a design note kept in the private development repository, sections 4.1 and 4.7 (signatures sent to the
        # adapter thread 2026-10-20; clicks keep id 16 and take version 6).
        core = SCRIPTS[0].read_text(encoding='ascii')
        # The version number itself moved on with version 6 (tests/test_cmf_pin_clicks.py).
        for line in ('function CMFPropertyLabelColor() : int { return 17; }',
                     'function CMFStylePart(provider : string, part : name, key : name, text : string, number : float) : bool',
                     'function CMFDraw(provider : string, anchor : name, id : name, kind : name) : bool',
                     'function CMFDrawSet(provider : string, id : name, key : name, text : string, number : float) : bool',
                     'function CMFHasAbility(part : name, key : name) : bool',
                     'event OnCMFMapThemeReady()',
                     'storage.SetFlashArray("cmf.map.theme", flashArray);'):
            self.assertIn(line, core)
        # Version 4 calls and hooks are never removed.
        for name in ('CMFPropertyPinScale', 'CMFPropertyLabelPlace', 'CMFPropertyLabelText', 'CMFPropertyLabelHide',
                     'CMFPropertyInfoBoxHeight', 'CMFPropertyTabHide', 'CMFStylePinScale', 'CMFStylePinLabel',
                     'CMFLevelLabel'):
            self.assertIn('function %s(' % name, core)

    def test_theme_names_match_the_pack_tool(self):
        # cmf_pack.py checks theme calls offline against its own copy of the names; keep the two in step.
        sys.path.insert(0, str(ROOT/'tools'))
        import cmf_pack
        core = SCRIPTS[0].read_text(encoding='ascii')

        def listed(function, case=None):
            if case:
                body = core[core.index('function %s(' % function):]
                body = body[body.index("case '%s':" % case):]
                body = body[:body.index(';')]
            else:
                body = core[core.index('function %s(' % function):]
                body = body[body.index('{'):]
                body = body[:body.index(';')]
            words = []
            for part in re.findall(r'"([^"]*)"|(CMFTheme\w+)\(\)', body):
                if part[0]:
                    words.extend(w for w in part[0].split(',') if w)
                else:
                    words.extend(listed(part[1]))
            return words

        self.assertEqual(listed('CMFThemeParts'), list(cmf_pack.THEME_PART_KEYS))
        self.assertEqual(listed('CMFThemeLayers'), list(cmf_pack.THEME_LAYERS))
        self.assertEqual(listed('CMFThemeKinds'), list(cmf_pack.THEME_KIND_KEYS))
        for part, keys in cmf_pack.THEME_PART_KEYS.items():
            if keys:
                self.assertEqual(listed('CMFThemePartKeys', part), list(keys), part)
            else:
                self.assertNotIn("case '%s':" % part, core[core.index('function CMFThemePartKeys('):
                                                          core.index('function CMFThemeHideWords(')])

    def test_core_reads_no_other_mods_names(self):
        # Kyle 2026-10-20 05:02Z/05:05Z: no mod-specific calls in CMF; adapters translate other mods' fields
        # through CMF's general calls and the OnPinReady/OnMapReady hooks.
        core = SCRIPTS[0].read_text(encoding='ascii')
        for name in ('"qmi', '"iai', 'modMapQuestInsight', 'modInkAndIron'):
            self.assertNotIn(name, core)
        for line in ('public function OnPinReady(dataObject : CScriptedFlashObject, mapContext : name)',
                     'public function OnMapReady(menuFlash : CScriptedFlashSprite)',
                     'function CMFLevelLabel(level : int, difficulty : int) : string'):
            self.assertIn(line, core)

    def test_scripts_are_ascii_lf_tabs(self):
        for path in SCRIPTS:
            data = path.read_bytes()
            self.assertTrue(all(b < 128 for b in data), path)
            self.assertNotIn(b'\r', data, path)
            for line in data.decode('ascii').splitlines():
                self.assertFalse(line.startswith(' '), '%s: %r' % (path.name, line))

    def test_pin_field_names_match_panel_edits(self):
        edits = (ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8')
        core = SCRIPTS[0].read_text(encoding='ascii')
        for field in ('cmfIconPath', 'cmfLegendIconPath', 'cmfIconTint', 'cmfIconTintEnabled', 'cmfLegendTint',
                      'cmfLegendTintEnabled', 'cmfDone', 'cmfDisabled', 'cmfLegendCategory', 'cmfLegendPriority',
                      'cmfLegendLabel', 'cmfCategoryLabel', 'cmfCategoryPriority', 'cmfRowHide', 'cmfIconBy',
                      'cmfTintBy', 'cmfHiddenBy', 'cmfIconScale', 'cmfLabelPlace', 'cmfLabelText', 'cmfLabelHide',
                      'cmfTabHide', 'cmfScaleBy', 'cmfPlaceBy', 'cmfLabelBy', 'cmfLabelHideBy', 'cmfTabHideBy',
                      'cmfLabelColor', 'cmfLabelColorEnabled', 'cmfLabelColorBy', 'cmfSpreadRank', 'cmfSpreadRankBy',
                      'cmfCategoryNoDefault'):
            self.assertIn('"%s"' % field, core)
            self.assertIn('public var %s' % field, edits)

    def test_renderers_never_reuse_an_image_loader(self):
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))
        for path in ('red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as',
                     'red/game/witcher3/menus/worldmap/HubMapPinCategoryItemRenderer.as'):
            code = ''.join(change['replace'] for change in edits['classes'][path])
            request = code[code.index('private function cmfRequestIconArt'):code.index('private function cmfDropIconLoader')]
            self.assertLess(request.index('this.cmfDropIconLoader();'), request.index('new Loader()'), path)
            self.assertNotIn('if(!this._cmfIconLoader)', request, path)
            self.assertIn('.unload();', code, path)


if __name__ == '__main__':
    unittest.main()
