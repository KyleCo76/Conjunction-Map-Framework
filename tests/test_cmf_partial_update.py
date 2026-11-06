"""Pin clip recycling in a full pin update (panel, API 17, general ability map/partialUpdate). Source checks and Python models."""
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'tests'), str(ROOT / 'tools')]
from test_cmf_make_button import ws_body

CLASSES = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text())['classes']
PIN = CLASSES['red/game/witcher3/menus/worldmap/StaticMapPinDescribed.as']
HUB = CLASSES['red/game/witcher3/menus/worldmap/HubMap.as']
MENU = CLASSES['red/game/witcher3/menus/worldmap/MapMenu.as']
DATA = CLASSES['red/game/witcher3/data/StaticMapPinData.as']
CORE = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='utf-8')
SETTINGS = (ROOT / 'source/core/content/scripts/local/cmfSettings.ws').read_text(encoding='utf-8')
XML = (ROOT / 'source/settings/menus/mod0000_ConjunctionMapFramework.xml').read_text(encoding='utf-8')
VANILLA_FIELDS = ['id', 'type', 'filteredType', 'label', 'description', 'posX', 'posY', 'radius', 'tracked', 'highlighted',
                  'areaId', 'journalAreaId', 'rotation', 'isFastTravel', 'isQuest', 'isPlayer', 'isUserPin', 'distance',
                  'hidden', 'questScriptName']
# CreatePin sets these again on a reused clip (place, offset, rotation) or nothing draws from them (distance).
NOT_COMPARED = ['posX', 'posY', 'rotation', 'distance', 'cmfPinOffsetX', 'cmfPinOffsetY', 'cmfPinOffsetEnabled',
                # Seam S14: the grid keep marks (set by the core, read by no panel drawing).
                'cmfGridKeep', 'cmfGridKeepBy']
# Names other mods write into the pin; no panel code reads them (tests/test_cmf_pin_fields.py), so they cannot change a drawing.
COMPAT_NOT_READ = ['qmiLevelText', 'iaiLv', 'iaiDiff', 'qmiIconScale', 'qmiIconTop', 'qmiIconKind', 'qmiNoCrosshairLabel',
                   'qmiIconTint', 'aqoomCachedPin', 'wmkIcon', 'aqoomRowLabel']


def edit_with(edits, text):
    return next(e for e in edits if text in e['replace'])


def last_edit_with(edits, text):
    return [e for e in edits if text in e['replace']][-1]


def method_body(name):
    match = re.search(r'private function ' + name + r'\([^{]*\)\n\t\{(.*?)\n\t\}', CORE, re.S)
    assert match, name
    return match.group(1)


def function_text(edits, name):
    text = ''.join(e['replace'] for e in edits)
    start = text.index('function ' + name)
    end = text.index('\n      }\n', start)
    return text[start:end]


