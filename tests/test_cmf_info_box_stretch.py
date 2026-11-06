"""Info box stretch (API 18): four tooltip keys in the core and pack tool, the panel's nearest-clear search with a
Python model, its use in cmfClearTooltip, and the Map Quest Insight adapter's guarded send.

Source tests only: no built panel or game files. The model mirrors cmfStretchPlace line for line.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
"""
import json
import math
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(ROOT / 'tests'))
import cmf_pack
from ws_text import ws_function

CORE = (ROOT / 'source/core/content/scripts/local/cmfCore.ws').read_text(encoding='ascii')
MENU_KEY = 'red/game/witcher3/menus/worldmap/MapMenu.as'
EDITS = json.loads((ROOT / 'source/panel/pin-fields/edits.json').read_text(encoding='utf-8'))['classes'][MENU_KEY]
KEYS = ('stretch', 'stretchMax', 'stretchDirs', 'stretchFlip')


class CoreTests(unittest.TestCase):
    def test_tooltip_takes_the_stretch_keys(self):
        part = ws_function(CORE, 'function CMFThemePartKeys(part : name) : string')
        tooltip = part[part.index("case 'tooltip':"):part.index("case 'preview':")]
        for key in KEYS:
            self.assertIn(key, tooltip, key)
            self.assertIn(key, cmf_pack.THEME_PART_KEYS['tooltip'], key)

    def test_stretch_keys_are_placement_piece_63(self):
        choice = ws_function(CORE, 'public function PartKeyChoice(part : name, key : name) : int')
        start = choice.index('stretch,stretchMax,stretchDirs,stretchFlip')
        piece = choice[start:choice.index('return 63;', start)]
        for key in KEYS:
            self.assertIn(key, piece, key)
            self.assertEqual(cmf_pack.theme_key_row('tooltip', key), 'Map behaviour > Info box moves out of the way')

    def test_stretch_dirs_is_a_text_key_and_accepts_only_the_four_words(self):
        text_keys = ws_function(CORE, 'function CMFThemeTextKey(key : name) : bool')
        self.assertIn('stretchDirs', text_keys)
        ok = ws_function(CORE, 'function CMFThemeValueOk(')
        self.assertIn('key == \'stretchDirs\') { return CMFThemeWordsOk(text, "left,right,up,down"); }', ok)
        issues = cmf_pack.fold_style_literal_issues('tooltip', 'stretchDirs', '"up,sideways", 0)')
        self.assertEqual(issues, ['tooltip.stretchDirs must use left, right, up, down'])
        self.assertEqual(cmf_pack.fold_style_literal_issues('tooltip', 'stretchDirs', '"up,down", 0)'), [])
        self.assertEqual(cmf_pack.fold_style_literal_issues('tooltip', 'stretchDirs', '"", 0)'), [])

    def test_stretch_switches_are_0_or_1_and_max_is_0_to_4000(self):
        ok = ws_function(CORE, 'function CMFThemeValueOk(')
        self.assertRegex(ok, r'k == "stretch" \|\| k == "stretchFlip"\)\s*\{\s*return number == 0 \|\| number == 1;')
        self.assertRegex(ok, r'k == "stretchMax"\)\s*\{\s*return number >= 0 && number <= 4000;')
        self.assertEqual(cmf_pack.fold_style_literal_issues('tooltip', 'stretch', '"", 2)'), ['tooltip.stretch must be 0 or 1'])
        self.assertEqual(cmf_pack.fold_style_literal_issues('tooltip', 'stretchMax', '"", 5000)'),
                         ['tooltip.stretchMax must be 0 to 4000'])
        self.assertEqual(cmf_pack.fold_style_literal_issues('tooltip', 'stretchMax', '"", 400)'), [])

    def test_version_is_18(self):
        self.assertIn('function CMFGetVersion() : int { return 18; }', CORE)

    def test_ability_comment_names_stretch(self):
        self.assertIn("('tooltip', 'stretch')", CORE)


# ---- the model of cmfStretchPlace (rectangles are (left, top, right, bottom), a box is its (x, y) and (w, h)) ----

ALL_DIRS = ('left', 'right', 'up', 'down')


def grow(r, g):
    return (r[0] - g, r[1] - g, r[2] + g, r[3] + g)


def area(a, b):
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    return max(w, 0) * max(h, 0)


