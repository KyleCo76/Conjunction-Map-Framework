"""Pin-field rebuild tooling: packager, texture cache writer, panel edits and scripts.

Fixture cases read ignored build/panel-runs evidence and skip when it is absent;
a skipped case is not qualification.
"""
import difflib
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


class SourceTests(unittest.TestCase):
    def test_edits_cover_exactly_fourteen_classes(self):
        # Smooth map movement (P6) adds UniverseMap and the tween library's GTween to the eleven; version 9 adds
        # UniverseMapContainer (world overview pictures).
        edits = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))
        self.assertEqual(edits['schema'], 'cmf-panel-edits-1')
        self.assertEqual(len(edits['classes']), 14)
        for path, changes in edits['classes'].items():
            self.assertTrue((path.startswith('red/game/witcher3/') or path == 'com/gskinner/motion/GTween.as') and
                            path.endswith('.as'), path)
            for change in changes:
                self.assertGreaterEqual(change['count'], 1)
                self.assertNotEqual(change['find'], change['replace'])
                self.assertIn(change['find'].strip().splitlines()[0], change['replace'])

    def test_hubmap_and_mapmenu_carry_the_recompile_lines_and_n4(self):
        # Stage 2 round trip: the two lines FFDec 26.3.0 needs, as Map Pin Teleport 1.2.2 (CenterOnPin) and
        # Fog of War 1.2.1 (pointer-manager init) ship them. The other edits add the Ink and Iron key-hint copy
        # (P4) and N4 (pin size, labels, the info box, tab hiding); only the lines listed here change vanilla code.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        hub = classes['red/game/witcher3/menus/worldmap/HubMap.as']
        menu = classes['red/game/witcher3/menus/worldmap/MapMenu.as']
        self.assertEqual(hub[0]['find'].replace('param2:Number = NaN, param3:Number = NaN',
                                                'param2:* = undefined, param3:* = undefined'), hub[0]['replace'])
        self.assertEqual(menu[0]['find'].replace('.getInstance().init(', '.getInstance()["init"]('), menu[0]['replace'])
        changed = {'         this.mcHubMapCrosshair.showLabel(_loc3_.label,true);'}
        # Smooth map movement (P6): the game's timings and zoom limit become theme values whose defaults are the
        # game's own constants, and a snap keeps the fade tweens when an opening key is set.
        changed |= {
            '            _loc2_ = Math2.clamp(_loc2_,this._minZoom,this._maxZoom);',
            '            _loc3_ = Math2.clamp(_loc3_,this._minZoom,this._maxZoom);',
            '         return Math.abs(this.mcHubMapZoomContainer.scaleX - this._minZoom) < 0.001 && '
            'Math.abs(this.mcHubMapZoomContainer.scaleY - this._minZoom) < 0.001;',
            '            _loc5_ = Math.min(this._mapPinDataIndex + MAX_PROCESSED_PIN_COUNT,this._mapPinDataArray.length);',
            '         this._initialTimer = new Timer(20);',
            '         if(this._menuAnimCompleted)',
            '         this._showMapTimer = new Timer(SHOW_INTERVAL);',
            '         GTweener.to(this.mcHubMapZoomContainer.mcHubMapContainer.mcGradientContainer,FADING_GRADIENT_DURATION,',
            '         GTweener.to(this.mcHubMapZoomContainer.mcHubMapContainer.mcLodContainer,FADING_TEXTURES_DURATION,',
            '         GTweener.to(this.mcHubMapPinContainer,FADING_GRADIENT_DURATION,',
            '               GTweener.removeTweens(this.mcHubMapZoomContainer.mcHubMapContainer);',
            '               GTweener.removeTweens(this.mcHubMapPinContainer);',
        }
        # Quest rows (API version 6): a quest pin with its own row claim is hidden by that row's key.
        changed |= {
            '               if(_loc10_.isPlayer || _loc10_.isUserPin && param2 && !param5.hasOwnProperty(HubMapPinPanel.'
            'USER_PIN_TYPE) || _loc10_.isFastTravel && param3 || _loc10_.isQuest && param4 && !param5.hasOwnProperty('
            'HubMapPinPanel.QUEST_PIN_TYPE) || _loc12_.hasOwnProperty(_loc10_.filteredType) && !param5.hasOwnProperty('
            '_loc10_.filteredType))',
        }
        # Spreading stacked pins (launch D3): the selected pin's copy takes its pin's own place while the pin is
        # in a row; otherwise the game's line places it as before.
        changed |= {
            '            _loc2_ = this._selectedPinAvatar.GetWorldPosition();',
            '            this._selectedPinAvatar.UpdateMapPosition2(this.WorldXToMapX(_loc2_.x) * param1,this.WorldYToMapY'
            '(_loc2_.y) * param1);',
        }
        # Blur at the opening (rerun 4): like the game's CenterOnPlayer, the default place and the middle ask for map
        # squares only once the menu's opening animation is over.
        changed |= {'         this.mcHubMapZoomContainer.mcHubMapContainer.ShowTilesFromCurrentLod();'}
        for edit in hub[1:] + menu[1:]:
            ops = difflib.SequenceMatcher(None, edit['find'].split('\n'), edit['replace'].split('\n')).get_opcodes()
            for tag, i1, i2, _j1, _j2 in ops:
                if tag in ('replace', 'delete'):
                    self.assertTrue(set(edit['find'].split('\n')[i1:i2]) <= changed, edit['find'])

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
        self.assertEqual(tag.count('NameToFlashUInt('), 3)
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
                          'qmiNoCrosshairLabel', 'qmiIconTint', 'uireScale', 'uireHideLabel', 'uireLevelLabel',
                          'uireLevel', 'uireLevelColor'])
        self.assertFalse([n for n in re.findall(r'public var (\w+):', head) if not n.startswith(('cmf', 'objScriptName'))])
        rest = ''.join(e['replace'] for name, edits in classes.items() for e in edits
                       if name != 'red/game/witcher3/data/StaticMapPinData.as')
        self.assertFalse(re.findall(r'\b(qmi\w*|iai\w*|uire\w*|\w*Gwm\w*|\w*[Ii]nk[A-Z]\w*|inkiron\S*)', rest))

    def test_n4_panel_reads_only_cmfs_own_fields(self):
        # N4 spec (a design note kept in the private development repository) section 8.1.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        pin = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as'])
        hub = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/HubMap.as'])
        menu = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/MapMenu.as'])
        for alias in ('qmiIconScale', 'qmiIconTop', 'qmiLevelText', 'iaiLv', 'uireScale', 'uireHideLabel'):
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
        # The box stays the game's while no claim sets a height.
        self.assertIn('this.tooltipInstance.y = this.TOOLTIP_POS - this.tooltipInstance.actualHeight;\n'
                      '            this.cmfPlaceTooltip();', menu)
        self.assertIn('if(this.cmfDescMaxH <= 0)\n         {\n            return;', menu)

    def test_mapmenu_hint_row_listens_on_cmfs_own_names(self):
        # Ink and Iron adapter design (PR #22) P4, under CMF's own names (Kyle 2026-10-20 05:02Z): the map
        # registers "cmf.map.hints" and calls OnCMFMapHintsReady; any mod may send a hint list there (the Ink and
        # Iron adapter sends Ink and Iron's). The copy never handles a key, a button or the mouse.
        menu = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes'][
            'red/game/witcher3/menus/worldmap/MapMenu.as']
        code = ''.join(e['replace'] for e in menu)
        self.assertEqual(code.count('dispatchEvent(new GameEvent(GameEvent.REGISTER,"cmf.map.hints",'
                                    '[this.cmfSetHintCopy]));'), 1)
        self.assertEqual(code.count('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMapHintsReady"));'), 1)
        self.assertNotIn('inkiron', code.lower())
        self.assertNotIn('OnInk', code)
        for line in ('this.cmfHintCopy.filterKeyCodeFunction = this.cmfHintCopyIgnoresInput;',
                     'this.cmfHintCopy.filterNavCodeFunction = this.cmfHintCopyIgnoresInput;',
                     'this.cmfHintCopy.clickable = false;', 'this.cmfHintCopy.mouseEnabled = false;',
                     'this.cmfHintCopy.mouseChildren = false;', 'this.cmfCreateHintCopy();\n      }\n'):
            self.assertIn(line, code)
        self.assertRegex(code, r'cmfHintCopyIgnoresInput\(param1:\*\) : Boolean\n      \{\n         return false;')
        hints = [e['replace'] for e in menu if 'protected function cmfCreateHintCopy' in e['replace']][0]
        self.assertNotIn('appendButton', hints)

    def test_theme_panel_listens_on_cmfs_name_and_matches_the_core_lists(self):
        # Stage 6b (a design note kept in the private development repository 4.6): the map registers
        # "cmf.map.theme", calls OnCMFMapThemeReady once, and knows the same parts, layers and text keys as cmfCore.
        # Every theme edit only adds lines to the game's classes.
        classes = json.loads((ROOT/'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
        menu = ''.join(e['replace'] for e in classes['red/game/witcher3/menus/worldmap/MapMenu.as'])
        self.assertEqual(menu.count('dispatchEvent(new GameEvent(GameEvent.REGISTER,"cmf.map.theme",[this.cmfSetTheme]));'), 1)
        self.assertEqual(menu.count('dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMapThemeReady"));'), 1)
        core = SCRIPTS[0].read_text(encoding='ascii')

        def core_list(function):
            body = core[core.index('function %s(' % function):]
            return re.search(r'"([^"]*)"', body[body.index('{'):]).group(1).split(',')

        text_keys = re.search(r'CMF_TEXT_KEYS:String = ",([^"]*),";', menu).group(1).split(',')
        listed = core[core.index('function CMFThemeTextKey('):]
        listed = re.search(r'CMFListHas\("([^"]*)" \+\s*"([^"]*)"', listed)
        self.assertEqual(text_keys, (listed.group(1) + listed.group(2)).split(','))
        self.assertEqual(re.search(r'CMF_LAYERS:Array = \[([^\]]*)\]', menu).group(1).replace('"', '').split(','),
                         core_list('CMFThemeLayers'))
        drawn = re.search(r'CMF_DRAWN_PARTS:Array = \[([^\]]*)\]', menu).group(1).replace('"', '').split(',')
        parts = core[core.index('function CMFThemeParts('):]
        parts = ''.join(re.findall(r'"([^"]*)"', parts[:parts.index('}')])).split(',')
        # mapSpace drawings go to the map layer (cmf.map.space), not to the screen-part drawer.
        self.assertEqual(drawn, [p for p in parts if p not in ('keyCap', 'navigation', 'markerPanel', 'pinButton',
                                                               'mapSpace', 'opening', 'spread')])
        for path in ('red/game/witcher3/menus/worldmap/HubMapContainer.as', 'red/game/witcher3/tooltips/TooltipMap.as',
                     'red/game/witcher3/controls/InputFeedbackButton.as',
                     'red/game/witcher3/controls/KeyboardButtonIcon.as'):
            for edit in classes[path]:
                ops = difflib.SequenceMatcher(None, edit['find'].split('\n'), edit['replace'].split('\n'),
                                              autojunk=False).get_opcodes()
                self.assertEqual([tag for tag, *_ in ops if tag in ('replace', 'delete')], [], (path, edit['find']))

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
        self.assertIn("case 'pinName':\n\t\t\treturn \"font,size,\" + CMFThemeShadowKeys();", core)

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
        for name in ('"qmi', '"iai', '"uire', 'modMapQuestInsight', 'modInkAndIron', 'UIRemastered'):
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