class SignatureCoversEveryField(unittest.TestCase):
    def declared(self):
        text = ''.join(e['replace'] for e in DATA)
        return re.findall(r'(?:public|private)\s+var\s+(\w+)\s*:', text) + VANILLA_FIELDS

    def test_every_data_field_is_compared_or_named_as_set_again_by_create_pin(self):
        body = function_text(PIN, 'cmfSameDrawn')
        compared = re.findall(r'if\(a\.(\w+) != b\.\1\) \{ return false; \}', body)
        self.assertEqual(sorted(set(compared) | set(NOT_COMPARED) | set(COMPAT_NOT_READ)), sorted(set(self.declared())))
        self.assertEqual(len(compared), len(set(compared)))
        self.assertFalse(set(compared) & (set(NOT_COMPARED) | set(COMPAT_NOT_READ)))

    def test_the_compat_names_left_out_are_read_by_no_panel_code(self):
        text = ''.join(e['replace'] for edits in CLASSES.values() for e in edits if edits is not DATA)
        for name in COMPAT_NOT_READ:
            self.assertNotRegex(text, r'\b' + name + r'\b')

    def test_compared_fields_cover_what_update_reads(self):
        text = ''.join(e['replace'] for e in PIN)
        read = set(re.findall(r'\b(?:_loc1_|pin)\.(\w+)', text)) & set(self.declared())
        body = function_text(PIN, 'cmfSameDrawn')
        for field in read:
            self.assertTrue(field in NOT_COMPARED or ('a.%s != b.%s' % (field, field)) in body, field)

    def test_update_returns_early_while_rebinding_after_it_records_what_it_would_have_drawn(self):
        e = edit_with(PIN, 'if(this.cmfRebinding)')
        text = e['replace']
        self.assertLess(text.index('this._cmfDrawnState = this.cmfDrawState();'), text.index('if(this.cmfRebinding)'))
        self.assertLess(text.index('this.cmfDrawnEpoch'), text.index('if(this.cmfRebinding)'))
        self.assertLess(text.index('if(this.cmfRebinding)'), text.index('if(!StaticMapPinDescribed.cmfSplitOn)'))

    def test_rebind_always_clears_its_flag(self):
        body = function_text(PIN, 'cmfRebind')
        self.assertIn('finally', body)
        self.assertLess(body.index('this.setData(newData);'), body.index('finally'))
        self.assertIn('this.cmfRebinding = false;', body[body.index('finally'):])

    def test_a_clip_keeps_its_pictures_only_while_the_pool_holds_it(self):
        e = edit_with(PIN, 'if(StaticMapPinDescribed.cmfPoolHold)')
        self.assertTrue(e['find'].startswith('         this.cmfDropIconLoader();'))
        self.assertLess(e['replace'].index('cmfPoolHold'), e['replace'].index('this.cmfDropIconLoader();'))

    def test_a_new_theme_makes_every_older_clip_stale(self):
        e = edit_with(MENU, 'StaticMapPinDescribed.cmfThemeEpoch++;')
        self.assertTrue(e['find'].startswith('      public function cmfSetTheme('))
        recycled = function_text(HUB, 'cmfRecycledPin')
        self.assertIn('pin.cmfDrawnEpoch != StaticMapPinDescribed.cmfThemeEpoch', recycled)


# The vanilla CreatePin, read from the compiled panel: the order of its steps.
VANILLA_STEPS = ['cmfNativeOrder = idx', 'SetWorldPosition(', 'UpdateMapPosition2(', 'cmfRebind(d)', 'cmfApplyZoom(zoom)',
                 'InitPingAnimation()', 'UpdateHighlighting()', 'this._staticMapPins[idx] = pin', 'validateNow()',
                 'this.addPinChild(pin)', 'pin.mcIcon.rotation = d.rotation', 'pin.mcIcon.rotation = 0']


class RecycledClipEndsLikeAFreshOne(unittest.TestCase):
    def test_same_steps_in_the_same_order_as_create_pin(self):
        body = function_text(HUB, 'cmfRecycledPin')
        at = -1
        for step in VANILLA_STEPS:
            found = body.find(step, at + 1)
            self.assertGreater(found, at, step)
            at = found

    def test_create_pin_wrapper_keeps_the_original_for_everything_else(self):
        e = edit_with(HUB, 'cmfCreatePinNew')
        self.assertEqual(e['find'], '      private function CreatePin(param1:StaticMapPinData, param2:int, param3:Number) : StaticMapPinDescribed')
        wrapper = e['replace']
        self.assertIn('if(this._cmfPoolOn && param1.type != "")', wrapper)
        self.assertTrue(wrapper.rstrip().endswith('private function cmfCreatePinNew(param1:StaticMapPinData, param2:int, param3:Number) : StaticMapPinDescribed'))
        self.assertIn('return this.cmfCreatePinNew(param1,param2,param3);', wrapper)

    def test_child_order_model_recycled_equals_full(self):
        """Model: ClearPins removes every clip, CreatePin adds in list order; reuse changes which clip, not the order."""
        listing = [('a', 1), ('b', 2), ('c', 3), ('d', 4)]
        old_clips = {k: object() for k, _ in listing}

        def build(new_list, pool):
            canvas, fresh, reused = [], 0, 0
            for key, sig in new_list:
                if pool is not None and key in pool and pool[key][1] == sig:
                    clip = pool.pop(key)[0]
                    reused += 1
                else:
                    clip = object()
                    fresh += 1
                canvas.append((key, clip))
            return canvas, fresh, reused

        new_list = [('d', 4), ('a', 1), ('e', 5), ('c', 3), ('b', 9)]
        full, f_fresh, _ = build(new_list, None)
        pool = {k: (old_clips[k], s) for k, s in listing}
        recycled, r_fresh, r_reused = build(new_list, pool)
        self.assertEqual([k for k, _ in full], [k for k, _ in recycled])
        self.assertEqual(f_fresh, 5)
        self.assertEqual((r_reused, r_fresh), (3, 2))
        for key, clip in recycled:
            if key in ('d', 'a', 'c'):
                self.assertIs(clip, old_clips[key])

    def test_the_clip_goes_back_through_add_pin_child_so_the_order_code_runs_for_it(self):
        self.assertIn('this.addPinChild(pin);', function_text(HUB, 'cmfRecycledPin'))
        self.assertIn('param1.cmfOrderWithinParent()', ''.join(e['replace'] for e in HUB))

    def test_a_reused_clip_is_attached_to_the_animation_again_after_it_is_back_on_the_map(self):
        # ClearPins takes the clip off the stage, which detaches its animation (cmfAnimationRemoved); the held draw step
        # that would attach it again does not run on a reused clip, so cmfRecycledPin attaches it once it is added back.
        body = function_text(HUB, 'cmfRecycledPin')
        attach = 'MapMenu.cmfMenu.cmfAnimationAttach(pin);'
        self.assertIn(attach, body)
        self.assertLess(body.index('this.addPinChild(pin);'), body.index(attach))