def stretch(want, size, anchor, pad, side, limit, soft, hard, max_d=400, dirs=ALL_DIRS, flip=1):
    """Returns (rect or None, pass, tried). Mirrors MapMenu.cmfStretchPlace."""
    w, h = size
    blocks = [grow(anchor, pad)] + [grow(o, 8) for o in hard]
    softs = [grow(o, 8) for o in soft]
    xs = [want[0], limit[0], limit[2] - w]
    ys = [want[1], limit[1], limit[3] - h]
    for o in blocks + softs:
        xs += [o[0] - w, o[2]]
        ys += [o[1] - h, o[3]]
    acx, acy = (anchor[0] + anchor[2]) / 2, (anchor[1] + anchor[3]) / 2
    wcx, wcy = want[0] + w / 2, want[1] + h / 2
    best1 = best2 = None
    tried = 0
    for x in xs:
        for y in ys:
            tried += 1
            c = (x, y, x + w, y + h)
            if c[0] < limit[0] or c[1] < limit[1] or c[2] > limit[2] or c[3] > limit[3]:
                continue
            dx, dy = x - want[0], y - want[1]
            dist = math.hypot(dx, dy)
            if dist > max_d:
                continue
            if (dx < 0 and 'left' not in dirs) or (dx > 0 and 'right' not in dirs) or \
                    (dy < 0 and 'up' not in dirs) or (dy > 0 and 'down' not in dirs):
                continue
            if not flip:
                if side in ('left', 'right') and (x + w / 2 - acx) * (wcx - acx) < 0:
                    continue
                if side in ('top', 'bottom') and (y + h / 2 - acy) * (wcy - acy) < 0:
                    continue
            if any(area(c, o) > 0 for o in blocks):
                continue
            covered = sum(area(c, o) for o in softs)
            away = 0 if math.hypot(x + w / 2 - acx, y + h / 2 - acy) >= math.hypot(wcx - acx, wcy - acy) else 1
            if covered == 0:
                key = (dist, abs(dy), away)
                if best1 is None or key < best1[0]:
                    best1 = (key, c)
            else:
                key = (dist, covered)
                if best2 is None or key < best2[0]:
                    best2 = (key, c)
    if best1:
        return best1[1], 1, tried
    if best2:
        return best2[1], 2, tried
    return None, 0, tried


LIMIT = (0, 0, 1920, 1080)
BOX = (400, 300)


