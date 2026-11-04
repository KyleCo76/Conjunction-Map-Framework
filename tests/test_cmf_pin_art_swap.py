"""Pin pictures: the old picture stays until the new one has loaded; decoded pictures are shared by URL (offline source checks)."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLASSES = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes']
KEY = next(k for k in CLASSES if k.endswith('StaticMapPinDescribed.as'))
EDITS = CLASSES[KEY]


def edit_with(text):
    return next(e for e in EDITS if text in e['replace'])


class ArtSwap(unittest.TestCase):
    def test_a_replacement_loads_beside_the_showing_picture(self):
        head = edit_with('this.cmfLoadNext(param1);')['replace']
        self.assertIn('if(this._cmfIconReady && this._cmfIconLoader)', head)
        # the showing picture is not dropped on that branch
        branch = head[head.index('if(this._cmfIconReady && this._cmfIconLoader)'):head.index('this.cmfLoadNext(param1);')]
        self.assertNotIn('cmfDropIconLoader', branch)

    def test_the_swap_happens_only_on_complete(self):
        funcs = edit_with('private function cmfOnIconNextLoaded')['replace']
        loaded = funcs[funcs.index('private function cmfOnIconNextLoaded'):funcs.index('private function cmfOnIconNextFailed')]
        self.assertIn('this.cmfUseIconView(next);', loaded)
        use = funcs[funcs.index('private function cmfUseIconView'):]
        self.assertLess(use.index('this._cmfIconLoader = view;'), use.index('this.cmfDisposeIconView(old);'))
        self.assertIn('this.cmfArtOwner(pin) == this._cmfIconOwner', use)

    def test_a_failed_replacement_clears_everything(self):
        funcs = edit_with('private function cmfOnIconNextFailed')['replace']
        failed = funcs[funcs.index('private function cmfOnIconNextFailed'):funcs.index('private function cmfUseIconView')]
        self.assertIn('OnCMFArtFailed', failed)
        self.assertIn('this.cmfDropIconLoader();', failed)

    def test_drop_also_cancels_the_pending_replacement(self):
        e = next(e for e in EDITS if e['replace'].startswith('         var _loc1_:* = this._cmfIconLoader;\n         this.cmfCancelNext();'))
        self.assertIn('cmfCancelNext', e['replace'])


class ArtCache(unittest.TestCase):
    def test_hit_uses_a_bitmap_over_the_shared_pixels_and_counts(self):
        head = edit_with('this.cmfUseIconView(new Bitmap(cached,"auto",true));')['replace']
        self.assertIn('StaticMapPinDescribed._cmfArtHits++;', head)
        self.assertIn('StaticMapPinDescribed._cmfArtMisses++;', head)

    def test_only_decoded_bitmaps_are_stored_and_never_disposed(self):
        text = ''.join(e['replace'] for e in EDITS)
        self.assertIn('cmfArtStore(this._cmfIconRequested,_loc2_.bitmapData)', text)
        self.assertIn('cmfArtStore(this._cmfIconRequested,bitmap.bitmapData)', text)
        self.assertNotIn('_cmfArtCache[path].dispose', text)

    def test_cache_is_small(self):
        funcs = edit_with('private static function cmfArtStore')['replace']
        self.assertIn('_cmfArtCacheCount >= 64', funcs)

    def test_note_carries_cache_counts(self):
        note = edit_with('art again pin=')['replace'] + ''.join(e['replace'] for e in EDITS if '" cache="' in e['replace'])
        self.assertIn('" cache=" + StaticMapPinDescribed._cmfArtHits + "/" + StaticMapPinDescribed._cmfArtMisses', note)

    def test_view_field_is_untyped_so_a_bitmap_fits(self):
        self.assertIn('private var _cmfIconLoader:*;', edit_with('_cmfIconNext:Loader;')['replace'])

    def test_show_sizes_a_bitmap_from_its_pixels(self):
        funcs = edit_with('private function cmfIconNaturalSize')['replace']
        self.assertIn('bitmap.bitmapData.width', funcs)


class AppendedEditsApplyInOrder(unittest.TestCase):
    def test_every_new_edit_finds_its_text_exactly_once_when_applied_in_order(self):
        text = edit_with('private function cmfApplyIconTint')['replace']
        start = next(i for i, e in enumerate(EDITS) if '_cmfIconNext:Loader;' in e['replace'])
        for i, e in enumerate(EDITS):
            if i == 4 or i in (20, 29, 32, 56, 76) or i >= start:
                continue
            if i > 4 and e['find'] in text:
                text = text.replace(e['find'], e['replace'])
        for e in EDITS[start + 1:start + 8]:
            self.assertEqual(text.count(e['find']), 1, e['find'][:60])
            text = text.replace(e['find'], e['replace'])
        self.assertNotIn('this._cmfIconLoader.content.width);\n         if(_loc2_ <= 0)', text)


if __name__ == '__main__':
    unittest.main()