def suffixed(keys):
    """Model of cmfPoolKey: the n-th repeat of a key is key#n; an empty key stays out."""
    seen, out = {}, []
    for key in keys:
        if key == '':
            continue
        seen[key] = seen.get(key, 0) + 1
        out.append(key if seen[key] == 1 else '%s#%d' % (key, seen[key]))
    return out


def decide(prev_ok, switch_on, old, new, hold_ok=True):
    """Python model of cmfPoolBegin: the reason for a full rebuild, or '' for recycling. old/new are lists of keys ('' = no key)."""
    if not switch_on:
        return 'off'
    if not prev_ok:
        return 'previous build failed'
    if not new:
        return 'no pins'
    if not old:
        return 'no clips to reuse'
    pool = set(suffixed(old))
    if not pool:
        return 'no clips to reuse'
    matched = sum(key in pool for key in suffixed(new))
    if matched * 2 < len(new):
        return 'under half matched'
    return ''


class BailOuts(unittest.TestCase):
    def test_model_cases(self):
        self.assertEqual(decide(True, True, ['a', 'b'], ['a', 'b', 'c']), '')
        self.assertEqual(decide(True, False, ['a'], ['a']), 'off')
        self.assertEqual(decide(False, True, ['a'], ['a']), 'previous build failed')
        # empty and repeated keys never throw the pool away: repeats get an occurrence suffix, empties get fresh clips
        self.assertEqual(decide(True, True, ['a', ''], ['a']), '')
        self.assertEqual(decide(True, True, ['a', 'a'], ['a', 'a']), '')
        self.assertEqual(decide(True, True, ['a'], ['a', 'a', 'b']), 'under half matched')
        self.assertEqual(decide(True, True, ['', ''], ['a']), 'no clips to reuse')
        self.assertEqual(decide(True, True, ['a', 'b'], ['x', 'y', 'z', 'a']), 'under half matched')
        self.assertEqual(decide(True, True, [], ['a']), 'no clips to reuse')

    def test_source_has_each_reason_in_the_same_order_as_the_model(self):
        body = function_text(HUB, 'cmfPoolBegin')
        reasons = ['"off"', '"previous build failed"', '"no pins"', '"no clips to reuse"', '"under half matched"']
        at = -1
        for reason in reasons:
            found = body.find(reason, at + 1)
            self.assertGreater(found, at, reason)
            at = found
        self.assertIn('matched * 2 < data.length', body)
        self.assertIn('MapMenu.cmfNum("opening","pinRecycle",1) == 0', body)

    def test_key_names_the_area_the_ids_and_the_type(self):
        body = function_text(HUB, 'cmfPinKey')
        for part in ('d.areaId', 'd.id', 'd.type', 'd.questScriptName', 'd.objScriptName'):
            self.assertIn(part, body)
        self.assertIn('d.id == 0', body)
        self.assertIn('"p/" + d.areaId + "/" + d.type + "/" + d.posX', body)

    def test_suffix_model_duplicates_and_empties_among_normal_keys(self):
        self.assertEqual(suffixed(['a', 'b', 'a', '', 'a']), ['a', 'b', 'a#2', 'a#3'])
        old = ['a', 'b', 'a', '', 'c']
        new = ['c', 'a', 'a', 'b', '']
        self.assertEqual(decide(True, True, old, new), '')
        self.assertEqual(sum(k in set(suffixed(old)) for k in suffixed(new)), 4)

    def test_source_counts_every_kind_and_logs_the_first_three_offenders(self):
        note = function_text(HUB, 'cmfPoolNote')
        for part in ('oldPins=', 'emptyOld=', 'dupOld=', 'emptyNew=', 'dupNew=', 'posKeyed=', 'pool=', ' first: ', 'cmfKidCounts()'):
            self.assertIn(part, note)
        self.assertIn('< 3', function_text(HUB, 'cmfPoolSample'))
        self.assertIn('staticPins=', function_text(HUB, 'cmfKidCounts'))
        self.assertIn('canvasKids=', function_text(HUB, 'cmfKidCounts'))
        self.assertIn('this.cmfPoolKey(d,this._cmfPoolSeen)', function_text(HUB, 'cmfRecycledPin'))

    def test_stamps_list_received_and_first_frame_after_finalize(self):
        text = ''.join(e['replace'] for e in HUB)
        self.assertIn('"pins list received sinceData="', text)
        self.assertIn('"pins update first frame after finalize ms="', text)
        self.assertIn('addEventListener(Event.ENTER_FRAME,this.cmfFrameAfter,false,0,true);', text)
        self.assertIn('public function cmfSinceData() : int', ''.join(e['replace'] for e in MENU))

    def test_a_clip_is_taken_once_and_only_when_unselected_unparented_and_same(self):
        body = function_text(HUB, 'cmfRecycledPin')
        self.assertIn('delete this._cmfPool[key];', body)
        for guard in ('pin.parent', 'pin.isAvatar', 'pin.selected', 'cmfSameDrawn(pin.data as StaticMapPinData,d)'):
            self.assertIn(guard, body)
        self.assertLess(body.index('delete this._cmfPool[key];'), body.index('pin.cmfNativeOrder = idx;'))

    def test_a_failed_build_makes_the_next_one_full_and_the_pool_is_always_closed(self):
        bracket = edit_with(HUB, 'this.cmfPoolBegin();')['replace']
        self.assertIn('this._cmfPoolBuildOk = false;', bracket)
        self.assertIn('this._cmfPoolBuildOk = false;', last_edit_with(HUB, 'pins update failed step=finalize')['replace'])
        end = edit_with(HUB, 'this.cmfPoolEnd();\n         StaticMapPinDescribed.cmfSplitOn = false;')
        self.assertLess(end['replace'].index('this.cmfPoolEnd();'), end['replace'].index('cmfT1 = getTimer();'))
        self.assertIn('StaticMapPinDescribed.cmfPoolHold = false;', function_text(HUB, 'cmfPoolEnd'))
        self.assertIn('this._cmfPoolBuildOk = true;', function_text(HUB, 'cmfPoolBegin'))
        self.assertIn('var failed:Boolean = !this._cmfPoolBuildOk', function_text(HUB, 'cmfPoolBegin'))

    def test_begin_comes_before_the_clips_are_cleared_and_unused_clips_are_released(self):
        e = edit_with(HUB, 'this.cmfPoolBegin();')['replace']
        self.assertLess(e.index('this.cmfPoolBegin();'), e.index('this.initializeMapPinsProcessing();'))
        end = function_text(HUB, 'cmfPoolEnd')
        self.assertIn('left.cmfReleaseArt();', end)
        hold_on = edit_with(HUB, 'StaticMapPinDescribed.cmfPoolHold = this._cmfPoolOn;')['replace']
        self.assertLess(hold_on.index('cmfPoolHold = this._cmfPoolOn'), hold_on.index('var _loc2_:StaticMapPinDescribed'))
        hold_off = edit_with(HUB, 'StaticMapPinDescribed.cmfPoolHold = false;\n         var below:Sprite')['replace']
        self.assertTrue(hold_off.startswith('         this._staticMapPins.length = 0;'))

    def test_note_names_mode_reason_and_every_count(self):
        body = function_text(HUB, 'cmfPoolNote')
        for part in ('pins update recycle mode=', ' reason=', ' reused=', ' changed=', ' fresh=', ' unused=', ' beginMs=', ' endMs='):
            self.assertIn(part, body)
        e = edit_with(HUB, 'this.cmfNote(this.cmfPoolNote());')
        self.assertTrue(e['find'].endswith('cmfSplitNote(cmfT1 - cmfT));'))

    def test_selection_is_cleared_before_the_clips_are_pooled(self):
        """UnselectPin (vanilla initializeMapPinsProcessing) runs after Begin has only read the clips, and the selected pin's
        avatar copy is not in the pool; a selected clip is refused by cmfRecycledPin."""
        pool = {}
        pins = [('a', False), ('b', True)]       # b is the selected one
        for key, selected in pins:
            pool[key] = selected
        # b removed from the new list: its clip stays in the pool and is released, the others are untouched
        new = ['a']
        taken = [k for k in new if k in pool and not pool[k]]
        left = [k for k in pool if k not in taken]
        self.assertEqual((taken, left), (['a'], ['b']))
        self.assertIn('pin.selected', function_text(HUB, 'cmfRecycledPin'))