class StretchModelTests(unittest.TestCase):
    def test_clear_first_place_is_kept(self):
        anchor = (100, 100, 130, 130)
        rect, passed, _ = stretch((133, 80), BOX, anchor, 3, 'right', LIMIT, [], [])
        self.assertEqual((rect[0], rect[1], passed), (133, 80, 1))

    def test_movie_on_the_right_moves_box_to_nearest_clear(self):
        anchor = (800, 400, 830, 430)
        movie = (900, 200, 1500, 700)
        want = (833, 265)
        rect, passed, _ = stretch(want, BOX, anchor, 3, 'right', LIMIT, [], [movie])
        self.assertEqual(passed, 1)
        self.assertEqual(area(rect, grow(movie, 8)), 0)
        self.assertEqual(area(rect, grow(anchor, 3)), 0)
        found = math.hypot(rect[0] - want[0], rect[1] - want[1])
        # brute force on a 1 px grid inside 400 px: nothing clear is nearer
        blocks = [grow(anchor, 3), grow(movie, 8)]
        best = min((math.hypot(x - want[0], y - want[1]) for x in range(0, 1521) for y in range(0, 781)
                    if math.hypot(x - want[0], y - want[1]) < found - 1e-6 and
                    not any(area((x, y, x + 400, y + 300), o) > 0 for o in blocks)), default=None)
        self.assertIsNone(best, 'a clear spot nearer than %.1f exists' % found)

    def test_panel_only_spot_used_when_nothing_clear(self):
        anchor = (900, 500, 930, 530)
        soft = (0, 0, 1920, 1080)
        rect, passed, _ = stretch((933, 365), BOX, anchor, 3, 'right', LIMIT, [soft], [])
        self.assertEqual(passed, 2)
        self.assertEqual(area(rect, grow(anchor, 3)), 0)

    def test_all_blocked_falls_back_to_today(self):
        rect, passed, _ = stretch((133, 80), BOX, (100, 100, 130, 130), 3, 'right', LIMIT, [], [(0, 0, 1920, 1080)])
        self.assertEqual((rect, passed), (None, 0))

    def test_edge_pin_flips_or_falls_back(self):
        anchor = (1880, 500, 1910, 530)
        want = (1520, 365)  # the right side's first place after the clamp to the limit: it covers the pin
        rect, passed, _ = stretch(want, BOX, anchor, 3, 'right', LIMIT, [], [], flip=1)
        self.assertEqual(passed, 1)
        self.assertEqual(area(rect, grow(anchor, 3)), 0)
        self.assertLessEqual(rect[2], 1880 - 3)
        # flip 0: the box may not cross the pin's centre line, and it never covers the pin
        kept, passed0, _ = stretch(want, BOX, anchor, 3, 'right', LIMIT, [], [], flip=0)
        self.assertEqual(passed0, 1)
        self.assertEqual(area(kept, grow(anchor, 3)), 0)
        self.assertLess(kept[0] + 200, (anchor[0] + anchor[2]) / 2)
        # the same pin with a first place past the screen edge is farther than stretchMax: today's place stays
        far, passed_far, _ = stretch((1913, 365), BOX, anchor, 3, 'right', LIMIT, [], [], flip=1)
        self.assertEqual((far, passed_far), (None, 0))

    def test_dirs_limit_the_moves(self):
        anchor = (800, 400, 830, 430)
        movie = (900, 200, 1500, 700)
        rect, passed, _ = stretch((833, 265), BOX, anchor, 3, 'right', LIMIT, [], [movie], dirs=('up', 'down'))
        self.assertEqual(passed in (0, 1), True)
        if rect:
            self.assertEqual(rect[0], 833)

    def test_box_taller_than_limits_uses_today(self):
        rect, passed, _ = stretch((133, 0), (400, 1200), (100, 100, 130, 130), 3, 'right', LIMIT, [], [])
        self.assertEqual((rect, passed), (None, 0))

    def test_max_distance_is_respected(self):
        anchor = (800, 400, 830, 430)
        movie = (900, 200, 1500, 700)
        rect, passed, _ = stretch((833, 265), BOX, anchor, 3, 'right', LIMIT, [], [movie], max_d=10)
        self.assertEqual((rect, passed), (None, 0))


def edit_index(text):
    return next(i for i, e in enumerate(EDITS) if text in e['replace'] and 'function cmfStretchPlace' in e['replace'])


class StretchEditTests(unittest.TestCase):
    def setUp(self):
        self.i = edit_index('protected function cmfStretchPlace')
        self.e = EDITS[self.i]

    def test_stretch_function_is_one_appended_edit_with_unique_find(self):
        self.assertEqual(self.e['count'], 1)
        made = [k for k in range(self.i) if self.e['find'] in EDITS[k]['replace']]
        self.assertTrue(made, 'an earlier edit must make the text this one finds')
        for k in range(max(made) + 1, self.i):
            self.assertNotIn(self.e['find'], EDITS[k]['find'], k)
            self.assertNotIn(EDITS[k]['find'], self.e['find'], k)
        self.assertTrue(self.e['replace'].endswith(self.e['find']))

    def test_stretch_function_reads_the_three_keys(self):
        text = self.e['replace']
        self.assertIn('"stretchMax",400', text)
        self.assertIn('"stretchDirs"', text)
        self.assertIn('"stretchFlip",1', text)

    def test_stretch_signature_and_result_shape(self):
        text = self.e['replace']
        self.assertIn('protected function cmfStretchPlace(want:Rectangle, anchor:Rectangle, pad:Number, side:String, '
                      'limit:Rectangle, soft:Array, hard:Array) : Object', text)
        self.assertIn('{"box":null,"pass":0,"dist":0,"tried":0,"hold":0}', text)

    def test_stretch_text_matches_the_model_constants(self):
        text = self.e['replace']
        self.assertEqual(text.count('o.x - 8,o.y - 8,o.width + 16,o.height + 16'), 2)   # movies and panels grown by 8
        self.assertIn('anchor.x - pad,anchor.y - pad,anchor.width + 2 * pad,anchor.height + 2 * pad', text)
        for word in ('",left,"', '",right,"', '",up,"', '",down,"'):
            self.assertIn(word, text)
        self.assertNotIn('\t', text)


