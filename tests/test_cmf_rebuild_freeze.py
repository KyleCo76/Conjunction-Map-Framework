"""Rebuild freeze: the previous build's anonymous-pin animation keys are dropped when a build starts; art counts reach the log."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='utf-8')
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']


def body(text, head):
    i = text.index(head)
    j = text.index('\n\t}\n', i)
    return text[i:j]


class ObjectKeysDropped(unittest.TestCase):
    def test_begin_build_forgets_object_keys(self):
        self.assertIn('AnimationForgetObjects();', body(CORE, '\tpublic function BeginBuild('))

    def test_forget_drops_bindings_keys_and_pins_together(self):
        b = body(CORE, '\tprivate function AnimationForgetObjects()')
        self.assertIn('StrBeginsWith(animationBindings[i].pinKey, "object/")', b)
        self.assertIn('animationBindings.Erase(i);', b)
        self.assertIn('animationBindingKeys.Erase(i);', b)
        self.assertIn('animationPins.Clear();', b)

    def test_tag_and_id_keyed_bindings_are_untouched(self):
        b = body(CORE, '\tprivate function AnimationForgetObjects()')
        self.assertNotIn('tag/', b)
        self.assertNotIn('id/', b)

    def test_ascii_tabs_only(self):
        b = body(CORE, '\tprivate function AnimationForgetObjects()')
        b.encode('ascii')
        self.assertFalse(re.search(r'^ +', b, re.M))


class ArtCountsInLog(unittest.TestCase):
    def test_split_note_ends_with_art_counts(self):
        hub = next(v for k, v in EDITS.items() if k.endswith('HubMap.as'))
        e = next(e for e in hub if 'StaticMapPinDescribed.cmfArtCounts()' in e['replace'])
        self.assertIn('" finalize=" + (getTimer() - cmfT1) + " art=" + StaticMapPinDescribed.cmfArtCounts()', e['replace'])

    def test_counts_are_loads_then_reused(self):
        pin = next(v for k, v in EDITS.items() if k.endswith('StaticMapPinDescribed.as'))
        e = next(e for e in pin if 'public static function cmfArtCounts' in e['replace'])
        self.assertIn('_cmfArtMisses + "/" + StaticMapPinDescribed._cmfArtHits', e['replace'])


if __name__ == '__main__':
    unittest.main()


class SplitParts(unittest.TestCase):
    pin = staticmethod(lambda: next(v for k, v in EDITS.items() if k.endswith('StaticMapPinDescribed.as')))
    hub = staticmethod(lambda: next(v for k, v in EDITS.items() if k.endswith('HubMap.as')))

    def text(self):
        return ''.join(e['replace'] for e in self.pin() if 'cmfSplit' in e['replace'])

    def test_every_step_of_update_has_a_lap_and_nothing_runs_when_off(self):
        t = self.text()
        for slot in range(9):
            self.assertIn('cmfSplitLap(%d,' % slot, t)
        self.assertIn('if(!StaticMapPinDescribed.cmfSplitOn)\n         {\n            this.cmfUpdateBody();\n            return;', t)

    def test_laps_run_in_the_order_of_the_calls(self):
        t = self.text()
        order = ['cmfApplyIconArt(_loc1_);', 'cmfApplyUnder(_loc1_);', 'cmfApplyPinLook();', 'cmfAnimationAttach(this);',
                 'cmfApplyPinAlpha(_loc1_);', 'cmfOrderWithinParent();', 'updateLabel();']
        at = [t.index(o, t.index('var cmfS:Boolean')) for o in order]
        self.assertEqual(at, sorted(at))

    def test_new_versus_reused_clip_count_per_instance(self):
        t = self.text()
        self.assertIn('private var _cmfSplitSeen:Boolean = false;', t)
        self.assertIn('StaticMapPinDescribed._cmfSplitNew++;', t)

    def test_hubmap_brackets_only_process_map_pins(self):
        e = next(e for e in self.hub() if 'cmfSplitStart();' in e['replace'])['replace']
        self.assertEqual(e.index('cmfSplitStart();') < e.index('this.processMapPins(true);') < e.index('cmfSplitOn = false;'), True)
        self.assertTrue(any('cmfSplitNote(cmfT1 - cmfT)' in e['replace'] for e in self.hub()))


class RebuildSafety(unittest.TestCase):
    pin = staticmethod(lambda: next(v for k, v in EDITS.items() if k.endswith('StaticMapPinDescribed.as')))
    hub = staticmethod(lambda: next(v for k, v in EDITS.items() if k.endswith('HubMap.as')))

    def class_text(self):
        """Every replace of the class in order: enough to see which names the class imports and uses."""
        return ''.join(e['replace'] for e in self.pin())

    def test_free_functions_used_by_the_pin_class_are_imported(self):
        text = self.class_text()
        for name in ('getTimer', 'getDefinitionByName', 'getQualifiedClassName'):
            if name + '(' in text:
                self.assertIn('import flash.utils.%s;' % name, text, name)

    def test_other_new_names_are_imported(self):
        text = self.class_text()
        for name in ('Bitmap', 'BitmapData', 'DisplayObject', 'Loader', 'URLRequest', 'IOErrorEvent', 'SecurityErrorEvent'):
            self.assertRegex(text, r'import flash\.\w+\.%s;' % name)

    def test_full_pin_update_catches_and_logs_and_clears_the_split_flag(self):
        e = next(x for x in self.hub() if 'pins update failed step=process' in x['replace'])['replace']
        self.assertEqual(e.count('catch('), 2)
        self.assertIn('"pins update failed step=process error=" + cmfError.name + ": " + cmfError.message', e)
        self.assertIn('"pins update failed step=finalize error=" + cmfError2.name + ": " + cmfError2.message', e)
        self.assertLess(e.index('catch(cmfError:Error)'), e.index('StaticMapPinDescribed.cmfSplitOn = false;'))

    def test_loader_events_ignore_a_bitmap_view(self):
        guards = [e for e in self.pin() if 'is Loader) ||' in e['replace']]
        self.assertEqual(len(guards), 2)


class DoubleUpdateGuard(unittest.TestCase):
    pin = staticmethod(lambda: next(v for k, v in EDITS.items() if k.endswith('StaticMapPinDescribed.as')))

    def edit(self, text):
        return next(e for e in self.pin() if text in e['replace'])

    def test_state_change_skips_when_data_and_state_are_as_drawn(self):
        r = self.edit('skippedState++' if False else '_cmfSplitSkipped++;')['replace']
        self.assertIn('if(this._cmfDrawnData == data && this._cmfDrawnState == this.cmfDrawState())', r)
        self.assertLess(r.index('return;'), r.index('this.update();'))

    def test_update_records_what_it_draws_before_drawing(self):
        r = self.edit('this._cmfDrawnData = data;')['replace']
        self.assertLess(r.index('this._cmfDrawnData = data;'), r.index('this.cmfUpdateBody();'))

    def test_state_that_picks_the_picture_is_selected_and_avatar(self):
        r = self.edit('private function cmfDrawState() : int')['replace']
        self.assertIn('(selected ? 1 : 0) + (this.isAvatar ? 2 : 0)', r)

    def test_the_note_reports_frame_and_the_state_counts(self):
        r = ''.join(e['replace'] for e in self.pin())
        for word in ('" frame=" + s[10]', '" fromState="', '" skippedState="'):
            self.assertIn(word, r)

    def test_frame_jump_is_lapped_on_its_own_slot(self):
        r = self.edit('var cmfF:int')['replace']
        self.assertIn('cmfSplitLap(10,cmfF)', r)