class HiddenSwitchAndAbility(unittest.TestCase):
    def test_file_setting_reads_off_only_for_the_off_words(self):
        body = ws_body(SETTINGS, 'CMFSettingsPinRecycle')
        self.assertIn("GetVarValue('CMFSettings', 'CMFPinRecycle')", body)
        self.assertIn('value != "false" && value != "0" && value != "off"', body)

    def test_declared_hidden_with_no_menu_entry(self):
        self.assertRegex(XML, r'<Var id="CMFPinRecycle" value="true"[^>]*visibilityCondition="hideAlways"/>')
        for menu in (ROOT / 'source/menu/modCMFInGameMenu.xml', ROOT / 'source/menu/strings.json'):
            self.assertNotIn('CMFPinRecycle', menu.read_text(encoding='utf-8'))

    def test_only_the_off_answer_is_sent_with_the_theme(self):
        body = method_body('SendPinRecycle')
        self.assertLess(body.index('if (CMFSettingsPinRecycle())'), body.index('item = storage.CreateTempFlashObject();'))
        self.assertIn('"pinRecycle"', body)
        self.assertIn('SendPinRecycle(flashArray, storage);', CORE[CORE.index('public function SendTheme('):])
        self.assertIn('SetMemberFlashNumber("n", 0)', body)

    def test_ability_added_and_version_unchanged(self):
        self.assertIn("if (part == 'map' && key == 'partialUpdate') { return true; }", ws_body(CORE, 'CMFHasAbility'))
        self.assertRegex(ws_body(CORE, 'CMFGetVersion'), r'return 18;')

    def test_the_key_is_not_an_author_key(self):
        keys = ws_body(CORE, 'CMFThemeOpeningKeys')
        self.assertNotIn('pinRecycle', keys)

    def test_ws_files_stay_ascii_tabs_lf(self):
        for text in (CORE, SETTINGS):
            self.assertFalse(re.search(r'[^\x00-\x7f]', text))
            self.assertNotIn('\r', text)


class FindsAreMadeByEarlierEdits(unittest.TestCase):
    def test_each_new_find_is_made_by_an_earlier_edit_and_no_edit_between_overlaps_it(self):
        for edits, markers in ((PIN, ('cmfRebinding', 'cmfPoolHold')), (HUB, ('cmfPool', '_cmfPool')), (MENU, ('cmfThemeEpoch',))):
            first = next(i for i, e in enumerate(edits) if any(m in e['replace'] for m in markers))
            for at in range(first, len(edits)):
                e = edits[at]
                made = [i for i in range(at) if e['find'] in edits[i]['replace']]
                if not made:
                    continue
                for i in range(max(made) + 1, at):
                    self.assertNotIn(e['find'], edits[i]['find'], (at, i))
                    self.assertNotIn(edits[i]['find'], e['find'], (at, i))


if __name__ == '__main__':
    unittest.main()