def hold(last, new, still_fits, limit=6):
    """Python model of cmfStretchHold: keep the last spot while the new one is within 6 px on both axes and it still fits."""
    if last and abs(last[0] - new[0]) <= limit and abs(last[1] - new[1]) <= limit and still_fits(last):
        return last, 1
    return new, 0


def edit_text(needle):
    return next(e for e in EDITS if needle in e['replace'] and 'function cmfStretchPlace' not in e['replace'])


class StretchUseTests(unittest.TestCase):
    def test_stretch_runs_only_when_the_key_is_1(self):
        e = edit_text('stretched = this.cmfStretchPlace(')['replace']
        self.assertIn('MapMenu.cmfNum("tooltip","stretch",0,this.m_selectedPinData) == 1', e)
        self.assertLess(e.index('"stretch",0'), e.index('this.cmfStretchPlace('))
        # off, or pass 0: today's pick stays reachable
        self.assertIn('if(!anchor) { best = this.cmfClearPick(box,cx,cy,gap,limit,avoid.concat(hard),best); }', e)
        self.assertLess(e.index('else'), e.index('this.cmfClearPick('))

    def test_first_place_captured_before_slides(self):
        e = edit_text('if(k == 0) { want = ')['replace']
        self.assertLess(e.index('if(k == 0) { want = '), e.index('this.cmfClearSlides('))
        self.assertIn('Math.max(limit.left,Math.min(r.x,limit.right - r.width))', e)  # the first place after the clamp

    def test_hold_keeps_last_spot_within_6px(self):
        always = lambda c: True
        never = lambda c: False
        self.assertEqual(hold((100, 100), (104, 99), always), ((100, 100), 1))
        self.assertEqual(hold((100, 100), (107, 100), always), ((107, 100), 0))
        self.assertEqual(hold((100, 100), (104, 100), never), ((104, 100), 0))
        self.assertEqual(hold(None, (1, 1), always), ((1, 1), 0))
        text = edit_text('function cmfStretchHold')['replace']
        self.assertIn('Math.abs(last.x - box.x) <= 6 && Math.abs(last.y - box.y) <= 6', text)
        self.assertIn('this.cmfStretchFits(last,anchor,pad,limit,soft,hard,res.pass)', text)

    def test_last_spot_cleared_on_back(self):
        e = edit_text('this._cmfStretchLast = null;\n         if(this._cmfTallPlaced)')['replace']
        self.assertLess(e.index('_cmfClearMoved = false;'), e.index('_cmfStretchLast = null;'))

    def test_note_names_pass_dist_tried_hold(self):
        e = edit_text('info box stretch pass=')['replace']
        for word in ('pass=', 'dist=', 'tried=', 'hold='):
            self.assertIn(word, e)
        self.assertIn('OnCMFPanelNote', e)

    def test_new_member_and_locals_declared(self):
        self.assertIn('private var _cmfStretchLast:Rectangle;', edit_text('private var _cmfStretchLast:Rectangle;')['replace'])
        e = edit_text('var stretched:Object = null;')['replace']
        self.assertIn('var want:Rectangle = null;', e)

    @staticmethod
    def _chained(upto):
        doc = ''
        for e in EDITS[:upto]:
            doc = doc.replace(e['find'], e['replace'], 1) if e['find'] in doc else doc + '\n' + e['replace']
        return doc

    def test_every_new_edit_finds_text_once_in_an_earlier_edit_and_nothing_overlaps(self):
        start = next(i for i, e in enumerate(EDITS) if 'function cmfStretchPlace' in e['replace'])
        for at in range(start, len(EDITS)):
            e = EDITS[at]
            made = [i for i in range(at) if e['find'] in EDITS[i]['replace']]
            if not made and e['find'] in self._chained(at):
                # Two earlier edits make the text together (the second rewrites a line the first produced).
                made = [at - 1]
            self.assertTrue(made, 'no earlier edit makes: ' + e['find'][:70])
            self.assertEqual(e['count'], 1)
            for i in range(max(made) + 1, at):
                self.assertNotIn(e['find'], EDITS[i]['find'], (at, i))
                self.assertNotIn(EDITS[i]['find'], e['find'], (at, i))
            self.assertNotIn('\t', e['replace'])
            self.assertFalse(re.search(r'claude|opus|sonnet|haiku', e['replace'], re.I))


if __name__ == '__main__':
    unittest.main()
